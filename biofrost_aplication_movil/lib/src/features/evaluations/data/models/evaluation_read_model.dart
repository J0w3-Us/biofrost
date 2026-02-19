/// Evaluación recibida del backend — mapeada desde [EvaluationDto].
///
/// Tipos: `oficial` (solo docentes, requiere calificación 0-100)
///         `sugerencia` (docente con observación libre, sin calificación)
class EvaluationReadModel {
  const EvaluationReadModel({
    required this.id,
    required this.projectId,
    required this.docenteId,
    required this.docenteNombre,
    required this.tipo,
    required this.contenido,
    required this.createdAt,
    this.calificacion,
  });

  final String id;
  final String projectId;
  final String docenteId;
  final String docenteNombre;

  /// `"oficial"` | `"sugerencia"`
  final String tipo;
  final String contenido;

  /// Solo para tipo `"oficial"` — valor entre 0 y 100.
  final int? calificacion;
  final DateTime createdAt;

  bool get isOficial => tipo == 'oficial';
  bool get hasCaliificacion => calificacion != null;

  factory EvaluationReadModel.fromJson(Map<String, dynamic> json) {
    return EvaluationReadModel(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      docenteId: json['docenteId'] as String? ?? '',
      docenteNombre: json['docenteNombre'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'sugerencia',
      contenido: json['contenido'] as String? ?? '',
      calificacion: (json['calificacion'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
