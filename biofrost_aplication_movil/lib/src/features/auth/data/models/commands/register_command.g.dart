// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterCommand _$RegisterCommandFromJson(Map<String, dynamic> json) =>
    RegisterCommand(
      firebaseUid: json['FirebaseUid'] as String,
      email: json['Email'] as String,
      nombre: json['Nombre'] as String,
      apellidoPaterno: json['ApellidoPaterno'] as String,
      apellidoMaterno: json['ApellidoMaterno'] as String,
      rol: json['Rol'] as String,
      grupoId: json['GrupoId'] as String?,
      matricula: json['Matricula'] as String?,
      carreraId: json['CarreraId'] as String?,
      profesion: json['Profesion'] as String?,
      organizacion: json['Organizacion'] as String?,
      asignaciones:
          (json['Asignaciones'] as List<dynamic>?)
              ?.map(
                (e) => AsignacionDocente.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      gruposDocente:
          (json['GruposDocente'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      carrerasIds:
          (json['CarrerasIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$RegisterCommandToJson(RegisterCommand instance) =>
    <String, dynamic>{
      'FirebaseUid': instance.firebaseUid,
      'Email': instance.email,
      'Nombre': instance.nombre,
      'ApellidoPaterno': instance.apellidoPaterno,
      'ApellidoMaterno': instance.apellidoMaterno,
      'Rol': instance.rol,
      'GrupoId': ?instance.grupoId,
      'Matricula': ?instance.matricula,
      'CarreraId': ?instance.carreraId,
      'Profesion': ?instance.profesion,
      'Organizacion': ?instance.organizacion,
      'Asignaciones': instance.asignaciones,
      'GruposDocente': instance.gruposDocente,
      'CarrerasIds': instance.carrerasIds,
    };
