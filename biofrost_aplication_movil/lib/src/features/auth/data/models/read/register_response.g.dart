// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterResponse _$RegisterResponseFromJson(Map<String, dynamic> json) =>
    RegisterResponse(
      success: json['Success'] as bool? ?? false,
      message: json['Message'] as String? ?? '',
      userId: json['UserId'] as String?,
      uid: json['Uid'] as String?,
      email: json['Email'] as String?,
      nombre: json['Nombre'] as String?,
      apellidoPaterno: json['ApellidoPaterno'] as String?,
      apellidoMaterno: json['ApellidoMaterno'] as String?,
      rol: json['Rol'] as String?,
      isFirstLogin: json['IsFirstLogin'] as bool? ?? false,
      grupoId: json['GrupoId'] as String?,
      matricula: json['Matricula'] as String?,
      carreraId: json['CarreraId'] as String?,
      fotoUrl: json['FotoUrl'] as String?,
    );

Map<String, dynamic> _$RegisterResponseToJson(RegisterResponse instance) =>
    <String, dynamic>{
      'Success': instance.success,
      'Message': instance.message,
      'UserId': instance.userId,
      'Uid': instance.uid,
      'Email': instance.email,
      'Nombre': instance.nombre,
      'ApellidoPaterno': instance.apellidoPaterno,
      'ApellidoMaterno': instance.apellidoMaterno,
      'Rol': instance.rol,
      'IsFirstLogin': instance.isFirstLogin,
      'GrupoId': instance.grupoId,
      'Matricula': instance.matricula,
      'CarreraId': instance.carreraId,
      'FotoUrl': instance.fotoUrl,
    };
