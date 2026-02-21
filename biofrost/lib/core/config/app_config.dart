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
  /// ⚠️  `localhost` NO es alcanzable desde un dispositivo físico ni emulador.
  /// Opciones de desarrollo:
  ///   - Emulador Android  → 'http://10.0.2.2:7001'
  ///   - Emulador iOS      → 'http://127.0.0.1:7001'
  ///   - Dispositivo real  → 'http://<IP_LAN_PC>:7001'  (ej. 192.168.1.X)
  ///   - Producción        → URL pública del servidor
  ///
  /// Cambia el valor según el entorno antes de compilar:
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://10.0.2.2:7001');

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
  static const String institutionalDomain = 'utm.mx';

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
}
