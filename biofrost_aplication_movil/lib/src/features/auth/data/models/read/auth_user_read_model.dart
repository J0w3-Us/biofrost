import 'package:json_annotation/json_annotation.dart';

import '../../../../../core/core.dart';

part 'auth_user_read_model.g.dart';

/// [ReadModel] Respuesta del backend para login y register.
///
/// El backend .NET retorna campos en PascalCase. [toAppUser] convierte
/// a la entidad de sesión persistida en SecureStorage.
@JsonSerializable()
class AuthUserReadModel {
  const AuthUserReadModel({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.rol,
    this.grupoId,
    this.carreraId,
    this.matricula,
    this.fotoUrl,
    this.isFirstLogin = false,
  });

  @JsonKey(name: 'Uid', defaultValue: '')
  final String uid;

  @JsonKey(name: 'Email', defaultValue: '')
  final String email;

  @JsonKey(name: 'Nombre', defaultValue: '')
  final String nombre;

  @JsonKey(name: 'ApellidoPaterno', defaultValue: '')
  final String apellidoPaterno;

  @JsonKey(name: 'ApellidoMaterno', defaultValue: '')
  final String apellidoMaterno;

  /// `Alumno` | `Docente` | `Admin` | `Invitado`
  @JsonKey(name: 'Rol', defaultValue: 'Invitado')
  final String rol;

  @JsonKey(name: 'GrupoId')
  final String? grupoId;

  @JsonKey(name: 'CarreraId')
  final String? carreraId;

  @JsonKey(name: 'Matricula')
  final String? matricula;

  @JsonKey(name: 'FotoUrl')
  final String? fotoUrl;

  /// Si `true`, el usuario nunca ha completado su perfil (RN-302).
  @JsonKey(name: 'IsFirstLogin', defaultValue: false)
  final bool isFirstLogin;

  factory AuthUserReadModel.fromJson(Map<String, dynamic> json) =>
      _$AuthUserReadModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthUserReadModelToJson(this);

  /// Convierte al modelo de sesión persistido en SecureStorage.
  AppUser toAppUser() => AppUser(
    uid: uid,
    email: email,
    nombre: nombre,
    apellidoPaterno: apellidoPaterno,
    apellidoMaterno: apellidoMaterno,
    rol: rol,
    grupoId: grupoId,
    carreraId: carreraId,
    matricula: matricula,
    fotoUrl: fotoUrl,
    isFirstLogin: isFirstLogin,
  );
}
