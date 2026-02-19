import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../models/commands/upload_file_command.dart';
import '../models/read/uploaded_file_read_model.dart';

// Implementa RF-Storage-01: Subida de archivos al backend (JWT requerido).
// Implementa RF-Storage-02: Eliminación de archivos (propietario / Admin).

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

abstract interface class IStorageRepository {
  /// Sube un solo archivo. Retorna el [UploadedFile] con la URL pública.
  Future<UploadedFile> uploadSingle(UploadFileCommand command);

  /// Sube múltiples archivos de forma secuencial con progreso.
  Future<List<UploadedFile>> uploadMultiple(
    List<UploadFileCommand> commands, {
    void Function(int done, int total)? onProgress,
  });

  /// Elimina un archivo del storage usando su ruta relativa.
  Future<void> deleteFile(String storagePath);
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class StorageRepository implements IStorageRepository {
  StorageRepository(this._client);

  final ApiClient _client;

  @override
  Future<UploadedFile> uploadSingle(UploadFileCommand cmd) async {
    final file = File(cmd.filePath);
    final bytes = await file.readAsBytes();

    final res = await _client.uploadFile(
      '/api/storage/upload',
      fileBytes: bytes,
      filename: cmd.fileName,
      fieldName: 'file',
      folder: cmd.folder,
    );

    return UploadedFile.fromApiResponse(
      res,
      fileName: cmd.fileName,
      folder: cmd.folder ?? 'general',
      sizeBytes: cmd.sizeBytes,
      mimeType: cmd.mimeType,
    );
  }

  @override
  Future<List<UploadedFile>> uploadMultiple(
    List<UploadFileCommand> commands, {
    void Function(int done, int total)? onProgress,
  }) async {
    final results = <UploadedFile>[];
    for (var i = 0; i < commands.length; i++) {
      results.add(await uploadSingle(commands[i]));
      onProgress?.call(i + 1, commands.length);
    }
    return results;
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    // El path puede contener slashes: DELETE /api/storage/projects/foto.jpg
    await _client.delete('/api/storage/$storagePath');
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final storageRepositoryProvider = Provider<IStorageRepository>((ref) {
  return StorageRepository(ref.read(apiClientProvider));
});
