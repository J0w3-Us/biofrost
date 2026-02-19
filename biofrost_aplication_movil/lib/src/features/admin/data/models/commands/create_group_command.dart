import 'package:json_annotation/json_annotation.dart';

part 'create_group_command.g.dart';

/// [Command] — Crear grupo. Solo escritura; no reutilizar como ReadModel (CQRS).
/// Maps to POST /api/admin/groups — PascalCase per .NET DTO convention.
@JsonSerializable()
class CreateGroupCommand {
  @JsonKey(name: 'Nombre')
  final String nombre;

  @JsonKey(name: 'Carrera')
  final String carrera;

  @JsonKey(name: 'Turno')
  final String turno;

  @JsonKey(name: 'CicloActivo')
  final String cicloActivo;

  const CreateGroupCommand({
    required this.nombre,
    required this.carrera,
    required this.turno,
    required this.cicloActivo,
  });

  factory CreateGroupCommand.fromJson(Map<String, dynamic> json) =>
      _$CreateGroupCommandFromJson(json);

  Map<String, dynamic> toJson() => _$CreateGroupCommandToJson(this);
}
