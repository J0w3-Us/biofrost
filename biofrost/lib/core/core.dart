/// Barrel export central para el módulo core.
///
/// Importar este archivo da acceso a toda la capa funcional:
/// ```dart
/// import 'package:biofrost/core/core.dart';
/// ```
library core;

// Config
export 'config/app_config.dart';
export 'config/api_endpoints.dart';

// Errors
export 'errors/app_exceptions.dart';

// Services
export 'services/api_service.dart';
export 'services/analytics_service.dart';
export 'services/connectivity_service.dart';

// Domain models (feature-local — re-exported for convenience)
export 'package:biofrost/features/auth/domain/models/user_read_model.dart';
export 'package:biofrost/features/showcase/domain/models/project_read_model.dart';
export 'package:biofrost/features/evaluations/domain/models/evaluation_read_model.dart';
export 'package:biofrost/features/project_detail/domain/models/comment_read_model.dart';
export 'package:biofrost/features/project_detail/domain/models/star_rating_read_model.dart';

// Router
export 'router/app_router.dart';

// Theme
export 'theme/app_theme.dart';

// Shared widgets
export 'widgets/ui_kit.dart';

// ── Módulo 3 ──────────────────────────────────────────────────────────────

// Cache (offline support)
export 'cache/cache_service.dart';

// Push Notifications
export 'notifications/notification_service.dart';

// Deep Links
export 'deeplinks/deep_link_service.dart';
