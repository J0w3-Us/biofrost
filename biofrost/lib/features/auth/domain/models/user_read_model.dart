import 'package:equatable/equatable.dart';

/// ReadModel del usuario — optimizado para UI (CQRS Query).
///
/// Mapea el DTO del backend .NET (PascalCase) a Dart (camelCase).
/// Solo contiene campos de lectura; nunca se usa para operaciones de escritura.
class UserReadModel extends Equatable {
  const UserReadModel({
    required this.userId,
    required this.email,
    required this.nombre,
    required this.rol,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.fotoUrl,
    this.grupoId,
    this.carreraId,
    this.matricula,
    this.cedula,
    this.especialidadDocente,
    this.profesion,
    this.organizacion,
    this.asignaciones,
  });

  // ── Campos comunes a todos los roles ──────────────────────────────
  final String userId; // Firebase UID
  final String email;
  final String nombre;

  /// 'Docente' | 'Alumno' | 'admin' | 'SuperAdmin' | 'Invitado'
  final String rol;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? fotoUrl;

  // ── Solo Alumno ────────────────────────────────────────────────────
  final String? grupoId;
  final String? carreraId;
  final String? matricula;

  // ── Solo Docente ───────────────────────────────────────────────────
  final String? cedula;
  final String? especialidadDocente;
  final String? profesion;

  /// Lista de asignaciones: [{ carreraId, materiaId, gruposIds: [] }]
  final List<Map<String, dynamic>>? asignaciones;

  // ── Solo Visitante ─────────────────────────────────────────────────
  final String? organizacion;

  // ── Computed ───────────────────────────────────────────────────────

  String get nombreCompleto {
    final partes = [nombre, apellidoPaterno, apellidoMaterno]
        .where((p) => p != null && p.isNotEmpty)
        .join(' ');
    return partes.isNotEmpty ? partes : nombre;
  }

  bool get isDocente => rol == 'Docente';
  bool get isVisitante => rol == 'Invitado';
  bool get isAdmin => rol == 'admin' || rol == 'SuperAdmin';

  String get avatarUrl {
    if (fotoUrl != null && fotoUrl!.isNotEmpty) return fotoUrl!;
    final encoded = Uri.encodeComponent(nombreCompleto);
    return 'https://ui-avatars.com/api/?name=$encoded&background=111&color=fff&size=128';
  }

  // ── Factory: desde JSON del backend .NET ──────────────────────────

  factory UserReadModel.fromJson(Map<String, dynamic> json) {
    return UserReadModel(
      userId: _str(json, ['userId', 'UserId', 'uid', 'Uid']) ?? '',
      email: _str(json, ['email', 'Email']) ?? '',
      nombre: _str(json, ['nombre', 'Nombre', 'displayName']) ?? 'Usuario',
      rol: _str(json, ['rol', 'Rol', 'role']) ?? 'Invitado',
      apellidoPaterno: _str(json, ['apellidoPaterno', 'ApellidoPaterno']),
      apellidoMaterno: _str(json, ['apellidoMaterno', 'ApellidoMaterno']),
      fotoUrl: _str(json, ['fotoUrl', 'FotoUrl', 'photoURL', 'PhotoURL']),
      grupoId: _str(json, ['grupoId', 'GrupoId']),
      carreraId: _str(json, ['carreraId', 'CarreraId']),
      matricula: _str(json, ['matricula', 'Matricula']),
      cedula: _str(json, ['cedula', 'Cedula']),
      especialidadDocente:
          _str(json, ['especialidadDocente', 'EspecialidadDocente']),
      profesion: _str(json, ['profesion', 'Profesion']),
      organizacion: _str(json, ['organizacion', 'Organizacion']),
      asignaciones: (json['asignaciones'] ?? json['Asignaciones'])
          as List<Map<String, dynamic>>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'nombre': nombre,
        'rol': rol,
        'apellidoPaterno': apellidoPaterno,
        'apellidoMaterno': apellidoMaterno,
        'fotoUrl': fotoUrl,
        'grupoId': grupoId,
        'carreraId': carreraId,
        'matricula': matricula,
        'cedula': cedula,
        'especialidadDocente': especialidadDocente,
        'profesion': profesion,
        'organizacion': organizacion,
      };

  @override
  List<Object?> get props => [
        userId,
        email,
        nombre,
        rol,
        fotoUrl,
        grupoId,
        carreraId,
        matricula,
        cedula,
        especialidadDocente,
        profesion,
        organizacion,
      ];

  UserReadModel copyWith({
    String? nombre,
    String? fotoUrl,
    String? grupoId,
    String? organizacion,
  }) {
    return UserReadModel(
      userId: userId,
      email: email,
      nombre: nombre ?? this.nombre,
      rol: rol,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      grupoId: grupoId ?? this.grupoId,
      carreraId: carreraId,
      matricula: matricula,
      cedula: cedula,
      especialidadDocente: especialidadDocente,
      profesion: profesion,
      organizacion: organizacion ?? this.organizacion,
      asignaciones: asignaciones,
    );
  }
}

// ── Helpers de normalización PascalCase/camelCase ─────────────────────

String? _str(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final val = json[key];
    if (val is String && val.isNotEmpty) return val;
  }
  return null;
}
