/// Configuración centralizada de la aplicación.
///
/// Los valores se inyectan en build via `--dart-define`:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.x:5093
///
/// Si no se provee, usa el valor por defecto (localhost de desarrollo).
///
/// IMPORTANTE:
/// - Para emulador Android: usar http://10.0.2.2:5093
/// - Para emulador iOS: usar http://127.0.0.1:5093
/// - Para dispositivo físico: usar la IP del PC en la red WiFi (ej: http://192.168.1.216:5093)
class AppConfig {
  AppConfig._();

  /// URL base del backend .NET
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5093', // Default: emulador Android
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
