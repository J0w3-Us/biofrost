// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_read_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupReadModel _$GroupReadModelFromJson(Map<String, dynamic> json) =>
    GroupReadModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      carrera: json['carrera'] as String,
      turno: json['turno'] as String,
      cicloActivo: json['cicloActivo'] as String,
      activo: json['activo'] as bool,
    );

Map<String, dynamic> _$GroupReadModelToJson(GroupReadModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'carrera': instance.carrera,
      'turno': instance.turno,
      'cicloActivo': instance.cicloActivo,
      'activo': instance.activo,
    };
