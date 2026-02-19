// Implementa RF-Storage-01: Comandos de subida de archivos.

/// Comando para subir uno o más archivos al backend.
class UploadFileCommand {
  const UploadFileCommand({
    required this.filePath,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.folder,
  });

  /// Ruta local del archivo en el dispositivo.
  final String filePath;

  /// Nombre del archivo (se envía como filename en multipart).
  final String fileName;

  /// MIME type del archivo (ej: "image/jpeg").
  final String mimeType;

  /// Tamaño del archivo en bytes.
  final int sizeBytes;

  /// Carpeta destino en el servidor (ej: "projects", "showcase").
  final String? folder;

  UploadFileCommand withFolder(String folder) => UploadFileCommand(
    filePath: filePath,
    fileName: fileName,
    mimeType: mimeType,
    sizeBytes: sizeBytes,
    folder: folder,
  );
}
