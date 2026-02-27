import 'package:equatable/equatable.dart';

/// ReadModel detallado de proyecto — incluye miembros del equipo y canvas.
/// Se usa en [ProjectDetailPage] y como respuesta de [ProjectDetailRemoteDatasource].
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
    this.conteoVotos,
    this.votantes,
    this.esPublico = false,
    this.videoUrl,
    this.videoFilePath,
    this.repositorioUrl,
    this.createdAt,
    this.grupoId,
    this.materiaId,
    this.thumbnailUrl,
    this.descripcion,
    this.demoUrl,
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
  final int? conteoVotos;

  /// Mapa userId → stars del detalle. Fijado por el backend.
  final Map<String, int>? votantes;
  final bool esPublico;
  final String? videoUrl;
  final String? videoFilePath;
  final String? repositorioUrl;
  final DateTime? createdAt;
  final String? grupoId;
  final String? materiaId;
  final String? thumbnailUrl;
  final String? descripcion;
  final String? demoUrl;

  // ── Computed ───────────────────────────────────────────────────────

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasRepo => repositorioUrl != null && repositorioUrl!.isNotEmpty;
  bool get hasThumbnail => thumbnailUrl != null && thumbnailUrl!.isNotEmpty;
  int get memberCount => members.length;

  double get starAverage {
    if (votantes == null || votantes!.isEmpty) return 0.0;
    final sum = votantes!.values.fold<int>(0, (a, b) => a + b);
    return sum / votantes!.length;
  }

  int? userStars(String userId) => votantes?[userId];

  // ── Factory ────────────────────────────────────────────────────────

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
      puntosTotales: _int(raw, ['puntosTotales']),
      conteoVotos: _int(raw, ['conteoVotos']),
      votantes: _votantesMap(raw, ['votantes']),
      esPublico: raw['esPublico'] as bool? ?? false,
      videoUrl: raw['videoUrl'] as String?,
      videoFilePath: raw['videoFilePath'] as String?,
      repositorioUrl: raw['repositorioUrl'] as String?,
      createdAt: _datetime(raw, ['createdAt']),
      grupoId: raw['grupoId'] as String?,
      materiaId: raw['materiaId'] as String?,
      thumbnailUrl: raw['thumbnailUrl'] as String?,
      descripcion: raw['descripcion'] as String?,
      demoUrl: raw['demoUrl'] as String?,
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
        'conteoVotos': conteoVotos,
        'votantes': votantes,
        'esPublico': esPublico,
        'videoUrl': videoUrl,
        'videoFilePath': videoFilePath,
        'repositorioUrl': repositorioUrl,
        'createdAt': createdAt?.toIso8601String(),
        'grupoId': grupoId,
        'materiaId': materiaId,
        'thumbnailUrl': thumbnailUrl,
        'descripcion': descripcion,
        'demoUrl': demoUrl,
      };

  @override
  List<Object?> get props => [id, titulo, estado, esPublico, memberCount];
}

// ── Miembro del equipo ─────────────────────────────────────────────────

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
          raw['nombreCompleto'] as String? ??
          'Miembro',
      email: raw['email'] as String?,
      fotoUrl: raw['fotoUrl'] as String? ?? raw['photoUrl'] as String?,
      esLider: raw['esLider'] as bool? ?? (raw['rol'] as String?) == 'Líder',
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

// ── Helpers ────────────────────────────────────────────────────────────

Map<String, dynamic> _normalizeKeys(Map<String, dynamic> json) {
  return json.map((key, value) {
    final camelKey =
        key.isNotEmpty ? key[0].toLowerCase() + key.substring(1) : key;
    return MapEntry(camelKey, value);
  });
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

List<ProjectMemberReadModel> _parseMembers(dynamic raw) {
  if (raw is! List) return [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(ProjectMemberReadModel.fromJson)
      .toList();
}

List<Map<String, dynamic>> _parseBlocks(dynamic raw) {
  if (raw is! List) return [];
  return raw.whereType<Map<String, dynamic>>().map(_normalizeKeys).toList();
}
