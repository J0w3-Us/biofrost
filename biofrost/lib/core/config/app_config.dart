/// Configuración global de la aplicación Biofrost.
///
/// Centraliza todas las constantes de infraestructura:
/// - URL base del backend .NET
/// - Endpoints de cada módulo
/// - Timeouts de red
/// - Parámetros de caché
library app_config;

class AppConfig {
  AppConfig._();

  // ── Backend API ────────────────────────────────────────────────────
  /// URL base del backend IntegradorHub (.NET).
  ///
  /// Se inyecta en tiempo de compilación con --dart-define:
  ///
  ///   Dev (USB físico):
  ///     flutter run   → scripts/dev_run.ps1
  ///
  ///   Producción (Railway):
  ///     flutter build → scripts/build_prod.ps1
  ///
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5093',
  );

  /// True cuando la app está apuntando a un servidor de producción (Railway).
  static bool get isProduction =>
      !apiBaseUrl.contains('localhost') &&
      !apiBaseUrl.contains('10.0.2.2') &&
      !apiBaseUrl.contains('127.0.0.1');

  /// Prefijo para todos los endpoints de la API REST.
  static const String apiPrefix = '/api';

  // ── Timeouts ───────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ── Caché (Stale-While-Revalidate) ────────────────────────────────
  /// TTL de proyectos públicos en caché.
  static const Duration showcaseCacheTtl = Duration(minutes: 5);

  /// TTL del listado de evaluaciones.
  static const Duration evaluationsCacheTtl = Duration(minutes: 2);

  /// TTL genérico para CacheService (alias de showcaseCacheTtl).
  static const Duration cacheTimeout = showcaseCacheTtl;

  // ── Firebase ───────────────────────────────────────────────────────
  /// Dominio institucional permitido para autenticación de docentes.
  static const String institutionalDomain = 'atmetropilonana.edu.mx';

  // ── Paginación ─────────────────────────────────────────────────────
  static const int rankingMaxVisible = 20;
  static const int rankingPodiumCount = 3;

  // ── Roles ──────────────────────────────────────────────────────────
  static const String roleDocente = 'Docente';
  static const String roleAlumno = 'Alumno';
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'SuperAdmin';
  static const String roleVisitante = 'Invitado';

  // ── Móvil: roles permitidos ────────────────────────────────────────
  /// Solo estos roles pueden autenticarse en la app móvil.
  static const List<String> allowedMobileRoles = [roleDocente, roleVisitante];

  // ── Supabase Storage ───────────────────────────────────────────────
  static const String supabaseUrl = 'https://zhnufraaybrruqdtgbwj.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpobnVmcmFheWJycnVxZHRnYndqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA1Njc3MDAsImV4cCI6MjA4NjE0MzcwMH0.qgMscHH824bf9i3PapqjnmRZYolkOPgiKGRXNs_SZMM';
  static const String supabaseBucket = 'project-files';

  /// Construye la URL pública de un archivo en Supabase Storage.
  static String storageUrl(String filePath) =>
      '$supabaseUrl/storage/v1/object/public/$supabaseBucket/$filePath';
}
