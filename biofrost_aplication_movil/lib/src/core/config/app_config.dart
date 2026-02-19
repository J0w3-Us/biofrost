/// Configuración centralizada de la aplicación.
///
/// Los valores se inyectan en build via `--dart-define`:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.x:5093
///
/// Si no se provee, usa el valor por defecto (localhost de desarrollo).
class AppConfig {
  AppConfig._();

  /// URL base del backend .NET
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5093',
  );

  /// Firebase project ID (informativo; la config real va en google-services.json)
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'integradorhub-dsm',
  );

  /// Timeout por defecto para peticiones HTTP (en segundos)
  static const int httpTimeoutSeconds = 15;

  /// Nombre de la clave en SecureStorage para el JWT
  static const String jwtStorageKey = 'bifrost_jwt';

  /// Nombre de la clave en SecureStorage para el JSON del usuario
  static const String userStorageKey = 'bifrost_user';
}
