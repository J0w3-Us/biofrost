import 'package:equatable/equatable.dart';

/// ReadModel de evaluación — para mostrar historial (CQRS Query).
///
/// Documentado en:
/// - IntegradorHub/docs/frontend/05_EVALUATIONS.md § Visualización de Evaluaciones
class EvaluationReadModel extends Equatable {
  const EvaluationReadModel({
    required this.id,
    required this.projectId,
    required this.docenteId,
    required this.docenteNombre,
    required this.tipo,
    required this.contenido,
    required this.esPublico,
    this.calificacion,
    this.createdAt,
  });

  final String id;
  final String projectId;
  final String docenteId;
  final String docenteNombre;
  /// 'sugerencia' | 'oficial'
  final String tipo;
  final String contenido;
  final bool esPublico;
  /// Calificación 0-100. Solo presente si tipo == 'oficial'.
  final double? calificacion;
  final DateTime? createdAt;

  // ── Computed ────────────────────────────────────────────────────────

  bool get isOficial => tipo == 'oficial';
  bool get isSugerencia => tipo == 'sugerencia';
  bool get hasGrade => calificacion != null;

  /// Calificación formateada como string (ej: "85.0" → "85").
  String? get calificacionDisplay {
    if (calificacion == null) return null;
    final val = calificacion!;
    return (val == val.toInt().toDouble())
        ? val.toInt().toString()
        : val.toStringAsFixed(1);
  }

  /// Fecha formateada en formato local mexicano (es-MX).
  String get fechaFormateada {
    if (createdAt == null) return 'Sin fecha';
    final d = createdAt!;
    return '${d.day}/${d.month}/${d.year} ${_pad(d.hour)}:${_pad(d.minute)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  // ── Factory desde JSON del backend .NET ─────────────────────────────

  factory EvaluationReadModel.fromJson(Map<String, dynamic> json) {
    return EvaluationReadModel(
      id: _str(json, ['id', 'Id']) ?? '',
      projectId: _str(json, ['projectId', 'ProjectId']) ?? '',
      docenteId: _str(json, ['docenteId', 'DocenteId']) ?? '',
      docenteNombre: _str(json, ['docenteNombre', 'DocenteNombre']) ?? 'Docente',
      tipo: _str(json, ['tipo', 'Tipo']) ?? 'sugerencia',
      contenido: _str(json, ['contenido', 'Contenido']) ?? '',
      esPublico: (json['esPublico'] ?? json['EsPublico']) as bool? ?? false,
      calificacion: _double(json, ['calificacion', 'Calificacion']),
      createdAt: _datetime(json, ['createdAt', 'CreatedAt']),
    );
  }

  @override
  List<Object?> get props => [id, tipo, contenido, calificacion, esPublico];

  EvaluationReadModel copyWith({bool? esPublico}) {
    return EvaluationReadModel(
      id: id,
      projectId: projectId,
      docenteId: docenteId,
      docenteNombre: docenteNombre,
      tipo: tipo,
      contenido: contenido,
      esPublico: esPublico ?? this.esPublico,
      calificacion: calificacion,
      createdAt: createdAt,
    );
  }
}

// ── CommandModel: Crear Evaluación (CQRS Command) ─────────────────────

/// CommandModel para crear una nueva evaluación.
/// Refleja el payload documentado en 05_EVALUATIONS.md § Payload de Creación.
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

// ── CommandModel: Cambiar visibilidad (CQRS Command) ──────────────────

/// CommandModel para cambiar visibilidad pública/privada de una evaluación.
/// Refleja el payload de 05_EVALUATIONS.md § Payload de Visibilidad.
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

// ── Helpers ────────────────────────────────────────────────────────────

String? _str(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final val = json[key];
    if (val is String && val.isNotEmpty) return val;
  }
  return null;
}

double? _double(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final val = json[key];
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val);
  }
  return null;
}

DateTime? _datetime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final val = json[key];
    if (val == null) continue;
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    if (val is Map && val['seconds'] is int) {
      return DateTime.fromMillisecondsSinceEpoch(
          (val['seconds'] as int) * 1000);
    }
  }
  return null;
}

