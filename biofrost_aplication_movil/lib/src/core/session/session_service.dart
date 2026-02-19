import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import 'app_user.dart';

/// Gestiona la sesión del usuario: JWT + datos de perfil.
///
/// - Persiste token Firebase y AppUser serializado en [FlutterSecureStorage].
/// - Expone [currentUser] y [getToken] para uso en ApiClient.
/// - [logout] limpia storage y revoca sesión Firebase.
class SessionService {
  SessionService({FlutterSecureStorage? storage, FirebaseAuth? firebaseAuth})
    : _storage = storage ?? const FlutterSecureStorage(),
      _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FlutterSecureStorage _storage;
  final FirebaseAuth _firebaseAuth;
  final _log = Logger();

  AppUser? _cachedUser;

  // -------------------------------------------------------------------------
  // Token
  // -------------------------------------------------------------------------

  /// Devuelve el token JWT fresco desde Firebase.
  /// Primero intenta refresh si el token local está próximo a expirar.
  Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      final tokenResult = await user.getIdTokenResult(forceRefresh);
      final token = tokenResult.token;
      if (token != null) {
        await _storage.write(key: AppConfig.jwtStorageKey, value: token);
      }
      return token;
    } catch (e) {
      _log.w('SessionService.getToken error: $e');
      // Fallback: devolver token guardado localmente
      return _storage.read(key: AppConfig.jwtStorageKey);
    }
  }

  // -------------------------------------------------------------------------
  // Usuario actual
  // -------------------------------------------------------------------------

  /// Carga el AppUser desde SecureStorage (cache en memoria).
  Future<AppUser?> getUser() async {
    if (_cachedUser != null) return _cachedUser;
    final raw = await _storage.read(key: AppConfig.userStorageKey);
    if (raw == null) return null;
    try {
      _cachedUser = AppUser.fromJsonString(raw);
      return _cachedUser;
    } catch (e) {
      _log.e('SessionService.getUser parse error: $e');
      return null;
    }
  }

  AppUser? get currentUser => _cachedUser;

  /// Guarda el AppUser en storage y actualiza la caché.
  Future<void> saveUser(AppUser user) async {
    _cachedUser = user;
    await _storage.write(
      key: AppConfig.userStorageKey,
      value: user.toJsonString(),
    );
    _log.i('SessionService: user saved — uid=${user.uid}, rol=${user.rol}');
  }

  // -------------------------------------------------------------------------
  // Login / Logout
  // -------------------------------------------------------------------------

  /// Llama a Firebase signIn con email/password y guarda el resultado.
  Future<String> signInWithFirebase({
    required String email,
    required String password,
  }) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final token = await cred.user?.getIdToken() ?? '';
    await _storage.write(key: AppConfig.jwtStorageKey, value: token);
    return token;
  }

  /// Limpia toda la sesión local y cierra sesión en Firebase.
  Future<void> logout() async {
    _cachedUser = null;
    await Future.wait([
      _storage.delete(key: AppConfig.jwtStorageKey),
      _storage.delete(key: AppConfig.userStorageKey),
      _firebaseAuth.signOut(),
    ]);
    _log.i('SessionService: logout complete');
  }

  /// True si hay un usuario de Firebase autenticado.
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  /// Stream del estado de autenticación de Firebase.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService();
});
