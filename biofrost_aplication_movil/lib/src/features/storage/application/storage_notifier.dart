import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../data/models/commands/upload_file_command.dart';
import '../data/models/read/uploaded_file_read_model.dart';
import '../data/repositories/storage_repository.dart';

// Implementa RF-Storage-01: Estado y lógica de subida/gestión de archivos.

// ---------------------------------------------------------------------------
// Estado
// ---------------------------------------------------------------------------

enum StorageStatus { idle, uploading, success, error }

class StorageState {
  const StorageState({
    this.status = StorageStatus.idle,
    this.uploadedFiles = const [],
    this.pendingCommands = const [],
    this.selectedFolder = 'projects',
    this.uploadProgress = 0.0,
    this.uploadDone = 0,
    this.uploadTotal = 0,
    this.errorMessage,
  });

  /// Estado actual del módulo.
  final StorageStatus status;

  /// Archivos subidos exitosamente en esta sesión.
  final List<UploadedFile> uploadedFiles;

  /// Comandos pendientes de subida (archivos seleccionados, no subidos aún).
  final List<UploadFileCommand> pendingCommands;

  /// Carpeta destino seleccionada por el usuario.
  final String selectedFolder;

  /// Progreso de subida (0.0 – 1.0).
  final double uploadProgress;

  /// Número de archivos subidos en el lote actual.
  final int uploadDone;

  /// Total de archivos en el lote actual.
  final int uploadTotal;

  /// Mensaje de error para mostrar en la UI.
  final String? errorMessage;

  // --------------------------------------------------------------------------
  // Derived
  // --------------------------------------------------------------------------

  bool get isUploading => status == StorageStatus.uploading;
  bool get hasError => status == StorageStatus.error;
  bool get isSuccess => status == StorageStatus.success;
  bool get hasPending => pendingCommands.isNotEmpty;
  bool get hasFiles => uploadedFiles.isNotEmpty;

  String get progressLabel {
    if (uploadTotal == 0) return '';
    return '$uploadDone / $uploadTotal';
  }

  // --------------------------------------------------------------------------
  // copyWith
  // --------------------------------------------------------------------------

  StorageState copyWith({
    StorageStatus? status,
    List<UploadedFile>? uploadedFiles,
    List<UploadFileCommand>? pendingCommands,
    String? selectedFolder,
    double? uploadProgress,
    int? uploadDone,
    int? uploadTotal,
    String? errorMessage,
    bool clearError = false,
  }) => StorageState(
    status: status ?? this.status,
    uploadedFiles: uploadedFiles ?? this.uploadedFiles,
    pendingCommands: pendingCommands ?? this.pendingCommands,
    selectedFolder: selectedFolder ?? this.selectedFolder,
    uploadProgress: uploadProgress ?? this.uploadProgress,
    uploadDone: uploadDone ?? this.uploadDone,
    uploadTotal: uploadTotal ?? this.uploadTotal,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class StorageNotifier extends StateNotifier<StorageState> {
  StorageNotifier(this._repo) : super(const StorageState());

  final IStorageRepository _repo;

  // --------------------------------------------------------------------------
  // Configuración
  // --------------------------------------------------------------------------

  /// Actualiza la carpeta destino.
  void setFolder(String folder) =>
      state = state.copyWith(selectedFolder: folder);

  /// Establece los archivos seleccionados antes de subir.
  void setPending(List<UploadFileCommand> commands) {
    state = state.copyWith(
      pendingCommands: commands,
      status: StorageStatus.idle,
      clearError: true,
    );
  }

  /// Descarta los archivos pendientes sin subir.
  void clearPending() {
    state = state.copyWith(pendingCommands: [], clearError: true);
  }

  void clearError() {
    state = state.copyWith(status: StorageStatus.idle, clearError: true);
  }

  // --------------------------------------------------------------------------
  // Upload — RF-Storage-01
  // --------------------------------------------------------------------------

  /// Sube todos los archivos pendientes usando la carpeta seleccionada.
  Future<void> uploadAll() async {
    if (state.pendingCommands.isEmpty) return;

    final commands = state.pendingCommands
        .map((c) => c.withFolder(state.selectedFolder))
        .toList();

    state = state.copyWith(
      status: StorageStatus.uploading,
      uploadDone: 0,
      uploadTotal: commands.length,
      uploadProgress: 0.0,
      clearError: true,
    );

    try {
      final newFiles = await _repo.uploadMultiple(
        commands,
        onProgress: (done, total) {
          state = state.copyWith(
            uploadDone: done,
            uploadTotal: total,
            uploadProgress: done / total,
          );
        },
      );

      state = state.copyWith(
        status: StorageStatus.success,
        uploadedFiles: [...state.uploadedFiles, ...newFiles],
        pendingCommands: [],
        uploadProgress: 1.0,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: StorageStatus.error,
        errorMessage: e.userMessage,
      );
    } catch (e) {
      state = state.copyWith(
        status: StorageStatus.error,
        errorMessage: 'Error inesperado al subir. Intenta de nuevo.',
      );
    }
  }

  // --------------------------------------------------------------------------
  // Delete — RF-Storage-02
  // --------------------------------------------------------------------------

  /// Elimina un archivo del servidor y lo quita de la lista local.
  Future<bool> deleteFile(UploadedFile file) async {
    try {
      await _repo.deleteFile(file.storagePath);
      state = state.copyWith(
        uploadedFiles: state.uploadedFiles
            .where((f) => f.url != file.url)
            .toList(),
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: StorageStatus.error,
        errorMessage: e.userMessage,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: StorageStatus.error,
        errorMessage: 'No se pudo eliminar el archivo.',
      );
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final storageProvider = StateNotifierProvider<StorageNotifier, StorageState>((
  ref,
) {
  return StorageNotifier(ref.read(storageRepositoryProvider));
});
