import 'canvas_block_model.dart';

/// Modelo del proyecto público retornado por `GET /api/projects/public`.
///
/// Mapeado desde `PublicProjectDto` del backend.
class PublicProjectReadModel {
  const PublicProjectReadModel({
    required this.id,
    required this.titulo,
    required this.materia,
    required this.ciclo,
    required this.stackTecnologico,
    required this.liderNombre,
    required this.miembrosIds,
    required this.estado,
    required this.descripcion,
    required this.canvas,
    required this.createdAt,
    this.thumbnailUrl,
    this.repositorioUrl,
    this.demoUrl,
    this.videoUrl,
    this.docenteNombre,
  });

  final String id;
  final String titulo;
  final String materia;
  final String ciclo;
  final List<String> stackTecnologico;
  final String? thumbnailUrl;
  final String? repositorioUrl;
  final String? demoUrl;
  final String? videoUrl;
  final String liderNombre;
  final List<String> miembrosIds;
  final String? docenteNombre;
  final String estado;
  final String descripcion;
  final List<CanvasBlockModel> canvas;
  final DateTime createdAt;

  int get miembrosCount => miembrosIds.length;
  bool get hasRepo => repositorioUrl != null && repositorioUrl!.isNotEmpty;
  bool get hasDemo => demoUrl != null && demoUrl!.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasThumbnail => thumbnailUrl != null && thumbnailUrl!.isNotEmpty;

  /// Extrae una descripción legible desde el canvas si `descripcion` está vacío.
  String get displayDescription {
    if (descripcion.isNotEmpty) return descripcion;
    final textBlock = canvas.where((b) => b.isText).toList();
    if (textBlock.isEmpty) return '';
    return textBlock.first.content;
  }

  factory PublicProjectReadModel.fromJson(Map<String, dynamic> json) {
    final stackRaw = json['stackTecnologico'] as List<dynamic>? ?? [];
    final miembrosRaw = json['miembrosIds'] as List<dynamic>? ?? [];
    final canvasRaw = json['canvas'] as List<dynamic>? ?? [];

    return PublicProjectReadModel(
      id: json['id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      materia: json['materia'] as String? ?? '',
      ciclo: json['ciclo'] as String? ?? '',
      stackTecnologico: stackRaw.cast<String>(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      repositorioUrl: json['repositorioUrl'] as String?,
      demoUrl: json['demoUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      liderNombre: json['liderNombre'] as String? ?? 'Desconocido',
      miembrosIds: miembrosRaw.cast<String>(),
      docenteNombre: json['docenteNombre'] as String?,
      estado: json['estado'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      canvas:
          canvasRaw
              .whereType<Map<String, dynamic>>()
              .map(CanvasBlockModel.fromJson)
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order)),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
