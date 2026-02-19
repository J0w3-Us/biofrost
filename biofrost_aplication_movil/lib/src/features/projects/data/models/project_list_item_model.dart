// Cubre tanto ProjectDto (grupo) como PublicProjectDto (galería pública).
// Campos opcionales para los que solo vienen de PublicProjectDto.
class ProjectListItemModel {
  const ProjectListItemModel({
    required this.id,
    required this.titulo,
    required this.materia,
    required this.estado,
    required this.stackTecnologico,
    required this.liderId,
    this.liderNombre,
    this.membersCount,
    this.thumbnailUrl,
    this.repositorioUrl,
    this.demoUrl,
    this.videoUrl,
    this.docenteNombre,
    this.descripcion,
    this.ciclo,
    this.createdAt,
  });

  final String id;
  final String titulo;
  final String materia;
  final String estado;
  final List<String> stackTecnologico;
  final String liderId;
  final String? liderNombre;
  final int? membersCount;
  final String? thumbnailUrl;
  final String? repositorioUrl;
  final String? demoUrl;
  final String? videoUrl;
  final String? docenteNombre;
  final String? descripcion;
  final String? ciclo;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'materia': materia,
    'estado': estado,
    'stackTecnologico': stackTecnologico,
    'liderId': liderId,
    if (liderNombre != null) 'liderNombre': liderNombre,
    if (membersCount != null) 'membersCount': membersCount,
    if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    if (repositorioUrl != null) 'repositorioUrl': repositorioUrl,
    if (demoUrl != null) 'demoUrl': demoUrl,
    if (videoUrl != null) 'videoUrl': videoUrl,
    if (docenteNombre != null) 'docenteNombre': docenteNombre,
    if (descripcion != null) 'descripcion': descripcion,
    if (ciclo != null) 'ciclo': ciclo,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  /// Construir desde ProjectDto (lista de grupo)
  factory ProjectListItemModel.fromGroupJson(Map<String, dynamic> json) {
    return ProjectListItemModel(
      id: json['id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      materia: json['materia'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      stackTecnologico:
          (json['stackTecnologico'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      liderId: json['liderId'] as String? ?? '',
      membersCount: (json['membersCount'] as num?)?.toInt(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  /// Construir desde PublicProjectDto (galería pública)
  factory ProjectListItemModel.fromPublicJson(Map<String, dynamic> json) {
    return ProjectListItemModel(
      id: json['id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      materia: json['materia'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      stackTecnologico:
          (json['stackTecnologico'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      liderId: '',
      liderNombre: json['liderNombre'] as String?,
      membersCount: (json['miembrosIds'] as List<dynamic>?)?.length,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      repositorioUrl: json['repositorioUrl'] as String?,
      demoUrl: json['demoUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      docenteNombre: json['docenteNombre'] as String?,
      descripcion: json['descripcion'] as String?,
      ciclo: json['ciclo'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
