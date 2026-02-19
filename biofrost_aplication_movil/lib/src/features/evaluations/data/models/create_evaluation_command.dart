/// Payload para `POST /api/Evaluations`.
class CreateEvaluationCommand {
  const CreateEvaluationCommand({
    required this.projectId,
    required this.docenteId,
    required this.docenteNombre,
    required this.tipo,
    required this.contenido,
    this.calificacion,
  });

  final String projectId;
  final String docenteId;
  final String docenteNombre;

  /// `"oficial"` | `"sugerencia"`
  final String tipo;
  final String contenido;
  final int? calificacion;

  /// Valida las reglas de negocio antes de enviar.
  bool get isValid {
    if (contenido.trim().isEmpty) return false;
    if (tipo == 'oficial') {
      return calificacion != null && calificacion! >= 0 && calificacion! <= 100;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'docenteId': docenteId,
    'docenteNombre': docenteNombre,
    'tipo': tipo,
    'contenido': contenido,
    if (calificacion != null) 'calificacion': calificacion,
  };
}
