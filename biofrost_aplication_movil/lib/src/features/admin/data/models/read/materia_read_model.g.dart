// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'materia_read_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MateriaReadModel _$MateriaReadModelFromJson(Map<String, dynamic> json) =>
    MateriaReadModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      clave: json['clave'] as String,
      carreraId: json['carreraId'] as String,
      cuatrimestre: (json['cuatrimestre'] as num).toInt(),
      esAltaPrioridad: json['esAltaPrioridad'] as bool,
      activo: json['activo'] as bool,
    );

Map<String, dynamic> _$MateriaReadModelToJson(MateriaReadModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'clave': instance.clave,
      'carreraId': instance.carreraId,
      'cuatrimestre': instance.cuatrimestre,
      'esAltaPrioridad': instance.esAltaPrioridad,
      'activo': instance.activo,
    };
