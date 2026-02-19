import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

/// Servicio de inicialización de Firebase.
///
/// Llama a [initialize] una sola vez desde `main()` antes de `runApp`.
/// Utiliza `google-services.json` (Android) y `GoogleService-Info.plist` (iOS)
/// para la configuración real del proyecto.
class FirebaseService {
  FirebaseService._();

  static final _log = Logger();
  static bool _initialized = false;

  /// Inicializa Firebase. Seguro de llamar múltiples veces (es idempotente).
  /// Nunca lanza excepción — si Firebase no está disponible la app arranca
  /// en modo degradado y las operaciones de auth/storage mostrarán un mensaje.
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
      _log.i('FirebaseService: initialized ✓');
    } on Object catch (e) {
      // PlatformException nativo (google-services.json ausente) u otro error.
      // Se degrada silenciosamente; la app arranca igual.
      _log.w('FirebaseService: init failed ($e). Firebase disabled.');
    }
  }
}
