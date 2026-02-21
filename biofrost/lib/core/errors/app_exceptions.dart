/// Jerarquía de excepciones del dominio Biofrost.
///
/// Traduce errores técnicos del backend a excepciones semánticas
/// que los providers pueden mapear a mensajes de usuario.
///
/// Regla CQRS (AI/rules.md §6):
/// - Conexión → [NetworkException]
/// - Validación de negocio → [BusinessException]
/// - Autenticación/Permisos → [AuthException]
/// - No encontrado → [NotFoundException]
library domain_exceptions;

// ── Clase base ─────────────────────────────────────────────────────────

/// Excepción base del dominio.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code});

  /// Mensaje legible por el usuario.
  final String message;

  /// Código de error/correlación para debugging (nunca se muestra al usuario).
  final String? code;

  @override
  String toString() => 'AppException($code): $message';
}

// ── Excepciones específicas ────────────────────────────────────────────

/// Error de conexión de red (timeout, sin internet).
///
/// UX: SnackBar con opción "Reintentar".
final class NetworkException extends AppException {
  const NetworkException({
    String message = 'Sin conexión. Verifica tu red e intenta de nuevo.',
    String? code,
  }) : super(message, code: code);
}

/// Error de autenticación o sesión expirada.
///
/// UX: Redirigir al login.
final class AuthException extends AppException {
  const AuthException({
    String message = 'Tu sesión expiró. Inicia sesión nuevamente.',
    String? code,
  }) : super(message, code: code);
}

/// El rol del usuario no tiene permisos para esta acción.
///
/// UX: Mensaje inline o modal de acceso denegado.
final class ForbiddenException extends AppException {
  const ForbiddenException({
    String message = 'No tienes permisos para realizar esta acción.',
    String? code,
  }) : super(message, code: code);
}

/// El recurso solicitado no existe en el backend.
final class NotFoundException extends AppException {
  const NotFoundException({
    String message = 'El recurso solicitado no fue encontrado.',
    String? code,
  }) : super(message, code: code);
}

/// Error de validación de negocio (campo inválido, regla de negocio violada).
///
/// UX: Texto de error rojo junto al campo o formulario.
final class BusinessException extends AppException {
  const BusinessException(
    super.message, {
    super.code,
    this.field,
  });

  /// Campo específico que produjo el error de validación (opcional).
  final String? field;
}

/// Error inesperado del servidor (5xx) o error no clasificado.
///
/// UX: SnackBar genérico.
final class ServerException extends AppException {
  const ServerException({
    String message = 'Ocurrió un error inesperado. Intenta más tarde.',
    String? code,
  }) : super(message, code: code);
}

/// El usuario cancela una operación (por ejemplo, cierra el popup de Google).
final class CancelledException extends AppException {
  const CancelledException({String message = 'Operación cancelada.'})
      : super(message);
}
