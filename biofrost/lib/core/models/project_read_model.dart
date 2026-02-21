import 'package:equatable/equatable.dart';

/// ReadModel de proyecto — optimizado para listas y tarjetas (CQRS Query).
///
/// Mapea el DTO del backend .NET (PascalCase) → Dart (camelCase).
/// Documentado en:
/// - IntegradorHub/docs/frontend/04_PROJECTS.md § Normalización
/// - IntegradorHub/docs/frontend/06_PUBLIC_PAGES.md § Modelo de Proyecto Público
///
/// Separado de [ProjectDetailReadModel] para optimizar el listado:
/// la lista solo necesita campos de resumen.
class ProjectReadModel extends Equatable {
  const ProjectReadModel({
    required this.id,
    required this.titulo,
    required this.materia,
    required this.estado,
    required this.stackTecnologico,
    this.liderNombre,
    this.liderId,
    this.docenteId,
    this.docenteNombre,
    this.materia_,
    this.ciclo,
    this.puntosTotales,
    this.esPublico = false,
    this.videoUrl,
    this.createdAt,
    this.grupoId,
  });

  final String id;
  final String titulo;
  final String materia;
  /// 'Activo' | 'Completado' | 'Borrador'
  final String estado;
  final List<String> stackTecnologico;
  final String? liderNombre;
  final String? liderId;
  final String? docenteId;
  final String? docenteNombre;
  final String? materia_; // alias interno
  final String? ciclo;
  final int? puntosTotales;
  final bool esPublico;
  final String? videoUrl;
  final DateTime? createdAt;
  final String? grupoId;

  // ── Computed ────────────────────────────────────────────────────────

  /// Primeras 3 tecnologías del stack para mostrar en tarjeta.
  List<String> get stackPreview => stackTecnologico.take(3).toList();

  /// Cantidad de tecnologías adicionales no mostradas en preview.
  int get stackOverflow =>
      stackTecnologico.length > 3 ? stackTecnologico.length - 3 : 0;

  /// Color semántico del badge de estado.
  /// Devuelve un identificador string para que la UI decida el color.
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

  // ── Factory desde JSON del backend .NET ─────────────────────────────

  factory ProjectReadModel.fromJson(Map<String, dynamic> json) {
    return ProjectReadModel(
      id: _str(json, ['id', 'Id']) ?? '',
      titulo: _str(json, ['titulo', 'Titulo']) ?? 'Sin título',
      materia: _str(json, ['materia', 'Materia']) ?? '',
      estado: _str(json, ['estado', 'Estado']) ?? 'Borrador',
      stackTecnologico: _strList(json, ['stackTecnologico', 'StackTecnologico']),
      liderNombre: _str(json, ['liderNombre', 'LiderNombre']),
      liderId: _str(json, ['liderId', 'LiderId']),
      docenteId: _str(json, ['docenteId', 'DocenteId']),
      docenteNombre: _str(json, ['docenteNombre', 'DocenteNombre']),
      ciclo: _str(json, ['ciclo', 'Ciclo']),
      puntosTotales: _int(json, ['puntosTotales', 'PuntosTotales']),
      esPublico: _bool(json, ['esPublico', 'EsPublico']),
      videoUrl: _str(json, ['videoUrl', 'VideoUrl']),
      createdAt: _datetime(json, ['createdAt', 'CreatedAt']),
      grupoId: _str(json, ['grupoId', 'GrupoId']),
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
        'docenteId': docenteId,
        'docenteNombre': docenteNombre,
        'ciclo': ciclo,
        'puntosTotales': puntosTotales,
        'esPublico': esPublico,
        'videoUrl': videoUrl,
        'createdAt': createdAt?.toIso8601String(),
        'grupoId': grupoId,
      };

  @override
  List<Object?> get props => [
        id, titulo, materia, estado, stackTecnologico,
        liderNombre, docenteId, puntosTotales, esPublico,
      ];
}

/// ReadModel detallado de proyecto — incluye miembros del equipo y canvas.
/// Se usa en [ProjectDetailPage] y [ProjectDetailsModal].
class ProjectDetailReadModel extends Equatable {
  const ProjectDetailReadModel({
    required this.id,
    required this.titulo,
    required this.materia,
    required this.estado,
    required this.stackTecnologico,
    required this.members,
    required this.canvasBlocks,
    this.liderId,
    this.liderNombre,
    this.docenteId,
    this.docenteNombre,
    this.ciclo,
    this.puntosTotales,
    this.esPublico = false,
    this.videoUrl,
    this.repositorioUrl,
    this.createdAt,
    this.grupoId,
    this.materiaId,
  });

  final String id;
  final String titulo;
  final String materia;
  final String estado;
  final List<String> stackTecnologico;
  final List<ProjectMemberReadModel> members;
  final List<Map<String, dynamic>> canvasBlocks;
  final String? liderId;
  final String? liderNombre;
  final String? docenteId;
  final String? docenteNombre;
  final String? ciclo;
  final int? puntosTotales;
  final bool esPublico;
  final String? videoUrl;
  final String? repositorioUrl;
  final DateTime? createdAt;
  final String? grupoId;
  final String? materiaId;

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasRepo => repositorioUrl != null && repositorioUrl!.isNotEmpty;
  int get memberCount => members.length;

