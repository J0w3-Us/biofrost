import 'dart:convert';

/// Modelo inmutable del usuario autenticado en sesión.
///
/// Mapeado desde los campos del backend .NET (PascalCase → camelCase).
/// Almacenado serializado en SecureStorage.
class AppUser {
  const AppUser({
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

  final String uid;
  final String email;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;

  /// Rol del usuario: `Alumno` | `Docente` | `Admin` | `Invitado`
  final String rol;

  final String? grupoId;
  final String? carreraId;
  final String? matricula;
  final String? fotoUrl;
  final bool isFirstLogin;

  String get nombreCompleto => '$nombre $apellidoPaterno $apellidoMaterno';

  bool get isAdmin => rol == 'Admin';
  bool get isDocente => rol == 'Docente';
  bool get isAlumno => rol == 'Alumno';
  bool get isInvitado => rol == 'Invitado';

  // -------------------------------------------------------------------------
  // Serialización — PascalCase para compat. con .NET DTO
  // -------------------------------------------------------------------------

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: (json['Uid'] ?? json['uid'] ?? '') as String,
      email: (json['Email'] ?? json['email'] ?? '') as String,
      nombre: (json['Nombre'] ?? json['nombre'] ?? '') as String,
      apellidoPaterno:
          (json['ApellidoPaterno'] ?? json['apellidoPaterno'] ?? '') as String,
      apellidoMaterno:
          (json['ApellidoMaterno'] ?? json['apellidoMaterno'] ?? '') as String,
      rol: (json['Rol'] ?? json['rol'] ?? 'Invitado') as String,
      grupoId: (json['GrupoId'] ?? json['grupoId']) as String?,
      carreraId: (json['CarreraId'] ?? json['carreraId']) as String?,
      matricula: (json['Matricula'] ?? json['matricula']) as String?,
      fotoUrl: (json['FotoUrl'] ?? json['fotoUrl']) as String?,
      isFirstLogin:
          (json['IsFirstLogin'] ?? json['isFirstLogin'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'nombre': nombre,
    'apellidoPaterno': apellidoPaterno,
    'apellidoMaterno': apellidoMaterno,
    'rol': rol,
    'grupoId': grupoId,
    'carreraId': carreraId,
    'matricula': matricula,
    'fotoUrl': fotoUrl,
    'isFirstLogin': isFirstLogin,
  };

  // Helpers para SecureStorage (almacena como JSON string)
  String toJsonString() => jsonEncode(toJson());

  factory AppUser.fromJsonString(String raw) =>
      AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  AppUser copyWith({
    String? uid,
    String? email,
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? rol,
    String? grupoId,
    String? carreraId,
    String? matricula,
    String? fotoUrl,
    bool? isFirstLogin,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      rol: rol ?? this.rol,
      grupoId: grupoId ?? this.grupoId,
      carreraId: carreraId ?? this.carreraId,
      matricula: matricula ?? this.matricula,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
    );
  }
}
