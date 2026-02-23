import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../config/api_endpoints.dart';
import '../errors/app_exceptions.dart';
import '../models/user_read_model.dart';
import 'api_service.dart';

/// Servicio de autenticación — capa de negocio entre Firebase y el backend.
///
/// Responsabilidades:
/// 1. Coordinar el sign-in de Firebase con la sincronización del backend.
/// 2. Proveer una sesión de visitante sin Firebase Auth.
/// 3. Exponer [refreshUserData] para mantener el perfil actualizado.
///
/// CQRS:
/// - Query  → [refreshUserData]
/// - Command → [signInDocente], [signOut]
class AuthService {
  AuthService({
    required FirebaseAuth firebaseAuth,
    required ApiService apiService,
  })  : _auth = firebaseAuth,
        _api = apiService;

  final FirebaseAuth _auth;
  final ApiService _api;

  // ── CQRS Command: Sign In ──────────────────────────────────────────

  /// Autentica un Docente con email y contraseña de Firebase,
  /// luego sincroniza con el backend para obtener el perfil completo.
  ///
  /// Throws:
  /// - [AuthException] si las credenciales son inválidas.
  /// - [ForbiddenException] si el backend rechaza al usuario.
  /// - [NetworkException] si no hay conexión.
  Future<UserReadModel> signInDocente({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException(
            message: 'No se pudo autenticar con Firebase.');
      }
      return _syncWithBackend(firebaseUser);
    } on FirebaseAuthException catch (e) {
      // Fix de IntegradorHub/docs/Historial_De_Avances_Completados.md:
      // § Refinamiento de Autenticación — Patrón "Sonda de Creación"
      //
      // Firebase retorna `invalid-credential` tanto para contraseña incorrecta
      // como para usuario no encontrado. Necesitamos diferenciarlos.
      if (e.code == 'invalid-credential') {
        return _probeCredential(email, password);
      }
      throw _mapFirebaseError(e);
    }
  }

  // ── CQRS Command: Register Docente ───────────────────────────────

  /// Crea una cuenta nueva de Docente en Firebase y la sincroniza con el backend.
  ///
  /// Flujo:
  /// 1. `createUserWithEmailAndPassword` → cuenta en Firebase Auth.
  /// 2. POST /auth/register → perfil completo en Firestore via backend.
  /// 3. [_syncWithBackend] → retorna [UserReadModel] listo para la UI.
  Future<UserReadModel> registerDocente({
    required String email,
    required String password,
    required String nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
  }) async {
    try {
      // 1. Crear en Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException(
            message: 'No se pudo crear la cuenta. Intenta de nuevo.');
      }

      // 2. Registrar perfil en el backend
      await _api.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'FirebaseUid': firebaseUser.uid,
          'Email': email,
          'Nombre': nombre,
          'ApellidoPaterno': apellidoPaterno,
          'ApellidoMaterno': apellidoMaterno,
          'Rol': 'Docente',
        },
        authenticated: true,
      );

      // 3. Sincronizar y devolver perfil completo
      return _syncWithBackend(firebaseUser);
    } on FirebaseAuthException catch (e) {
      throw _mapRegisterError(e);
    } on AppException {
      rethrow;
    }
  }

  /// Sonda de creación: distingue "contraseña incorrecta" de "cuenta nueva".
  ///
  /// 1. Intenta crear la cuenta temporalmente.
  /// 2. Si Firebase responde `email-already-in-use` → el usuario SÍ existe
  ///    pero su contraseña es incorrecta → mensaje claro al usuario.
  /// 3. Si la creación tiene éxito → es un usuario genuinamente nuevo.
  ///    Se elimina la cuenta temporal y se informa que no está registrado.
  Future<UserReadModel> _probeCredential(String email, String password) async {
    try {
      final tempCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Usuario nuevo — eliminar la cuenta temporal creada
      await tempCredential.user?.delete();
      throw const AuthException(
        message: 'No encontramos una cuenta con este correo. '
            'Regístrate para crear tu cuenta de Docente.',
        code: 'no-account',
      );
    } on FirebaseAuthException catch (probe) {
      if (probe.code == 'email-already-in-use') {
        // El usuario existe → la contraseña que ingresó es incorrecta.
        throw const AuthException(
          message: 'Contraseña incorrecta. Verifica e intenta de nuevo.',
        );
      }
      throw _mapFirebaseError(probe);
    }
  }

  // ── CQRS Query: Refresh User Data ─────────────────────────────────

  /// Sincroniza los datos del usuario con el backend.
  ///
  /// Se llama al detectar cambios de sesión en [FirebaseAuth.authStateChanges].
  Future<UserReadModel> refreshUserData(String uid) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null || firebaseUser.uid != uid) {
      throw const AuthException(message: 'Sesión no encontrada.');
    }
    return _syncWithBackend(firebaseUser);
  }

  // ── CQRS Command: Actualizar foto de perfil ───────────────────────

  /// Sube una imagen a Firebase Storage y persiste la URL en el backend.
  ///
  /// Implementa docs/Historial_De_Avances_Completados.md:
  /// § Funcionalidad de Foto de Perfil — endpoint PUT /api/users/{id}/photo
  ///
  /// 1. Sube [imageFile] a Firebase Storage en `profile_photos/{uid}.jpg`.
  /// 2. Obtiene la URL de descarga.
  /// 3. Llama a PUT /api/users/{uid}/photo para persistir en Firestore.
  ///
  /// Devuelve la nueva URL de la foto.
  Future<String> updateProfilePhoto({
    required String uid,
    required File imageFile,
  }) async {
    try {
      // 1. Subir a Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$uid.jpg');

      final uploadTask = await storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // 2. Persistir URL en el backend (.NET → Firestore)
      await _api.put<void>(
        ApiEndpoints.updateUserPhoto(uid),
        data: {'photoUrl': downloadUrl},
      );

      return downloadUrl;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'No se pudo actualizar la foto de perfil: $e',
      );
    }
  }

  // ── CQRS Command: Sign Out ─────────────────────────────────────────

  /// Cierra la sesión de Firebase.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Sesión de visitante (sin Firebase Auth) ────────────────────────

  /// Crea un [UserReadModel] local para visitantes sin autenticación.
  UserReadModel visitorSession({String? organizacion}) {
    return UserReadModel(
      userId: 'visitor_${DateTime.now().millisecondsSinceEpoch}',
      email: '',
      nombre: 'Visitante',
      rol: 'Invitado',
      organizacion: organizacion,
    );
  }

  // ── Privado ────────────────────────────────────────────────────────

  Future<UserReadModel> _syncWithBackend(User firebaseUser) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {
          'FirebaseUid': firebaseUser.uid,
          'Email': firebaseUser.email ?? '',
          'DisplayName': firebaseUser.displayName ?? '',
          'PhotoUrl': firebaseUser.photoURL,
        },
        authenticated: true,
      );

      if (response.data == null) {
        throw const ServerException(
            message: 'Respuesta vacía del servidor al hacer login.');
      }

      final user = UserReadModel.fromJson(response.data!);

      if (user.rol == 'Invitado') {
        throw const ForbiddenException(
          message: 'Tu cuenta no tiene acceso a esta aplicación.',
        );
      }

      return user;
    } on AppException {
      rethrow;
    } catch (_) {
      throw const NetworkException(
        message: 'No se pudo conectar con el servidor. Verifica tu conexión.',
      );
    }
  }

  AppException _mapRegisterError(FirebaseAuthException e) {
    return switch (e.code) {
      'email-already-in-use' => const AuthException(
          message: 'Ya existe una cuenta con este correo. Inicia sesión.',
          code: 'email-already-in-use',
        ),
      'invalid-email' => const AuthException(
          message: 'El formato del correo no es válido.',
        ),
      'weak-password' => const AuthException(
          message: 'La contraseña es muy débil. Usa al menos 6 caracteres.',
        ),
      'network-request-failed' => const NetworkException(
          message: 'Sin conexión. Verifica tu red.',
        ),
      _ => AuthException(
          message: 'No se pudo crear la cuenta: ${e.message ?? e.code}',
          code: e.code,
        ),
    };
  }

  AppException _mapFirebaseError(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        const AuthException(message: 'Correo o contraseña incorrectos.'),
      'user-disabled' => const ForbiddenException(
          message:
              'Tu cuenta ha sido deshabilitada. Contacta al administrador.',
        ),
      'too-many-requests' =>
        const AuthException(message: 'Demasiados intentos. Intenta más tarde.'),
      'network-request-failed' => const NetworkException(
          message: 'Sin conexión. Verifica tu red e intenta de nuevo.',
        ),
      _ => AuthException(
          message: 'Error de autenticación: ${e.message ?? e.code}',
          code: e.code,
        ),
    };
  }
}
