import 'package:json_annotation/json_annotation.dart';

part 'user_read_model.g.dart';

/// ReadModel optimizado para UI. Solo lectura — no reutilizar para escritura (CQRS).
///
/// Cubre tanto alumnos como docentes. El campo [rol] diferencia el tipo.
/// Campo [asignaciones] solo aplica para docentes (nullable).
@JsonSerializable()
class UserReadModel {
  final String id;
  final String uid;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String email;
  final String rol;
  final String? matricula;
  final String? grupoId;
  final String? carreraId;
  final String? fotoUrl;
  final List<DocenteAsignacionReadModel>? asignaciones;

  const UserReadModel({
    required this.id,
    required this.uid,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.email,
    required this.rol,
    this.matricula,
    this.grupoId,
    this.carreraId,
    this.fotoUrl,
    this.asignaciones,
  });

  String get nombreCompleto => '$nombre $apellidoPaterno $apellidoMaterno';

  factory UserReadModel.fromJson(Map<String, dynamic> json) =>
      _$UserReadModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserReadModelToJson(this);
}

@JsonSerializable()
class DocenteAsignacionReadModel {
  final String carreraId;
  final String materiaId;
  final List<String> gruposIds;

  const DocenteAsignacionReadModel({
    required this.carreraId,
    required this.materiaId,
    required this.gruposIds,
  });

  factory DocenteAsignacionReadModel.fromJson(Map<String, dynamic> json) =>
      _$DocenteAsignacionReadModelFromJson(json);

  Map<String, dynamic> toJson() => _$DocenteAsignacionReadModelToJson(this);
}
