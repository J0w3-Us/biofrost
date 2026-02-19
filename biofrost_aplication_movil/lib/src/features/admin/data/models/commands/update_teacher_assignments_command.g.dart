// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_teacher_assignments_command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateTeacherAssignmentsCommand _$UpdateTeacherAssignmentsCommandFromJson(
  Map<String, dynamic> json,
) => UpdateTeacherAssignmentsCommand(
  asignaciones: (json['Asignaciones'] as List<dynamic>)
      .map((e) => AsignacionCommandItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UpdateTeacherAssignmentsCommandToJson(
  UpdateTeacherAssignmentsCommand instance,
) => <String, dynamic>{'Asignaciones': instance.asignaciones};

AsignacionCommandItem _$AsignacionCommandItemFromJson(
  Map<String, dynamic> json,
) => AsignacionCommandItem(
  carreraId: json['CarreraId'] as String,
  materiaId: json['MateriaId'] as String,
  gruposIds: (json['GruposIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$AsignacionCommandItemToJson(
  AsignacionCommandItem instance,
) => <String, dynamic>{
  'CarreraId': instance.carreraId,
  'MateriaId': instance.materiaId,
  'GruposIds': instance.gruposIds,
};
