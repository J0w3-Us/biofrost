import '../../../showcase/data/models/canvas_block_model.dart';

// Payload para PUT /api/projects/{id}
class UpdateProjectCommand {
  const UpdateProjectCommand({
    required this.titulo,
    this.videoUrl,
    this.canvasBlocks,
    this.esPublico,
  });

  final String titulo;
  final String? videoUrl;
  final List<CanvasBlockModel>? canvasBlocks;
  final bool? esPublico;

  Map<String, dynamic> toJson() => {
    'titulo': titulo.trim(),
    if (videoUrl != null) 'videoUrl': videoUrl,
    if (canvasBlocks != null)
      'canvasBlocks': canvasBlocks!
          .map(
            (b) => {
              'id': b.id,
              'type': b.type,
              'content': b.content,
              'order': b.order,
              if (b.metadata != null) 'metadata': b.metadata,
            },
          )
          .toList(),
    if (esPublico != null) 'esPublico': esPublico,
  };
}
