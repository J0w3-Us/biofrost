// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginCommand _$LoginCommandFromJson(Map<String, dynamic> json) => LoginCommand(
  firebaseUid: json['FirebaseUid'] as String,
  email: json['Email'] as String,
  displayName: json['DisplayName'] as String?,
  photoUrl: json['PhotoUrl'] as String?,
);

Map<String, dynamic> _$LoginCommandToJson(LoginCommand instance) =>
    <String, dynamic>{
      'FirebaseUid': instance.firebaseUid,
      'Email': instance.email,
      'DisplayName': ?instance.displayName,
      'PhotoUrl': ?instance.photoUrl,
    };
