/// CQRS Commands para el dominio de evaluaciones.
///
/// Documentado en AI/rules.md §2: "Convenciones: CreateMyEntityCommand".

// ── Command: Crear evaluación ─────────────────────────────────────────

/// CommandModel para crear una nueva evaluación.
///
/// Endpoint: POST /api/evaluations
class CreateEvaluationCommand {
  const CreateEvaluationCommand({
    required this.projectId,
    required this.docenteId,
    required this.docenteNombre,
    required this.tipo,
    required this.contenido,
    this.calificacion,
  }) : assert(
          tipo == 'sugerencia' || tipo == 'oficial',
          'tipo debe ser "sugerencia" o "oficial"',
        );

  final String projectId;
  final String docenteId;
  final String docenteNombre;

  /// 'sugerencia' | 'oficial'
  final String tipo;
  final String contenido;

  /// Solo requerido si tipo == 'oficial'. Rango: 0-100.
  final double? calificacion;

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'docenteId': docenteId,
        'docenteNombre': docenteNombre,
        'tipo': tipo,
        'contenido': contenido,
        'calificacion': calificacion,
      };
}

// ── Command: Cambiar visibilidad ───────────────────────────────────────

/// CommandModel para cambiar visibilidad pública/privada de una evaluación.
///
/// Endpoint: PATCH /api/evaluations/{id}/visibility
class ToggleEvaluationVisibilityCommand {
  const ToggleEvaluationVisibilityCommand({
    required this.evaluationId,
    required this.userId,
    required this.esPublico,
  });

  final String evaluationId;
  final String userId;
  final bool esPublico;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'esPublico': esPublico,
      };
}
