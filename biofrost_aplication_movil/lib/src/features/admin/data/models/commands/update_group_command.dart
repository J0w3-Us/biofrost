import 'package:json_annotation/json_annotation.dart';

part 'update_group_command.g.dart';

/// [Command] — Actualizar grupo existente. Solo escritura (CQRS).
/// Maps to PUT /api/admin/groups/{id} — PascalCase per .NET DTO convention.
@JsonSerializable()
class UpdateGroupCommand {
  @JsonKey(name: 'Nombre')
  final String nombre;

  @JsonKey(name: 'Carrera')
  final String carrera;

  @JsonKey(name: 'Turno')
  final String turno;

  @JsonKey(name: 'CicloActivo')
  final String cicloActivo;

  const UpdateGroupCommand({
    required this.nombre,
    required this.carrera,
    required this.turno,
    required this.cicloActivo,
  });

  factory UpdateGroupCommand.fromJson(Map<String, dynamic> json) =>
      _$UpdateGroupCommandFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateGroupCommandToJson(this);
}
