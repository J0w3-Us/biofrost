import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../config/api_endpoints.dart';
import '../errors/app_exceptions.dart';
import '../models/user_read_model.dart';
import 'api_service.dart';

/// Servicio de autenticación para la app móvil Biofrost.
///
/// Actores permitidos en móvil:
/// - [AppConfig.roleDocente]: Login con email @utm.mx + contraseña.
/// - [AppConfig.roleVisitante]: Acceso sin auth (modo explorador).
///
/// Flujo de autenticación (CQRS Query):
/// 1. signInWithEmailAndPassword (Firebase Auth)
/// 2. GET /api/users/{uid} → obtiene perfil y rol
/// 3. Verifica que el rol sea Docente (único rol con auth en móvil)
/// 4. Normaliza PascalCase → camelCase
class AuthService {
  AuthService({
    required FirebaseAuth firebaseAuth,
    required ApiService apiService,
    Logger? logger,
  })  : _firebaseAuth = firebaseAuth,
        _apiService = apiService,
        _logger = logger ?? Logger();

  final FirebaseAuth _firebaseAuth;
  final ApiService _apiService;
  final Logger _logger;

  // ── Observar estado de sesión ──────────────────────────────────────

  /// Stream que emite el usuario Firebase actual.
  /// Emite null cuando no hay sesión activa.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Usuario actualmente autenticado en Firebase. Null si no hay sesión.
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // ── Login de Docente ───────────────────────────────────────────────

  /// Inicia sesión con email (@utm.mx) y contraseña.
  ///
  /// Lanza:
  /// - [AuthException] si las credenciales son inválidas.
  /// - [ForbiddenException] si el usuario no tiene rol Docente.
  /// - [NotFoundException] si el usuario no existe en el backend.
  /// - [NetworkException] si no hay conexión.
  Future<UserReadModel> signInDocente({
    required String email,
    required String password,
  }) async {
    _logger.d('[Auth] Iniciando login docente: $email');

    // 1. Autenticar en Firebase
    final UserCredential credential;
    try {
      credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _logger.w('[Auth] Firebase error: ${e.code}');
      throw _mapFirebaseError(e);
    }

    final uid = credential.user!.uid;

    // 2. Obtener perfil completo desde backend
    final user = await _fetchAndValidateUser(uid);

    _logger.i('[Auth] Login exitoso: ${user.nombre} (${user.rol})');
    return user;
  }

  // ── Obtener perfil actualizado ─────────────────────────────────────

  /// Sincroniza los datos del usuario con el backend.
  /// Útil para refrescar el estado tras cambios de perfil.
  Future<UserReadModel> refreshUserData(String uid) async {
    _logger.d('[Auth] Refrescando datos de usuario: $uid');
    return _fetchAndValidateUser(uid);
  }

  // ── Logout ─────────────────────────────────────────────────────────

  /// Cierra sesión en Firebase.
  Future<void> signOut() async {
    _logger.i('[Auth] Cerrando sesión');
    await _firebaseAuth.signOut();
  }

  // ── Acceso como Visitante (sin auth) ──────────────────────────────

  /// Verifica si el usuario tiene acceso de visitante.
  /// Los visitantes no requieren autenticación en Firebase.
  ///
  /// Retorna el [UserReadModel] de visitante con campos mínimos.
  UserReadModel visitorSession({String? organizacion}) {
    return UserReadModel(
      userId: 'visitor-${DateTime.now().millisecondsSinceEpoch}',
      email: '',
      nombre: 'Visitante',
      rol: AppConfig.roleVisitante,
      organizacion: organizacion,
    );
  }

  // ── Helpers privados ───────────────────────────────────────────────

  /// Obtiene el perfil del backend y valida que sea un rol permitido en móvil.
  Future<UserReadModel> _fetchAndValidateUser(String uid) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.userById(uid),
    );

    if (response.data == null) {
      throw const NotFoundException(
        message: 'Usuario no encontrado en el sistema.',
      );
    }

    final user = UserReadModel.fromJson(response.data!);

    // Verificar rol permitido en la app móvil
    if (!AppConfig.allowedMobileRoles.contains(user.rol)) {
      _logger.w('[Auth] Rol no permitido en móvil: ${user.rol}');
      await _firebaseAuth.signOut();
      throw const ForbiddenException(
        message:
            'Esta app es exclusiva para Docentes y Visitantes. '
            'Accede desde la plataforma web.',
      );
    }

    return user;
  }

  /// Mapea errores de Firebase Auth a excepciones del dominio.
  AppException _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return const AuthException(
          message: 'Correo o contraseña incorrectos.',
        );
      case 'wrong-password':
        return const AuthException(
          message: 'Contraseña incorrecta.',
        );
      case 'too-many-requests':
        return const AuthException(
          message:
              'Demasiados intentos fallidos. Espera unos minutos e intenta de nuevo.',
        );
      case 'network-request-failed':
        return const NetworkException(
          message: 'Sin conexión. Verifica tu red.',
        );
      case 'invalid-email':
        return const BusinessException(
          'El correo electrónico no tiene un formato válido.',
          field: 'email',
        );
      default:
        return ServerException(
          message: 'Error de autenticación: ${e.message ?? e.code}',
          code: e.code,
        );
    }
  }
}
