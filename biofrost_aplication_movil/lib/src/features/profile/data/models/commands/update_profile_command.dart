// Implementa RF-Profile-01: Edición de perfil de usuario.

/// Comando para actualizar los datos editables del perfil propio.
///
/// Solo contiene campos que el usuario puede modificar por sí mismo.
/// El avatar se gestiona por separado a través del módulo de Storage.
class UpdateProfileCommand {
  const UpdateProfileCommand({
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
  });

  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;

  /// Nombre para display completo — mismo formato que [AppUser.nombreCompleto].
  String get displayName => '$nombre $apellidoPaterno $apellidoMaterno'.trim();

  bool get isValid =>
      nombre.trim().isNotEmpty &&
      apellidoPaterno.trim().isNotEmpty &&
      apellidoMaterno.trim().isNotEmpty;
}
