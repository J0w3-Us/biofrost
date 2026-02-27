import 'package:equatable/equatable.dart';

/// ReadModel de proyecto — optimizado para listas y tarjetas (CQRS Query).
///
/// Mapea el DTO del backend .NET (PascalCase) → Dart (camelCase).
/// Separado de [ProjectDetailReadModel] para optimizar el listado.
class ProjectReadModel extends Equatable {
  const ProjectReadModel({
    required this.id,
    required this.titulo,
    required this.materia,
    required this.estado,
    required this.stackTecnologico,
    this.liderNombre,
    this.liderId,
    this.liderFotoUrl,
    this.docenteId,
    this.docenteNombre,
    this.ciclo,
    this.puntosTotales,
    this.conteoVotos,
    this.votantes,
    this.esPublico = false,
    this.videoUrl,
    this.videoFilePath,
    this.createdAt,
    this.grupoId,
    this.thumbnailUrl,
    this.descripcion,
  });

  final String id;
  final String titulo;
  final String materia;

  /// 'Activo' | 'Completado' | 'Borrador'
  final String estado;
  final List<String> stackTecnologico;
  final String? liderNombre;
  final String? liderId;
  final String? liderFotoUrl;
  final String? docenteId;
  final String? docenteNombre;
  final String? ciclo;
  final int? puntosTotales;

  /// Suma acumulada de puntos de votos individuales.
  final int? conteoVotos;

  /// Mapa userId → stars. Permite saber si el usuario ya votó.
  final Map<String, int>? votantes;
  final bool esPublico;
  final String? videoUrl;
  final String? videoFilePath;
  final DateTime? createdAt;
  final String? grupoId;
  final String? thumbnailUrl;
  final String? descripcion;

  // ── Computed ───────────────────────────────────────────────────────

  List<String> get stackPreview => stackTecnologico.take(3).toList();

  int get stackOverflow =>
      stackTecnologico.length > 3 ? stackTecnologico.length - 3 : 0;

  String get estadoColor {
    switch (estado) {
      case 'Activo':
        return 'green';
      case 'Completado':
        return 'blue';
      default:
        return 'gray';
    }
  }

  // ── Factory desde JSON del backend .NET ───────────────────────────

  factory ProjectReadModel.fromJson(Map<String, dynamic> json) {
    return ProjectReadModel(
      id: _str(json, ['id', 'Id']) ?? '',
      titulo: _str(json, ['titulo', 'Titulo']) ?? 'Sin título',
      materia: _str(json, ['materia', 'Materia']) ?? '',
      estado: _str(json, ['estado', 'Estado']) ?? 'Borrador',
      stackTecnologico:
          _strList(json, ['stackTecnologico', 'StackTecnologico']),
      liderNombre: _str(json, ['liderNombre', 'LiderNombre']),
      liderId: _str(json, ['liderId', 'LiderId']),
      liderFotoUrl: _str(json, ['liderFotoUrl', 'LiderFotoUrl']),
      docenteId: _str(json, ['docenteId', 'DocenteId']),
      docenteNombre: _str(json, ['docenteNombre', 'DocenteNombre']),
      ciclo: _str(json, ['ciclo', 'Ciclo']),
      puntosTotales: _int(json, ['puntosTotales', 'PuntosTotales']),
      conteoVotos: _int(json, ['conteoVotos', 'ConteoVotos']),
      votantes: _votantesMap(json, ['votantes', 'Votantes']),
      esPublico: _bool(json, ['esPublico', 'EsPublico']),
      videoUrl: _str(json, ['videoUrl', 'VideoUrl']),
      videoFilePath:
          _str(json, ['videoFilePath', 'VideoFilePath', 'videoFilePath']),
      createdAt: _datetime(json, ['createdAt', 'CreatedAt']),
      grupoId: _str(json, ['grupoId', 'GrupoId']),
      thumbnailUrl: _str(json, ['thumbnailUrl', 'ThumbnailUrl']),
      descripcion: _str(json, ['descripcion', 'Descripcion']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'materia': materia,
        'estado': estado,
        'stackTecnologico': stackTecnologico,
        'liderNombre': liderNombre,
        'liderId': liderId,
        'liderFotoUrl': liderFotoUrl,
        'docenteId': docenteId,
        'docenteNombre': docenteNombre,
        'ciclo': ciclo,
        'puntosTotales': puntosTotales,
        'conteoVotos': conteoVotos,
        'votantes': votantes,
        'esPublico': esPublico,
        'videoUrl': videoUrl,
        'videoFilePath': videoFilePath,
        'createdAt': createdAt?.toIso8601String(),
        'grupoId': grupoId,
        'thumbnailUrl': thumbnailUrl,
        'descripcion': descripcion,
      };

  @override
  List<Object?> get props => [
        id,
        titulo,
        materia,
        estado,
        stackTecnologico,
        liderNombre,
        docenteId,
        puntosTotales,
        esPublico,
      ];
}

// ── Helpers de normalización ───────────────────────────────────────────

String? _str(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final val = json[key];
    if (val is String && val.isNotEmpty) return val;
  }
  return null;
}

List<String> _strList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final val = json[key];
    if (val is List) return val.map((e) => e.toString()).toList();
  }
  return [];
}

int? _int(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final val = json[key];
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val);
  }
  return null;
}

bool _bool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final val = json[key];
    if (val is bool) return val;
    if (val is int) return val == 1;
  }
  return false;
}

Map<String, int>? _votantesMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final val = json[key];
    if (val is Map) {
      try {
        return val.map((k, v) => MapEntry(
              k.toString(),
              v is int
                  ? v
                  : (v is double ? v.toInt() : int.tryParse(v.toString()) ?? 0),
            ));
      } catch (_) {
        return null;
      }
    }
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
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val * 1000);
  }
  return null;
}
