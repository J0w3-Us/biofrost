import 'package:equatable/equatable.dart';

/// ReadModel de evaluación — para mostrar historial (CQRS Query).
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

  // ── Computed ───────────────────────────────────────────────────────

  bool get isOficial => tipo == 'oficial';
  bool get isSugerencia => tipo == 'sugerencia';
  bool get hasGrade => calificacion != null;

  String? get calificacionDisplay {
    if (calificacion == null) return null;
    final val = calificacion!;
    return (val == val.toInt().toDouble())
        ? val.toInt().toString()
        : val.toStringAsFixed(1);
  }

  String get fechaFormateada {
    if (createdAt == null) return 'Sin fecha';
    final d = createdAt!;
    return '${d.day}/${d.month}/${d.year} ${_pad(d.hour)}:${_pad(d.minute)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  // ── Factory desde JSON del backend .NET ───────────────────────────

  factory EvaluationReadModel.fromJson(Map<String, dynamic> json) {
    return EvaluationReadModel(
      id: _str(json, ['id', 'Id']) ?? '',
      projectId: _str(json, ['projectId', 'ProjectId']) ?? '',
      docenteId: _str(json, ['docenteId', 'DocenteId']) ?? '',
      docenteNombre:
          _str(json, ['docenteNombre', 'DocenteNombre']) ?? 'Docente',
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
