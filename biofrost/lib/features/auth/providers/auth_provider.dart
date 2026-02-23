import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/core/config/app_config.dart';
import 'package:biofrost/core/errors/app_exceptions.dart';
import 'package:biofrost/core/models/user_read_model.dart';
import 'package:biofrost/core/services/api_service.dart';
import 'package:biofrost/core/services/auth_service.dart';

// ── Provider base: Infraestructura ─────────────────────────────────────

/// Firebase Auth singleton.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// ApiService singleton — comparte la instancia Dio en toda la app.
final apiServiceProvider = Provider<ApiService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return ApiService(auth: auth);
});

/// AuthService singleton.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    apiService: ref.watch(apiServiceProvider),
  );
});

// ── Estado de Autenticación ─────────────────────────────────────────────

/// Estado completo de la sesión del usuario.
sealed class AuthState {}

/// Verificando sesión inicial (splash).
final class AuthStateLoading extends AuthState {}

/// Sin sesión activa.
final class AuthStateUnauthenticated extends AuthState {}

/// Sesión de visitante (sin Firebase Auth).
final class AuthStateVisitor extends AuthState {
  AuthStateVisitor(this.user);
  final UserReadModel user;
}

/// Sesión de docente autenticado.
final class AuthStateAuthenticated extends AuthState {
  AuthStateAuthenticated(this.user);
  final UserReadModel user;
}

/// Error de autenticación.
final class AuthStateError extends AuthState {
  AuthStateError(this.exception);
  final AppException exception;
}

// ── Notifier principal de Auth ─────────────────────────────────────────

/// Gestiona el ciclo de vida de la sesión.
///
/// Escucha [FirebaseAuth.authStateChanges] y sincroniza con el backend.
/// Expone acciones: [loginAsDocente], [continueAsVisitor], [logout].
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _initAuthListener();
    return AuthStateLoading();
  }

  AuthService get _authService => ref.read(authServiceProvider);

  void _initAuthListener() {
    ref.watch(firebaseAuthProvider).authStateChanges().listen(
      (firebaseUser) async {
        if (firebaseUser == null) {
          // Solo clearear si no estamos en modo visitante
          if (state is! AuthStateVisitor) {
            state = AuthStateUnauthenticated();
          }
          return;
        }

        // Usuario Firebase exists → sincronizar con backend
        try {
          final user = await _authService.refreshUserData(firebaseUser.uid);
          state = AuthStateAuthenticated(user);
        } on ForbiddenException catch (e) {
          state = AuthStateError(e);
        } on AppException catch (e) {
          state = AuthStateError(e);
        }
      },
    );
  }

  // ── Acciones ────────────────────────────────────────────────────────

  /// Login de Docente con email + contraseña.
  ///
  /// Emite [AuthStateLoading] → [AuthStateAuthenticated] o [AuthStateError].
  Future<void> loginAsDocente({
    required String email,
    required String password,
  }) async {
    state = AuthStateLoading();
    try {
      final user = await _authService.signInDocente(
        email: email,
        password: password,
      );
      state = AuthStateAuthenticated(user);
    } on AppException catch (e) {
      state = AuthStateError(e);
    }
  }

  /// Acceso como visitante (sin Firebase Auth).
  /// Navega directamente al Showcase.
  void continueAsVisitor({String? organizacion}) {
    final visitor = _authService.visitorSession(organizacion: organizacion);
    state = AuthStateVisitor(visitor);
  }

  /// Cierra la sesión actual (Docente o Visitante).
  Future<void> logout() async {
    await _authService.signOut();
    state = AuthStateUnauthenticated();
  }

  /// Actualiza la foto de perfil del usuario autenticado.
  ///
  /// 1. Sube la imagen a Firebase Storage.
  /// 2. Persiste la URL en Firestore vía el backend.
  /// 3. Refresca el estado del usuario para reflejar el nuevo fotoUrl.
  Future<String> updateProfilePhoto(File imageFile) async {
    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    if (currentUser == null) throw const AuthException();

    final newUrl = await _authService.updateProfilePhoto(
      uid: currentUser.uid,
      imageFile: imageFile,
    );
    // Refrescar datos del usuario para propagar el nuevo fotoUrl a la UI
    await refreshUser();
    return newUrl;
  }

  /// Refresca los datos del usuario desde el backend.
  Future<void> refreshUser() async {
    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    if (currentUser == null) return;

    try {
      final updated = await _authService.refreshUserData(currentUser.uid);
      state = AuthStateAuthenticated(updated);
    } on AppException {
      // Silencioso — no cambiar estado si el refresh falla
    }
  }
}

/// Provider del notifier de autenticación.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// ── Providers derivados (selectores) ───────────────────────────────────

/// El usuario autenticado actualmente. Null si no hay sesión.
final currentUserProvider = Provider<UserReadModel?>((ref) {
  final authState = ref.watch(authProvider);
  return switch (authState) {
    AuthStateAuthenticated(:final user) => user,
    AuthStateVisitor(:final user) => user,
    _ => null,
  };
});

/// True si hay una sesión activa (Docente o Visitante).
final isAuthenticatedProvider = Provider<bool>((ref) {
  final state = ref.watch(authProvider);
  return state is AuthStateAuthenticated || state is AuthStateVisitor;
});

/// True si el usuario tiene rol Docente.
final isDocenteProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.rol == AppConfig.roleDocente;
});

/// True si el estado está cargando.
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AuthStateLoading;
});

/// Error de autenticación actual. Null si no hay error.
final authErrorProvider = Provider<AppException?>((ref) {
  final state = ref.watch(authProvider);
  return state is AuthStateError ? state.exception : null;
});
