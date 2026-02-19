import 'package:json_annotation/json_annotation.dart';

part 'update_student_group_command.g.dart';

/// [Command] — Actualizar grupo de un alumno. Solo escritura (CQRS).
/// Maps to PUT /api/admin/users/students/{userId} — PascalCase per .NET DTO convention.
@JsonSerializable()
class UpdateStudentGroupCommand {
  @JsonKey(name: 'GrupoId')
  final String grupoId;

  const UpdateStudentGroupCommand({required this.grupoId});

  factory UpdateStudentGroupCommand.fromJson(Map<String, dynamic> json) =>
      _$UpdateStudentGroupCommandFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateStudentGroupCommandToJson(this);
}
