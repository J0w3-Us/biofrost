// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_group_command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateGroupCommand _$UpdateGroupCommandFromJson(Map<String, dynamic> json) =>
    UpdateGroupCommand(
      nombre: json['Nombre'] as String,
      carrera: json['Carrera'] as String,
      turno: json['Turno'] as String,
      cicloActivo: json['CicloActivo'] as String,
    );

Map<String, dynamic> _$UpdateGroupCommandToJson(UpdateGroupCommand instance) =>
    <String, dynamic>{
      'Nombre': instance.nombre,
      'Carrera': instance.carrera,
      'Turno': instance.turno,
      'CicloActivo': instance.cicloActivo,
    };
