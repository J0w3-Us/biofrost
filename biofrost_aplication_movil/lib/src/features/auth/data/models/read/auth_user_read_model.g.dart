// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_user_read_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthUserReadModel _$AuthUserReadModelFromJson(Map<String, dynamic> json) =>
    AuthUserReadModel(
      uid: json['Uid'] as String? ?? '',
      email: json['Email'] as String? ?? '',
      nombre: json['Nombre'] as String? ?? '',
      apellidoPaterno: json['ApellidoPaterno'] as String? ?? '',
      apellidoMaterno: json['ApellidoMaterno'] as String? ?? '',
      rol: json['Rol'] as String? ?? 'Invitado',
      grupoId: json['GrupoId'] as String?,
      carreraId: json['CarreraId'] as String?,
      matricula: json['Matricula'] as String?,
      fotoUrl: json['FotoUrl'] as String?,
      isFirstLogin: json['IsFirstLogin'] as bool? ?? false,
    );

Map<String, dynamic> _$AuthUserReadModelToJson(AuthUserReadModel instance) =>
    <String, dynamic>{
      'Uid': instance.uid,
      'Email': instance.email,
      'Nombre': instance.nombre,
      'ApellidoPaterno': instance.apellidoPaterno,
      'ApellidoMaterno': instance.apellidoMaterno,
      'Rol': instance.rol,
      'GrupoId': instance.grupoId,
      'CarreraId': instance.carreraId,
      'Matricula': instance.matricula,
      'FotoUrl': instance.fotoUrl,
      'IsFirstLogin': instance.isFirstLogin,
    };
