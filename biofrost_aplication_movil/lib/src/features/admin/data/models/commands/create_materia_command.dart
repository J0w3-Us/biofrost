import 'package:json_annotation/json_annotation.dart';

part 'create_materia_command.g.dart';

/// [Command] — Crear materia. Solo escritura (CQRS).
/// Maps to POST /api/admin/materias — PascalCase per .NET DTO convention.
@JsonSerializable()
class CreateMateriaCommand {
  @JsonKey(name: 'Nombre')
  final String nombre;

  @JsonKey(name: 'Clave')
  final String clave;

  @JsonKey(name: 'CarreraId')
  final String carreraId;

  @JsonKey(name: 'Cuatrimestre')
  final int cuatrimestre;

  @JsonKey(name: 'EsAltaPrioridad')
  final bool esAltaPrioridad;

  const CreateMateriaCommand({
    required this.nombre,
    required this.clave,
    required this.carreraId,
    required this.cuatrimestre,
    this.esAltaPrioridad = false,
  });

  factory CreateMateriaCommand.fromJson(Map<String, dynamic> json) =>
      _$CreateMateriaCommandFromJson(json);

  Map<String, dynamic> toJson() => _$CreateMateriaCommandToJson(this);
}
