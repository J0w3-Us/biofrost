/// CQRS Commands para el dominio de autenticación.
///
/// Cada command representa una intención de escritura que modifica estado.
/// Documentado en AI/rules.md §2: "Define CommandModel para transacciones".

// ── Command: Iniciar sesión como Docente ──────────────────────────────

/// Command para autenticar un Docente con email y contraseña.
///
/// Endpoint: POST /api/auth/login (tras Firebase sign-in).
class SignInDocenteCommand {
  const SignInDocenteCommand({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

// ── Command: Registrar Docente ─────────────────────────────────────────

/// Command para registrar un nuevo Docente en Firebase + backend.
///
/// Endpoint: POST /api/auth/register
class RegisterDocenteCommand {
  const RegisterDocenteCommand({
    required this.email,
    required this.password,
    required this.nombre,
    this.apellidoPaterno,
    this.apellidoMaterno,
  });

  final String email;
  final String password;
  final String nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;

  Map<String, dynamic> toRegisterPayload(String firebaseUid) => {
        'firebaseUid': firebaseUid,
        'email': email,
        'nombre': nombre,
        'apellidoPaterno': apellidoPaterno,
        'apellidoMaterno': apellidoMaterno,
        'rol': 'Docente',
      };
}

// ── Command: Actualizar foto de perfil ────────────────────────────────

/// Command para subir una nueva foto de perfil.
///
/// Flujo: subir a Firebase Storage → PUT /api/users/{uid}/photo.
class UpdateProfilePhotoCommand {
  const UpdateProfilePhotoCommand({
    required this.userId,
    required this.localFilePath,
  });

  final String userId;
  final String localFilePath;
}

// ── Command: Actualizar nombre de perfil ──────────────────────────────

/// Command para actualizar el display name del usuario.
class UpdateDisplayNameCommand {
  const UpdateDisplayNameCommand({
    required this.userId,
    required this.nombre,
  });

  final String userId;
  final String nombre;
}
