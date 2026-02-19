/// Docente asignado al grupo — mapeado desde [TeacherDto].
///
/// Devuelto por `GET /api/teams/available-teachers?groupId=`.
class TeacherReadModel {
  const TeacherReadModel({
    required this.id,
    required this.nombreCompleto,
    required this.profesion,
    required this.carrera,
    required this.asignatura,
    this.materiaId,
    this.esAltaPrioridad = false,
  });

  final String id;
  final String nombreCompleto;
  final String profesion;
  final String carrera;
  final String asignatura;
  final String? materiaId;

  /// Si la materia asignada es de alta prioridad (Integradora).
  final bool esAltaPrioridad;

  String get initials {
    final parts = nombreCompleto.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory TeacherReadModel.fromJson(Map<String, dynamic> json) {
    return TeacherReadModel(
      id: json['id'] as String? ?? '',
      nombreCompleto: json['nombreCompleto'] as String? ?? '',
      profesion: json['profesion'] as String? ?? 'Docente',
      carrera: json['carrera'] as String? ?? '',
      asignatura: json['asignatura'] as String? ?? '',
      materiaId: json['materiaId'] as String?,
      esAltaPrioridad: json['esAltaPrioridad'] as bool? ?? false,
    );
  }
}
