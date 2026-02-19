/// Jerarquía de excepciones de la aplicación.
///
/// Uso:
/// ```dart
/// try {
///   await repo.doSomething();
/// } on UnauthorizedException {
///   // redirigir a login
/// } on NetworkException {
///   // mostrar "Sin conexión — Reintentar"
/// } on AppException catch (e) {
///   // error genérico: e.userMessage
/// }
/// ```
sealed class AppException implements Exception {
  const AppException({required this.userMessage, this.debugInfo});

  /// Mensaje legible para mostrar al usuario final.
  final String userMessage;

  /// Detalle técnico para logs (nunca mostrar en UI).
  final String? debugInfo;

  @override
  String toString() => 'AppException($runtimeType): $debugInfo';
}

/// No hay conexión a internet o el host es inalcanzable.
final class NetworkException extends AppException {
  const NetworkException({super.debugInfo})
    : super(userMessage: 'Sin conexión. Verifica tu red e intenta de nuevo.');
}

/// El servidor respondió con un error no esperado (5xx).
final class ServerException extends AppException {
  const ServerException({required super.debugInfo})
    : super(userMessage: 'Error del servidor. Intenta más tarde.');
  final int? statusCode = null;
}

/// El token es inválido o expiró (401).
final class UnauthorizedException extends AppException {
  const UnauthorizedException({super.debugInfo})
    : super(userMessage: 'Tu sesión expiró. Inicia sesión de nuevo.');
}

/// El usuario no tiene permisos para la acción (403).
final class ForbiddenException extends AppException {
  const ForbiddenException({super.debugInfo})
    : super(userMessage: 'No tienes permisos para esta acción.');
}

/// El recurso solicitado no existe (404).
final class NotFoundException extends AppException {
  const NotFoundException({required String resource, super.debugInfo})
    : super(userMessage: 'No se encontró: $resource.');
}

/// Error de validación del backend (400 con detalle).
final class ValidationException extends AppException {
  const ValidationException({required String detail, super.debugInfo})
    : super(userMessage: detail);
}

/// Error inesperado genérico.
final class UnknownException extends AppException {
  const UnknownException({super.debugInfo})
    : super(userMessage: 'Ocurrió un error inesperado. Intenta de nuevo.');
}
