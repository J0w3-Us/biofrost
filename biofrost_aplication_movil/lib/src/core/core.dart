/// Barrel de exportaciones del módulo Core.
///
/// Importar este archivo en los módulos de feature:
/// ```dart
/// import 'package:biofrost_aplication_movil/src/core/core.dart';
/// ```
library bifrost_core;

export 'config/app_config.dart';
export 'errors/app_exception.dart';
export 'firebase/firebase_service.dart';
export 'network/api_client.dart';
export 'session/app_user.dart';
export 'session/session_service.dart';
// ── Offline / Cache ────────────────────────────────────────────────────────
export 'offline/connectivity_service.dart';
export 'offline/cache_service.dart';
export 'offline/sync_queue_service.dart';
