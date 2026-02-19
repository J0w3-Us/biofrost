// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_carrera_command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCarreraCommand _$CreateCarreraCommandFromJson(
  Map<String, dynamic> json,
) => CreateCarreraCommand(
  nombre: json['Nombre'] as String,
  nivel: json['Nivel'] as String,
);

Map<String, dynamic> _$CreateCarreraCommandToJson(
  CreateCarreraCommand instance,
) => <String, dynamic>{'Nombre': instance.nombre, 'Nivel': instance.nivel};
