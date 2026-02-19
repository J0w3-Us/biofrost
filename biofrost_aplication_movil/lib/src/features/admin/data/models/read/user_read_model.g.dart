// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_read_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserReadModel _$UserReadModelFromJson(Map<String, dynamic> json) =>
    UserReadModel(
      id: json['id'] as String,
      uid: json['uid'] as String,
      nombre: json['nombre'] as String,
      apellidoPaterno: json['apellidoPaterno'] as String,
      apellidoMaterno: json['apellidoMaterno'] as String,
      email: json['email'] as String,
      rol: json['rol'] as String,
      matricula: json['matricula'] as String?,
      grupoId: json['grupoId'] as String?,
      carreraId: json['carreraId'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
      asignaciones: (json['asignaciones'] as List<dynamic>?)
          ?.map(
            (e) =>
                DocenteAsignacionReadModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$UserReadModelToJson(UserReadModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uid': instance.uid,
      'nombre': instance.nombre,
      'apellidoPaterno': instance.apellidoPaterno,
      'apellidoMaterno': instance.apellidoMaterno,
      'email': instance.email,
      'rol': instance.rol,
      'matricula': instance.matricula,
      'grupoId': instance.grupoId,
      'carreraId': instance.carreraId,
      'fotoUrl': instance.fotoUrl,
      'asignaciones': instance.asignaciones,
    };

DocenteAsignacionReadModel _$DocenteAsignacionReadModelFromJson(
  Map<String, dynamic> json,
) => DocenteAsignacionReadModel(
  carreraId: json['carreraId'] as String,
  materiaId: json['materiaId'] as String,
  gruposIds: (json['gruposIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$DocenteAsignacionReadModelToJson(
  DocenteAsignacionReadModel instance,
) => <String, dynamic>{
  'carreraId': instance.carreraId,
  'materiaId': instance.materiaId,
  'gruposIds': instance.gruposIds,
};
