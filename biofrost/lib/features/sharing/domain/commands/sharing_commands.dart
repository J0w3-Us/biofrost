/// CQRS Commands para el dominio de compartir proyectos.

// ── Command: Compartir proyecto ───────────────────────────────────────

/// Command para compartir un proyecto vía deep link / imagen.
class ShareProjectLinkCommand {
  const ShareProjectLinkCommand({
    required this.projectId,
    required this.titulo,
    required this.stackPreview,
  });

  final String projectId;
  final String titulo;
  final List<String> stackPreview;

  String get deepLink => 'biofrost://project/$projectId';
  String get webLink => 'https://integradorhub.utm.mx/showcase/$projectId';
}

// ── Command: Guardar imagen en galería ────────────────────────────────

/// Command para guardar una imagen capturada en la galería del dispositivo.
class SaveImageToGalleryCommand {
  const SaveImageToGalleryCommand({
    required this.imageBytes,
    required this.fileName,
  });

  final List<int> imageBytes;
  final String fileName;
}
