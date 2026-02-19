// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_materia_command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateMateriaCommand _$CreateMateriaCommandFromJson(
  Map<String, dynamic> json,
) => CreateMateriaCommand(
  nombre: json['Nombre'] as String,
  clave: json['Clave'] as String,
  carreraId: json['CarreraId'] as String,
  cuatrimestre: (json['Cuatrimestre'] as num).toInt(),
  esAltaPrioridad: json['EsAltaPrioridad'] as bool? ?? false,
);

Map<String, dynamic> _$CreateMateriaCommandToJson(
  CreateMateriaCommand instance,
) => <String, dynamic>{
  'Nombre': instance.nombre,
  'Clave': instance.clave,
  'CarreraId': instance.carreraId,
  'Cuatrimestre': instance.cuatrimestre,
  'EsAltaPrioridad': instance.esAltaPrioridad,
};
