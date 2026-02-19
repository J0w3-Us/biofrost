// Implementa RF-Storage-01: Modelo de archivo subido al servidor.

/// Representa un archivo que fue subido exitosamente al backend.
/// Construido localmente a partir de la respuesta de la API + metadatos del archivo.
class UploadedFile {
  const UploadedFile({
    required this.url,
    required this.fileName,
    required this.folder,
    required this.uploadedAt,
    required this.sizeBytes,
    required this.mimeType,
  });

  /// URL pública del archivo en el servidor (Firebase Storage).
  final String url;

  /// Nombre original del archivo (ej: "foto_proyecto.jpg").
  final String fileName;

  /// Carpeta donde fue almacenado (ej: "projects", "showcase").
  final String folder;

  /// Timestamp de cuando fue subido (local).
  final DateTime uploadedAt;

  /// Tamaño en bytes.
  final int sizeBytes;

  /// MIME type (ej: "image/jpeg", "application/pdf").
  final String mimeType;

  // --------------------------------------------------------------------------
  // Derived properties
  // --------------------------------------------------------------------------

  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get isPdf => mimeType == 'application/pdf';
  bool get isDocument =>
      isPdf ||
      mimeType.contains('word') ||
      mimeType.contains('excel') ||
      mimeType.contains('spreadsheet') ||
      mimeType.contains('presentation');

  /// Tamaño formateado (ej: "1.2 MB").
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Extrae el path relativo para el endpoint DELETE.
  /// La URL tiene forma: https://host/path/to/file → devuelve "path/to/file"
  String get storagePath {
    try {
      final uri = Uri.parse(url);
      // Remover slash inicial, si existe
      return uri.path.replaceFirst(RegExp(r'^/'), '');
    } catch (_) {
      return url;
    }
  }

  // --------------------------------------------------------------------------
  // Factory desde respuesta de API
  // --------------------------------------------------------------------------

  /// Construye un [UploadedFile] desde la respuesta JSON del backend.
  /// El backend puede retornar `{ "url": "..." }` o `{ "Url": "..." }`.
  static UploadedFile fromApiResponse(
    dynamic json, {
    required String fileName,
    required String folder,
    required int sizeBytes,
    required String mimeType,
  }) {
    String url = '';
    if (json is Map) {
      url =
          (json['url'] ??
                  json['Url'] ??
                  json['URL'] ??
                  json['fileUrl'] ??
                  json['FileUrl'] ??
                  '')
              .toString();
    } else if (json is String) {
      url = json;
    }

    return UploadedFile(
      url: url,
      fileName: fileName,
      folder: folder,
      uploadedAt: DateTime.now(),
      sizeBytes: sizeBytes,
      mimeType: mimeType,
    );
  }

  UploadedFile copyWith({
    String? url,
    String? fileName,
    String? folder,
    DateTime? uploadedAt,
    int? sizeBytes,
    String? mimeType,
  }) => UploadedFile(
    url: url ?? this.url,
    fileName: fileName ?? this.fileName,
    folder: folder ?? this.folder,
    uploadedAt: uploadedAt ?? this.uploadedAt,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    mimeType: mimeType ?? this.mimeType,
  );
}
