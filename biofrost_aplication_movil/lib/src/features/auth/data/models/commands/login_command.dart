import 'package:json_annotation/json_annotation.dart';

part 'login_command.g.dart';

/// [Command] Payload para POST /api/auth/login.
///
/// Intercambia credenciales de Firebase por el perfil de usuario del backend.
/// Endpoint público — no requiere Authorization header.
@JsonSerializable(includeIfNull: false)
class LoginCommand {
  const LoginCommand({
    required this.firebaseUid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  /// UID asignado por Firebase Authentication.
  @JsonKey(name: 'FirebaseUid')
  final String firebaseUid;

  @JsonKey(name: 'Email')
  final String email;

  @JsonKey(name: 'DisplayName')
  final String? displayName;

  @JsonKey(name: 'PhotoUrl')
  final String? photoUrl;

  factory LoginCommand.fromJson(Map<String, dynamic> json) =>
      _$LoginCommandFromJson(json);

  Map<String, dynamic> toJson() => _$LoginCommandToJson(this);
}
