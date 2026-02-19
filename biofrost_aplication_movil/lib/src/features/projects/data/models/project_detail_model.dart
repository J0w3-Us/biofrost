import '../../../showcase/data/models/canvas_block_model.dart';
import 'member_model.dart';

// ProjectDetailsDto del backend → ProjectDetailModel en Flutter.
class ProjectDetailModel {
  const ProjectDetailModel({
    required this.id,
    required this.titulo,
    required this.materia,
    required this.materiaId,
    required this.ciclo,
    required this.estado,
    required this.liderId,
    required this.miembrosIds,
    required this.stackTecnologico,
    required this.canvas,
    required this.members,
    required this.createdAt,
    required this.esPublico,
    this.repositorioUrl,
    this.videoUrl,
  });

  final String id;
  final String titulo;
  final String materia;
  final String materiaId;
  final String ciclo;
  final String estado;
  final String liderId;
  final List<String> miembrosIds;
  final List<String> stackTecnologico;
  final String? repositorioUrl;
  final String? videoUrl;
  final List<CanvasBlockModel> canvas;
  final List<MemberModel> members;
  final DateTime createdAt;
  final bool esPublico;

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'materia': materia,
    'materiaId': materiaId,
    'ciclo': ciclo,
    'estado': estado,
    'liderId': liderId,
    'miembrosIds': miembrosIds,
    'stackTecnologico': stackTecnologico,
    if (repositorioUrl != null) 'repositorioUrl': repositorioUrl,
    if (videoUrl != null) 'videoUrl': videoUrl,
    'canvas': canvas.map((b) => b.toJson()).toList(),
    'members': members.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'esPublico': esPublico,
  };

  factory ProjectDetailModel.fromJson(Map<String, dynamic> json) {
    return ProjectDetailModel(
      id: json['id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      materia: json['materia'] as String? ?? '',
      materiaId: json['materiaId'] as String? ?? '',
      ciclo: json['ciclo'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      liderId: json['liderId'] as String? ?? '',
      miembrosIds:
          (json['miembrosIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      stackTecnologico:
          (json['stackTecnologico'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      repositorioUrl: json['repositorioUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      canvas:
          (json['canvas'] as List<dynamic>?)
              ?.map((e) => CanvasBlockModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      members:
          (json['members'] as List<dynamic>?)
              ?.map((e) => MemberModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      esPublico: json['esPublico'] as bool? ?? false,
    );
  }
}
