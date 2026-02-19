import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../data/models/commands/login_command.dart';
import '../data/repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum AuthStatus { unauthenticated, loading, authenticated, error }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// [Query + Command] Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo, this._session) : super(const AuthState()) {
    _restore();
  }

  final IAuthRepository _repo;
  final SessionService _session;

  /// [Query] Restaura sesión guardada al iniciar la app (cold start).
  Future<void> _restore() async {
    // Marcar como "cargando" para que el AuthGuard muestre el splash
    state = const AuthState(status: AuthStatus.loading);
    try {
      if (!_session.isAuthenticated) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      final user = await _session.getUser();
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// [Command] Login: Firebase sign-in → sync backend → persistir sesión.
  ///
  /// Implements RF-Auth-01 (Login con correo institucional).
  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      // 1. Firebase sign-in (almacena token en SecureStorage vía SessionService)
      await _session.signInWithFirebase(email: email, password: password);

      // 2. Obtener datos del usuario Firebase post sign-in
      final fbUser = fb.FirebaseAuth.instance.currentUser!;

      // 3. Sync con backend — endpoint público, no requiere header JWT
      final cmd = LoginCommand(
        firebaseUid: fbUser.uid,
        email: fbUser.email ?? email,
        displayName: fbUser.displayName,
        photoUrl: fbUser.photoURL,
      );
      final response = await _repo.login(cmd);

      // 4. Persistir perfil completo
      final appUser = response.toAppUser();
      await _session.saveUser(appUser);

      state = AuthState(status: AuthStatus.authenticated, user: appUser);
    } on AppException catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.userMessage);
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'Error de conexión. Revisa tu red e intenta de nuevo.',
      );
    }
  }

  /// [Command] Logout: elimina sesión local y cierra sesión en Firebase.
  Future<void> logout() async {
    await _session.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// [Command] Actualiza el [AppUser] en el estado global (usado por Profile).
  /// No hace llamada de red — solo refleja cambios ya persistidos en sesión.
  void updateUser(AppUser user) {
    state = state.copyWith(user: user);
  }

  /// Limpia el mensaje de error activo.
  void clearError() => state = state.copyWith(clearError: true);
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(sessionServiceProvider),
  );
});
