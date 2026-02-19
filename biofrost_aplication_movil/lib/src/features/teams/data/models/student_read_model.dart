/// Alumno sin equipo asignado — mapeado desde [StudentDto].
///
/// Devuelto por `GET /api/teams/available-students?groupId=`.
class StudentReadModel {
  const StudentReadModel({
    required this.id,
    required this.nombreCompleto,
    required this.matricula,
    this.fotoUrl = '',
  });

  final String id;
  final String nombreCompleto;
  final String matricula;
  final String fotoUrl;

  String get initials {
    final parts = nombreCompleto.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory StudentReadModel.fromJson(Map<String, dynamic> json) {
    return StudentReadModel(
      id: json['id'] as String? ?? '',
      nombreCompleto: json['nombreCompleto'] as String? ?? '',
      matricula: json['matricula'] as String? ?? 'S/M',
      fotoUrl: json['fotoUrl'] as String? ?? '',
    );
  }
}