  factory ProjectDetailReadModel.fromJson(Map<String, dynamic> json) {
    final raw = _normalizeKeys(json);
    return ProjectDetailReadModel(
      id: raw['id'] as String? ?? '',
      titulo: raw['titulo'] as String? ?? 'Sin título',
      materia: raw['materia'] as String? ?? '',
      estado: raw['estado'] as String? ?? 'Borrador',
      stackTecnologico: _strList(raw, ['stackTecnologico']),
      members: _parseMembers(raw['members'] ?? raw['miembros']),
      canvasBlocks: _parseBlocks(raw['canvas'] ?? raw['canvasBlocks']),
      liderId: raw['liderId'] as String?,
      liderNombre: raw['liderNombre'] as String?,
      docenteId: raw['docenteId'] as String?,
      docenteNombre: raw['docenteNombre'] as String?,
      ciclo: raw['ciclo'] as String?,
      puntosTotales: raw['puntosTotales'] as int?,
      esPublico: raw['esPublico'] as bool? ?? false,
      videoUrl: raw['videoUrl'] as String?,
      repositorioUrl: raw['repositorioUrl'] as String?,
      createdAt: _datetime(raw, ['createdAt']),
      grupoId: raw['grupoId'] as String?,
      materiaId: raw['materiaId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'materia': materia,
        'estado': estado,
        'stackTecnologico': stackTecnologico,
        'members': members.map((m) => m.toJson()).toList(),
        'canvasBlocks': canvasBlocks,
        'liderId': liderId,
        'liderNombre': liderNombre,
        'docenteId': docenteId,
        'docenteNombre': docenteNombre,
        'ciclo': ciclo,
        'puntosTotales': puntosTotales,
        'esPublico': esPublico,
        'videoUrl': videoUrl,
        'repositorioUrl': repositorioUrl,
        'createdAt': createdAt?.toIso8601String(),
        'grupoId': grupoId,
        'materiaId': materiaId,
      };

  @override
  List<Object?> get props => [id, titulo, estado, esPublico, memberCount];
}

// ── Miembro del equipo ────────────────────────────────────────────────

class ProjectMemberReadModel extends Equatable {
  const ProjectMemberReadModel({
    required this.id,
    required this.nombre,
    this.email,
    this.fotoUrl,
    this.esLider = false,
    this.matricula,
  });

  final String id;
  final String nombre;
  final String? email;
  final String? fotoUrl;
  final bool esLider;
  final String? matricula;

  String get avatarUrl {
    if (fotoUrl != null && fotoUrl!.isNotEmpty) return fotoUrl!;
    final encoded = Uri.encodeComponent(nombre);
    return 'https://ui-avatars.com/api/?name=$encoded&background=111&color=fff&size=64';
  }

  factory ProjectMemberReadModel.fromJson(Map<String, dynamic> json) {
    final raw = _normalizeKeys(json);
    return ProjectMemberReadModel(
      id: raw['id'] as String? ?? '',
      nombre: raw['nombre'] as String? ??
          raw['nombreCompleto'] as String? ?? 'Miembro',
      email: raw['email'] as String?,
      fotoUrl: raw['fotoUrl'] as String? ?? raw['photoUrl'] as String?,
      esLider: raw['esLider'] as bool? ?? false,
      matricula: raw['matricula'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'email': email,
        'fotoUrl': fotoUrl,
        'esLider': esLider,
        'matricula': matricula,
      };

  @override
  List<Object?> get props => [id, nombre, esLider];
}

// ── Helpers de normalización ──────────────────────────────────────────

/// Normaliza todas las claves del Map de PascalCase → camelCase.
Map<String, dynamic> _normalizeKeys(Map<String, dynamic> json) {
  return json.map((key, value) {
    final camelKey = key.isNotEmpty
        ? key[0].toLowerCase() + key.substring(1)
        : key;
    return MapEntry(camelKey, value);
  });
}

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

/// Parsea fechas desde Firestore Timestamp, ISO string o epoch seconds.
DateTime? _datetime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final val = json[key];
    if (val == null) continue;
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    // Firestore Timestamp: { seconds: int }
    if (val is Map && val['seconds'] is int) {
      return DateTime.fromMillisecondsSinceEpoch(
          (val['seconds'] as int) * 1000);
    }
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val * 1000);
  }
  return null;
}

List<ProjectMemberReadModel> _parseMembers(dynamic raw) {
  if (raw is! List) return [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(ProjectMemberReadModel.fromJson)
      .toList();
}

List<Map<String, dynamic>> _parseBlocks(dynamic raw) {
  if (raw is! List) return [];
  return raw.whereType<Map<String, dynamic>>().toList();
}
