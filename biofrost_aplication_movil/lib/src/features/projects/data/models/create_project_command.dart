// Payload para POST /api/projects
class CreateProjectCommand {
  const CreateProjectCommand({
    required this.titulo,
    required this.materia,
    required this.materiaId,
    required this.ciclo,
    required this.stackTecnologico,
    required this.userId,
    required this.userGroupId,
    this.repositorioUrl,
    this.videoUrl,
    this.docenteId,
    this.miembrosIds,
  });

  final String titulo;
  final String materia;
  final String materiaId;
  final String ciclo;
  final List<String> stackTecnologico;
  final String userId;
  final String userGroupId;
  final String? repositorioUrl;
  final String? videoUrl;
  final String? docenteId;
  final List<String>? miembrosIds;

  bool get isValid =>
      titulo.trim().isNotEmpty &&
      materia.trim().isNotEmpty &&
      materiaId.trim().isNotEmpty &&
      ciclo.trim().isNotEmpty &&
      stackTecnologico.isNotEmpty &&
      userId.trim().isNotEmpty &&
      userGroupId.trim().isNotEmpty &&
      (miembrosIds == null || miembrosIds!.length <= 4);

  Map<String, dynamic> toJson() => {
    'titulo': titulo.trim(),
    'materia': materia.trim(),
    'materiaId': materiaId.trim(),
    'ciclo': ciclo.trim(),
    'stackTecnologico': stackTecnologico,
    'userId': userId,
    'userGroupId': userGroupId,
    if (repositorioUrl != null && repositorioUrl!.isNotEmpty)
      'repositorioUrl': repositorioUrl,
    if (videoUrl != null && videoUrl!.isNotEmpty) 'videoUrl': videoUrl,
    if (docenteId != null && docenteId!.isNotEmpty) 'docenteId': docenteId,
    if (miembrosIds != null) 'miembrosIds': miembrosIds,
  };
}
