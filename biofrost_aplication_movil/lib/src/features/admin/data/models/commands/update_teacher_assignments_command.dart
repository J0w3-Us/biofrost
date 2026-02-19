import 'package:json_annotation/json_annotation.dart';

part 'update_teacher_assignments_command.g.dart';

/// [Command] — Actualizar asignaciones de docente. Solo escritura (CQRS).
/// Maps to PUT /api/admin/users/teachers/{userId} — PascalCase per .NET DTO convention.
@JsonSerializable()
class UpdateTeacherAssignmentsCommand {
  @JsonKey(name: 'Asignaciones')
  final List<AsignacionCommandItem> asignaciones;

  const UpdateTeacherAssignmentsCommand({required this.asignaciones});

  factory UpdateTeacherAssignmentsCommand.fromJson(Map<String, dynamic> json) =>
      _$UpdateTeacherAssignmentsCommandFromJson(json);

  Map<String, dynamic> toJson() =>
      _$UpdateTeacherAssignmentsCommandToJson(this);
}

@JsonSerializable()
class AsignacionCommandItem {
  @JsonKey(name: 'CarreraId')
  final String carreraId;

  @JsonKey(name: 'MateriaId')
  final String materiaId;

  @JsonKey(name: 'GruposIds')
  final List<String> gruposIds;

  const AsignacionCommandItem({
    required this.carreraId,
    required this.materiaId,
    required this.gruposIds,
  });

  factory AsignacionCommandItem.fromJson(Map<String, dynamic> json) =>
      _$AsignacionCommandItemFromJson(json);

  Map<String, dynamic> toJson() => _$AsignacionCommandItemToJson(this);
}
