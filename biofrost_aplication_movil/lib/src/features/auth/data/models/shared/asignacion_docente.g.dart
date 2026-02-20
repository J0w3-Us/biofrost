// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asignacion_docente.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AsignacionDocente _$AsignacionDocenteFromJson(Map<String, dynamic> json) =>
    AsignacionDocente(
      carreraId: json['CarreraId'] as String,
      materiaId: json['MateriaId'] as String,
      gruposIds: (json['GruposIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AsignacionDocenteToJson(AsignacionDocente instance) =>
    <String, dynamic>{
      'CarreraId': instance.carreraId,
      'MateriaId': instance.materiaId,
      'GruposIds': instance.gruposIds,
    };
