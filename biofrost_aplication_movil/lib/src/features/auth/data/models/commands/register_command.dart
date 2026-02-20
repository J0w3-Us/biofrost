import 'package:json_annotation/json_annotation.dart';

import '../shared/asignacion_docente.dart';

part 'register_command.g.dart';

/// [Command] Payload para POST /api/auth/register.
///
/// Registro con datos extendidos diferenciado por rol (RN-301).
/// - Alumno: requiere grupoId, carreraId, matricula.
/// - Docente: requiere profesion, gruposDocente, carrerasIds.
/// - Invitado: requiere organizacion (opcional).
@JsonSerializable(includeIfNull: false)
class RegisterCommand {
  const RegisterCommand({
    required this.firebaseUid,
    required this.email,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.rol,
    this.grupoId,
    this.matricula,
    this.carreraId,
    this.profesion,
    this.organizacion,
    this.asignaciones = const [],
    this.gruposDocente = const [],
    this.carrerasIds = const [],
  });

  @JsonKey(name: 'FirebaseUid')
  final String firebaseUid;

  @JsonKey(name: 'Email')
  final String email;

  @JsonKey(name: 'Nombre')
  final String nombre;

  @JsonKey(name: 'ApellidoPaterno')
  final String apellidoPaterno;

  @JsonKey(name: 'ApellidoMaterno')
  final String apellidoMaterno;

  /// `Alumno` | `Docente` | `Admin` | `Invitado`
  @JsonKey(name: 'Rol')
  final String rol;

  /// Solo Alumno.
  @JsonKey(name: 'GrupoId')
  final String? grupoId;

  /// Solo Alumno — auto-extraída del correo institucional.
  @JsonKey(name: 'Matricula')
  final String? matricula;

  /// Solo Alumno.
  @JsonKey(name: 'CarreraId')
  final String? carreraId;

  /// Solo Docente.
  @JsonKey(name: 'Profesion')
  final String? profesion;

  /// Solo Invitado.
  @JsonKey(name: 'Organizacion')
  final String? organizacion;

  /// Asignaciones completas de materias (Docente). Vacío para otros roles.
  @JsonKey(name: 'Asignaciones', defaultValue: [])
  final List<AsignacionDocente> asignaciones;

  /// Grupos asignados al docente (usado para construir asignaciones).
  @JsonKey(name: 'GruposDocente', defaultValue: [])
  final List<String> gruposDocente;

  /// Carreras del docente (usado para construir asignaciones).
  @JsonKey(name: 'CarrerasIds', defaultValue: [])
  final List<String> carrerasIds;

  factory RegisterCommand.fromJson(Map<String, dynamic> json) =>
      _$RegisterCommandFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterCommandToJson(this);
}
