import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../auth/application/auth_notifier.dart';
import '../data/models/commands/update_profile_command.dart';
import '../data/repositories/profile_repository.dart';

// Implementa RF-Profile-01: Visualización y edición del perfil de usuario.
// Implementa RF-Profile-02: Upload de avatar.

// ---------------------------------------------------------------------------
// Estado
// ---------------------------------------------------------------------------

enum ProfileStatus { idle, loading, saving, savingAvatar, success, error }

class ProfileState {
  const ProfileState({
    this.status = ProfileStatus.loading,
    this.user,
    this.isEditing = false,
    this.errorMessage,
    this.successMessage,
    // Campos del formulario en edición
    this.editNombre,
    this.editApellidoPaterno,
    this.editApellidoMaterno,
  });

  final ProfileStatus status;

  /// Usuario actualmente cargado (puede ser null mientras carga).
  final AppUser? user;

  /// True cuando se está en modo edición.
  final bool isEditing;

  final String? errorMessage;
  final String? successMessage;

  // Campos del formulario de edición
  final String? editNombre;
  final String? editApellidoPaterno;
  final String? editApellidoMaterno;

  // --------------------------------------------------------------------------
  // Derived
  // --------------------------------------------------------------------------

  bool get isLoading => status == ProfileStatus.loading;
  bool get isSaving =>
      status == ProfileStatus.saving || status == ProfileStatus.savingAvatar;
  bool get isSavingAvatar => status == ProfileStatus.savingAvatar;
  bool get hasError => status == ProfileStatus.error;
  bool get isSuccess => status == ProfileStatus.success;

  // --------------------------------------------------------------------------
  // copyWith
  // --------------------------------------------------------------------------

  ProfileState copyWith({
    ProfileStatus? status,
    AppUser? user,
    bool? isEditing,
    String? errorMessage,
    String? successMessage,
    String? editNombre,
    String? editApellidoPaterno,
    String? editApellidoMaterno,
    bool clearMessages = false,
    bool clearEditFields = false,
  }) => ProfileState(
    status: status ?? this.status,
    user: user ?? this.user,
    isEditing: isEditing ?? this.isEditing,
    errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
    successMessage: clearMessages
        ? null
        : successMessage ?? this.successMessage,
    editNombre: clearEditFields ? null : editNombre ?? this.editNombre,
    editApellidoPaterno: clearEditFields
        ? null
        : editApellidoPaterno ?? this.editApellidoPaterno,
    editApellidoMaterno: clearEditFields
        ? null
        : editApellidoMaterno ?? this.editApellidoMaterno,
  );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._repo, this._ref) : super(const ProfileState()) {
    _load();
  }

  final IProfileRepository _repo;
  final Ref _ref;

  // --------------------------------------------------------------------------
  // Load
  // --------------------------------------------------------------------------

  Future<void> _load() async {
    state = state.copyWith(status: ProfileStatus.loading);
    final user = await _repo.getProfile();
    state = state.copyWith(status: ProfileStatus.idle, user: user);
  }

  /// Recarga el perfil desde la sesión (útil tras volver de edición).
  Future<void> reload() => _load();

  // --------------------------------------------------------------------------
  // Modo edición
  // --------------------------------------------------------------------------

  /// Entra al modo edición, inicializando los campos con los datos actuales.
  void startEdit() {
    if (state.user == null) return;
    state = state.copyWith(
      isEditing: true,
      editNombre: state.user!.nombre,
      editApellidoPaterno: state.user!.apellidoPaterno,
      editApellidoMaterno: state.user!.apellidoMaterno,
      clearMessages: true,
    );
  }

  /// Cancela la edición y restaura los valores originales.
  void cancelEdit() {
    state = state.copyWith(
      isEditing: false,
      clearEditFields: true,
      clearMessages: true,
    );
  }

  /// Actualiza un campo del formulario de edición sin guardar.
  void updateField({
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
  }) {
    state = state.copyWith(
      editNombre: nombre ?? state.editNombre,
      editApellidoPaterno: apellidoPaterno ?? state.editApellidoPaterno,
      editApellidoMaterno: apellidoMaterno ?? state.editApellidoMaterno,
    );
  }

  // --------------------------------------------------------------------------
  // Guardar perfil — RF-Profile-01
  // --------------------------------------------------------------------------

  Future<void> saveProfile() async {
    if (state.user == null) return;

    final cmd = UpdateProfileCommand(
      nombre: state.editNombre ?? state.user!.nombre,
      apellidoPaterno: state.editApellidoPaterno ?? state.user!.apellidoPaterno,
      apellidoMaterno: state.editApellidoMaterno ?? state.user!.apellidoMaterno,
    );

    if (!cmd.isValid) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Nombre y apellidos son obligatorios.',
      );
      return;
    }

    state = state.copyWith(status: ProfileStatus.saving, clearMessages: true);

    try {
      final updated = await _repo.updateProfile(cmd, current: state.user!);
      // Sincronizar estado global de sesión
      _ref.read(authProvider.notifier).updateUser(updated);
      state = state.copyWith(
        status: ProfileStatus.success,
        user: updated,
        isEditing: false,
        successMessage: 'Perfil actualizado correctamente.',
        clearEditFields: true,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.userMessage,
      );
    } catch (_) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'No se pudo guardar el perfil. Intenta de nuevo.',
      );
    }
  }

  // --------------------------------------------------------------------------
  // Upload de avatar — RF-Profile-02
  // --------------------------------------------------------------------------

  Future<void> uploadAvatar({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
  }) async {
    if (state.user == null) return;

    state = state.copyWith(
      status: ProfileStatus.savingAvatar,
      clearMessages: true,
    );

    try {
      final url = await _repo.uploadAvatar(
        filePath: filePath,
        fileName: fileName,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
      );

      final updated = state.user!.copyWith(fotoUrl: url);
      final saved = await _repo.saveUserLocally(updated);

      // Sincronizar estado global de sesión
      _ref.read(authProvider.notifier).updateUser(saved);

      state = state.copyWith(
        status: ProfileStatus.success,
        user: saved,
        successMessage: 'Avatar actualizado correctamente.',
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.userMessage,
      );
    } catch (_) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'No se pudo subir la imagen. Intenta de nuevo.',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true, status: ProfileStatus.idle);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  return ProfileNotifier(ref.read(profileRepositoryProvider), ref);
});
