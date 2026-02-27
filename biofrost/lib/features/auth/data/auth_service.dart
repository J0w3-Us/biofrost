import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:biofrost/core/config/api_endpoints.dart';
import 'package:biofrost/core/errors/app_exceptions.dart';
import 'package:biofrost/core/services/api_service.dart';
import 'package:biofrost/features/auth/domain/models/user_read_model.dart';

/// Servicio de autenticación — coordinación Firebase Auth + backend .NET.
///
/// Responsabilidades:
/// 1. Coordinar sign-in de Firebase con sincronización del backend.
/// 2. Sesión de visitante sin Firebase Auth.
/// 3. [refreshUserData] para mantener el perfil actualizado.
///
/// CQRS:
/// - Query   → [refreshUserData]
/// - Command → [signInDocente], [registerDocente], [updateProfilePhoto], [updateDisplayName]
class AuthService {
  AuthService({
    required FirebaseAuth firebaseAuth,
    required ApiService apiService,
  })  : _auth = firebaseAuth,
        _api = apiService;

  final FirebaseAuth _auth;
  final ApiService _api;

  // ── CQRS Command: Sign In ──────────────────────────────────────────

  /// Autentica un Docente con email y contraseña.
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
      // Patrón "Sonda de Creación": diferencia contraseña incorrecta de usuario no encontrado.
      if (e.code == 'invalid-credential') {
        return _probeCredential(email, password);
      }
      throw _mapFirebaseError(e);
    }
  }

  // ── CQRS Command: Register Docente ────────────────────────────────

  /// Crea cuenta en Firebase → POST /api/auth/register.
  Future<UserReadModel> registerDocente({
    required String email,
    required String password,
    required String nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException(message: 'No se pudo crear la cuenta.');
      }

      await _api.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'firebaseUid': firebaseUser.uid,
          'email': email,
          'nombre': nombre,
          'apellidoPaterno': apellidoPaterno,
          'apellidoMaterno': apellidoMaterno,
          'rol': 'Docente',
        },
        authenticated: false,
      );

      return _syncWithBackend(firebaseUser);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  // ── CQRS Query: Refresh User Data ─────────────────────────────────

  /// Re-sincroniza el perfil del usuario desde el backend.
  Future<UserReadModel> refreshUserData(String uid) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null || firebaseUser.uid != uid) {
      throw const AuthException(message: 'Sesión no encontrada.');
    }
    return _syncWithBackend(firebaseUser);
  }

  // ── CQRS Command: Actualizar Foto de Perfil ──────────────────────

  /// Sube imagen a Firebase Storage → PUT /api/users/{uid}/photo.
  ///
  /// Usa [putData] en lugar de [putFile] para evitar el error 404 de storage:
  /// el cropper guarda en un archivo temporal que el OS puede eliminar antes
  /// de que el SDK de Firebase confirme la sesión de upload resumible.
  Future<String> updateProfilePhoto({
    required String uid,
    required File imageFile,
  }) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child('$uid.jpg');

    // Leer bytes ANTES de subir — garantiza que el temp-file del cropper
    // no desaparezca durante la transferencia resumible de Firebase.
    final bytes = await imageFile.readAsBytes();

    final uploadTask = await storageRef.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Sincronizar Firebase Auth con la nueva URL ANTES de llamar al backend,
    // para que _syncWithBackend envíe el photoURL correcto en el POST de login.
    await _auth.currentUser?.updatePhotoURL(downloadUrl);
    await _auth.currentUser?.reload();

    await _api.put<void>(
      ApiEndpoints.updateUserPhoto(uid),
      data: {'photoUrl': downloadUrl},
    );

    return downloadUrl;
  }

  // ── CQRS Command: Actualizar Nombre ────────────────────────────────

  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    final current = _auth.currentUser;
    if (current == null || current.uid != uid) {
      throw const AuthException(message: 'Sesión no encontrada.');
    }
    await current.updateDisplayName(displayName);
  }

  // ── CQRS Command: Sign Out ───────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Visitor Session ─────────────────────────────────────────────────

  /// Crea una sesión de visitante sin autenticación Firebase.
  UserReadModel visitorSession({String? organizacion}) {
    return UserReadModel(
      userId: 'visitor_${DateTime.now().millisecondsSinceEpoch}',
      email: '',
      nombre: 'Visitante',
      rol: 'Invitado',
      organizacion: organizacion,
    );
  }

  // ── Helpers privados ────────────────────────────────────────────────

  Future<UserReadModel> _syncWithBackend(User firebaseUser) async {
    // El endpoint de login es la raíz de la autenticación; no puede requerir
    // un Bearer token porque el token es precisamente lo que se obtiene aquí.
    // Se usa authenticated: false para evitar el problema de "huevo y gallina"
    // donde _AuthInterceptor llama user.getIdToken() para llamar al login mismo.
    final response = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {
        'FirebaseUid': firebaseUser.uid,
        'Email': firebaseUser.email ?? '',
        'DisplayName': firebaseUser.displayName ?? '',
        'PhotoUrl': firebaseUser.photoURL,
      },
      authenticated: false,
    );

    if (response.data == null) {
      throw const ServerException(message: 'Error al sincronizar perfil.');
    }

    return UserReadModel.fromJson(response.data!);
  }

  /// Patrón "Sonda de Creación" para diferenciar:
  /// - contraseña incorrecta → AuthException
  /// - usuario no encontrado → NotFoundException
  Future<UserReadModel> _probeCredential(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: 'probe-only-${DateTime.now().millisecondsSinceEpoch}',
      );
      // Si llegamos aquí: usuario no existía → borramos la cuenta temporal
      await _auth.currentUser?.delete();
      throw const NotFoundException(
        message: 'No existe una cuenta con este correo. ¿Deseas registrarte?',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const AuthException(
            message: 'Contraseña incorrecta. Inténtalo de nuevo.');
      }
      throw _mapFirebaseError(e);
    }
  }

  AppException _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const NotFoundException(
            message: 'No existe una cuenta con este correo.');
      case 'wrong-password':
        return const AuthException(message: 'Contraseña incorrecta.');
      case 'email-already-in-use':
        return const BusinessException(
          'Ya existe una cuenta con este correo.',
          field: 'email',
        );
      case 'weak-password':
        return const BusinessException(
          'La contraseña debe tener al menos 6 caracteres.',
          field: 'password',
        );
      case 'invalid-email':
        return const BusinessException(
          'El correo electrónico no tiene un formato válido.',
          field: 'email',
        );
      case 'too-many-requests':
        return const AuthException(
            message: 'Demasiados intentos fallidos. Inténtalo más tarde.');
      default:
        return AuthException(message: e.message ?? 'Error desconocido.');
    }
  }
}
