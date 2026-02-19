// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_group_command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateGroupCommand _$CreateGroupCommandFromJson(Map<String, dynamic> json) =>
    CreateGroupCommand(
      nombre: json['Nombre'] as String,
      carrera: json['Carrera'] as String,
      turno: json['Turno'] as String,
      cicloActivo: json['CicloActivo'] as String,
    );

Map<String, dynamic> _$CreateGroupCommandToJson(CreateGroupCommand instance) =>
    <String, dynamic>{
      'Nombre': instance.nombre,
      'Carrera': instance.carrera,
      'Turno': instance.turno,
      'CicloActivo': instance.cicloActivo,
    };
