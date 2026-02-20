import 'package:json_annotation/json_annotation.dart';

import '../../../../../core/core.dart';

part 'register_response.g.dart';

/// [ReadModel] Respuesta del backend para el endpoint de registro.
///
/// El backend retorna tanto el status del registro como el perfil completo
/// del usuario para mantener consistencia con el flow de login.
@JsonSerializable()
class RegisterResponse {
  const RegisterResponse({
    required this.success,
    required this.message,
    this.userId,
    this.uid,
    this.email,
    this.nombre,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.rol,
    this.isFirstLogin = false,
    this.grupoId,
    this.matricula,
    this.carreraId,
    this.fotoUrl,
  });

  /// Indica si el registro fue exitoso
  @JsonKey(name: 'Success', defaultValue: false)
  final bool success;

  /// Mensaje descriptivo del resultado del registro
  @JsonKey(name: 'Message', defaultValue: '')
  final String message;

  /// ID del usuario creado (puede ser null si falló)
  @JsonKey(name: 'UserId')
  final String? userId;

  // ── Perfil completo del usuario (mismo contrato que LoginResponse) ──

  @JsonKey(name: 'Uid')
  final String? uid;

  @JsonKey(name: 'Email')
  final String? email;

  @JsonKey(name: 'Nombre')
  final String? nombre;

  @JsonKey(name: 'ApellidoPaterno')
  final String? apellidoPaterno;

  @JsonKey(name: 'ApellidoMaterno')
  final String? apellidoMaterno;

  /// `Alumno` | `Docente` | `Admin` | `Invitado`
  @JsonKey(name: 'Rol')
  final String? rol;

  /// Si `true`, el usuario nunca ha completado su perfil
  @JsonKey(name: 'IsFirstLogin', defaultValue: false)
  final bool isFirstLogin;

  @JsonKey(name: 'GrupoId')
  final String? grupoId;

  @JsonKey(name: 'Matricula')
  final String? matricula;

  @JsonKey(name: 'CarreraId')
  final String? carreraId;

  @JsonKey(name: 'FotoUrl')
  final String? fotoUrl;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterResponseToJson(this);

  /// Convierte al modelo de sesión si el registro fue exitoso.
  /// Retorna null si el registro falló.
  AppUser? toAppUser() {
    if (!success || uid == null || email == null || nombre == null) {
      return null;
    }

    return AppUser(
      uid: uid!,
      email: email!,
      nombre: nombre!,
      apellidoPaterno: apellidoPaterno ?? '',
      apellidoMaterno: apellidoMaterno ?? '',
      rol: rol ?? 'Invitado',
      grupoId: grupoId,
      carreraId: carreraId,
      matricula: matricula,
      fotoUrl: fotoUrl,
      isFirstLogin: isFirstLogin,
    );
  }
}
