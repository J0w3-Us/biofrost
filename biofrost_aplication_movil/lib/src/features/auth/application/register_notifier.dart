import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../data/models/commands/register_command.dart';
import '../data/repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// Estado del formulario de registro
// ---------------------------------------------------------------------------

class RegisterState {
  const RegisterState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.detectedRol,
  });

  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  /// Rol detectado automáticamente del correo institcional (RN-301).
  final String? detectedRol;

  RegisterState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    String? detectedRol,
    bool clearMessages = false,
  }) => RegisterState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
    successMessage: clearMessages
        ? null
        : successMessage ?? this.successMessage,
    detectedRol: detectedRol ?? this.detectedRol,
  );
}

// ---------------------------------------------------------------------------
// [Command] Notifier — Registro de usuario nuevo
// ---------------------------------------------------------------------------

class RegisterNotifier extends StateNotifier<RegisterState> {
  RegisterNotifier(this._repo, this._session) : super(const RegisterState());

  final IAuthRepository _repo;
  final SessionService _session;

  // -------------------------------------------------------------------------
  // Detección de rol (RN-301 — email institucional determina rol)
  // -------------------------------------------------------------------------

  static final _regexAlumno = RegExp(
    r'^\d{8}@alumno\.utmetropolitana\.edu\.mx$',
  );
  static final _regexDocente = RegExp(r'^[a-zA-Z.]+@utmetropolitana\.edu\.mx$');

  /// Detecta el rol a partir del correo institucional.
  static String detectRol(String email) {
    if (_regexAlumno.hasMatch(email)) return 'Alumno';
    if (_regexDocente.hasMatch(email)) return 'Docente';
    return 'Invitado';
  }

  /// Extrae la matrícula del correo de alumno (8 dígitos antes de @alumno).
  static String? extractMatricula(String email) {
    if (_regexAlumno.hasMatch(email)) return email.split('@').first;
    return null;
  }

  /// Notifica al formulario el rol detectado cuando cambia el correo.
  void detectRolFromEmail(String email) {
    state = state.copyWith(detectedRol: detectRol(email.trim()));
  }

  // -------------------------------------------------------------------------
  // [Command] Registro
  // -------------------------------------------------------------------------

  /// Crea cuenta en Firebase Auth y sincroniza con el backend.
  ///
  /// Implements RF-Auth-02 (Registro con datos extendidos).
  Future<void> register({
    required String email,
    required String password,
    required RegisterCommand cmd,
  }) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      // 1. Crear usuario en Firebase Auth (queda signed-in automáticamente)
      final credential = await fb.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final fbUser = credential.user!;

      // 2. Registrar en backend con FirebaseUid real
      final finalCmd = RegisterCommand(
        firebaseUid: fbUser.uid,
        email: email,
        nombre: cmd.nombre,
        apellidoPaterno: cmd.apellidoPaterno,
        apellidoMaterno: cmd.apellidoMaterno,
        rol: cmd.rol,
        grupoId: cmd.grupoId,
        matricula: cmd.matricula ?? extractMatricula(email),
        carreraId: cmd.carreraId,
        profesion: cmd.profesion,
        organizacion: cmd.organizacion,
        asignaciones: cmd.asignaciones,
        gruposDocente: cmd.gruposDocente,
        carrerasIds: cmd.carrerasIds,
      );

      final response = await _repo.register(finalCmd);

      // 3. Persistir perfil
      await _session.saveUser(response.toAppUser());

      state = state.copyWith(
        isLoading: false,
        successMessage: '¡Cuenta creada correctamente!',
      );
    } on fb.FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _firebaseErrorMessage(e.code),
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.userMessage);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado al registrarse. Intenta de nuevo.',
      );
    }
  }

  static String _firebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo ya tiene una cuenta. Intenta iniciar sesión.';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'invalid-email':
        return 'El correo ingresado no es válido.';
      case 'operation-not-allowed':
        return 'Registro no permitido. Contacta al administrador.';
      default:
        return 'Error al crear la cuenta. Intenta de nuevo.';
    }
  }

  /// Limpia mensajes de error/éxito.
  void clearMessages() => state = state.copyWith(clearMessages: true);
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final registerProvider = StateNotifierProvider<RegisterNotifier, RegisterState>(
  (ref) {
    return RegisterNotifier(
      ref.read(authRepositoryProvider),
      ref.read(sessionServiceProvider),
    );
  },
);
