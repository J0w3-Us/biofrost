import 'package:json_annotation/json_annotation.dart';

part 'create_carrera_command.g.dart';

/// [Command] — Crear carrera. Solo escritura (CQRS).
/// Maps to POST /api/admin/carreras — PascalCase per .NET DTO convention.
@JsonSerializable()
class CreateCarreraCommand {
  @JsonKey(name: 'Nombre')
  final String nombre;

  @JsonKey(name: 'Nivel')
  final String nivel;

  const CreateCarreraCommand({required this.nombre, required this.nivel});

  factory CreateCarreraCommand.fromJson(Map<String, dynamic> json) =>
      _$CreateCarreraCommandFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCarreraCommandToJson(this);
}
