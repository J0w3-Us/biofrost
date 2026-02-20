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
    print('[INFO] RegisterNotifier.register: STARTING registration process');
    print('[DEBUG] RegisterNotifier.register: Email: $email, Role: ${cmd.rol}');
    print(
      '[DEBUG] RegisterNotifier.register: Personal info - Nombre: ${cmd.nombre}, ApellidoPaterno: ${cmd.apellidoPaterno}',
    );

    // Prevent double submissions
    if (state.isLoading) {
      print(
        '[WARN] RegisterNotifier.register: Already in loading state, ignoring duplicate request',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearMessages: true);
    print('[DEBUG] RegisterNotifier.register: State updated to loading');

    fb.User? fbUser;

    try {
      // 1. Crear usuario en Firebase Auth (queda signed-in automáticamente)
      print(
        '[DEBUG] RegisterNotifier.register: STEP 1 - Creating Firebase user...',
      );
      final credential = await fb.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      fbUser = credential.user!;
      print(
        '[SUCCESS] RegisterNotifier.register: Firebase user created successfully - UID: ${fbUser.uid}',
      );

      // 2. Registrar en backend con FirebaseUid real
      print(
        '[DEBUG] RegisterNotifier.register: STEP 2 - Creating backend registration command...',
      );
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
      print(
        '[DEBUG] RegisterNotifier.register: Backend command created - UID: ${finalCmd.firebaseUid}, Matricula: ${finalCmd.matricula}',
      );

      print(
        '[DEBUG] RegisterNotifier.register: STEP 3 - Sending registration to backend...',
      );
      final response = await _repo.register(finalCmd);
      print(
        '[SUCCESS] RegisterNotifier.register: Backend registration successful - Success: ${response.success}, UserId: ${response.userId}',
      );

      // 3. Verificar que tenemos un usuario válido y persistir perfil
      print(
        '[DEBUG] RegisterNotifier.register: STEP 4 - Processing user data and saving session...',
      );
      final appUser = response.toAppUser();
      if (appUser == null) {
        print(
          '[ERROR] RegisterNotifier.register: Failed to convert response to AppUser',
        );
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error al procesar los datos del usuario registrado.',
        );
        return;
      }
      print(
        '[DEBUG] RegisterNotifier.register: AppUser created - ID: ${appUser.uid}, Role: ${appUser.rol}',
      );

      await _session.saveUser(appUser);
      print(
        '[SUCCESS] RegisterNotifier.register: User session saved successfully',
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: '¡Cuenta creada correctamente!',
      );
      print(
        '[INFO] RegisterNotifier.register: REGISTRATION COMPLETED SUCCESSFULLY',
      );
    } on fb.FirebaseAuthException catch (e) {
      // Firebase falló antes de crear el usuario — no hay nada que revertir.
      print(
        '[ERROR] RegisterNotifier.register: FirebaseAuthException - Code: ${e.code}, Message: ${e.message}',
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: _firebaseErrorMessage(e.code),
      );
    } on AppException catch (e) {
      // Backend rechazó el registro (validación, duplicado, etc.)
      // ROLLBACK: eliminar el usuario de Firebase para que el correo quede libre.
      print(
        '[ERROR] RegisterNotifier.register: Backend AppException - ${e.userMessage}',
      );
      print(
        '[DEBUG] RegisterNotifier.register: Starting Firebase rollback for user: ${fbUser?.uid}',
      );
      await _rollbackFirebaseUser(fbUser);
      state = state.copyWith(isLoading: false, errorMessage: e.userMessage);
    } catch (e) {
      // Error de red / backend no disponible
      // ROLLBACK: eliminar el usuario de Firebase para que el correo quede libre.
      print(
        '[ERROR] RegisterNotifier.register: Unexpected error - ${e.toString()}',
      );
      print(
        '[DEBUG] RegisterNotifier.register: Starting Firebase rollback for user: ${fbUser?.uid}',
      );
      await _rollbackFirebaseUser(fbUser);
      final msg = _networkErrorMessage(e);
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  /// Elimina el usuario de Firebase Auth si ya fue creado, para que el correo
  /// quede disponible en un siguiente intento.
  static Future<void> _rollbackFirebaseUser(fb.User? user) async {
    if (user == null) {
      print(
        '[DEBUG] RegisterNotifier._rollbackFirebaseUser: No user to rollback',
      );
      return;
    }

    try {
      print(
        '[DEBUG] RegisterNotifier._rollbackFirebaseUser: Attempting to delete Firebase user: ${user.uid}',
      );
      await user.delete();
      print(
        '[SUCCESS] RegisterNotifier._rollbackFirebaseUser: Firebase user deleted successfully',
      );
    } catch (e) {
      // Ignorar — si no se puede borrar, el usuario lo intentará de nuevo
      // y recibirá "email ya en uso", que es igualmente manejable.
      print(
        '[WARN] RegisterNotifier._rollbackFirebaseUser: Failed to delete Firebase user - ${e.toString()}',
      );
    }
  }

  static String _networkErrorMessage(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('connection refused') ||
        msg.contains('connection reset') ||
        msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('timeout') ||
        msg.contains('failed host lookup')) {
      return 'No se pudo conectar al servidor. Verifica que el backend esté activo e inténtalo de nuevo.';
    }
    return 'Error inesperado al registrarse. Inténtalo de nuevo.';
  }

  static String _firebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo ya tiene una cuenta activa. Si eres tú, ve a "Iniciar sesión". Si es tu primera vez, verifica que el correo sea correcto.';
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
