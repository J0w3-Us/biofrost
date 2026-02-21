import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Monitorea el estado de conectividad de red en tiempo real.
///
/// Usa [connectivity_plus] para detectar transiciones online ↔ offline
/// y los expone como un [Stream<bool>] donde `true` = con red.
///
/// ### Uso
/// ```dart
/// final isOnline = ref.watch(connectivityProvider);
/// if (!isOnline) { /* mostrar banner offline */ }
/// ```
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  // Stream filtrado: sólo emite cuando la app pasa de offline → online.
  final _onlineController = StreamController<void>.broadcast();

  Stream<bool> get onChanged => _controller.stream;

  /// Emite un evento cada vez que la conectividad se **restaura**.
  /// Úsalo en notifiers para disparar recargas automáticas.
  Stream<void> get onCameOnline => _onlineController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _sub;

  // ── Inicialización ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // Idempotente — solo se inicializa una vez aunque se llame varias veces.
    if (_sub != null) return;

    // Verificar estado actual antes de escuchar cambios.
    final results = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(results);
    debugPrint(
        '[Connectivity] Estado inicial: ${_isOnline ? "Online" : "Offline"}');

    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final online = _isConnected(results);
      if (online != _isOnline) {
        final wasOffline = !_isOnline;
        _isOnline = online;
        debugPrint('[Connectivity] Cambio → ${online ? "Online" : "Offline"}');
        _controller.add(online);
        // Notificar recuperación de red (offline → online)
        if (online && wasOffline) {
          _onlineController.add(null);
        }
      }
    });
  }

  /// `true` si al menos un tipo de conexión está disponible.
  static bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  void dispose() {
    _sub?.cancel();
    _controller.close();
    _onlineController.close();
  }
}

// ── RetryScheduler ────────────────────────────────────────────────────────────

/// Ejecuta [action] con backoff exponencial cuando la red se restaura.
///
/// Configuración por defecto:
/// - Base: 2 s → 4 s → 8 s  (duplica en cada intento)
/// - Máximo de intentos: 3
///
/// ### Uso en un Notifier
/// ```dart
/// _retryScheduler = RetryScheduler(action: () => load(forceRefresh: true));
/// _retryScheduler.startOnRestore(); // escucha onCameOnline
/// ```
class RetryScheduler {
  RetryScheduler({
    required Future<void> Function() action,
    Duration baseDelay = const Duration(seconds: 2),
    int maxAttempts = 3,
  })  : _action = action,
        _baseDelay = baseDelay,
        _maxAttempts = maxAttempts;

  final Future<void> Function() _action;
  final Duration _baseDelay;
  final int _maxAttempts;

  StreamSubscription<void>? _sub;
  Timer? _timer;
  int _attempts = 0;
  bool _running = false;

  /// Suscribe al stream [ConnectivityService.onCameOnline] y programa
  /// la [action] con backoff exponencial al recuperar la red.
  void startOnRestore() {
    _sub = ConnectivityService.instance.onCameOnline.listen((_) {
      _scheduleNext();
    });
  }

  void _scheduleNext() {
    if (_running || _attempts >= _maxAttempts) return;
    final delay = _baseDelay * math.pow(2, _attempts).toInt();
    debugPrint(
      '[Retry] Intento ${_attempts + 1}/$_maxAttempts en ${delay.inSeconds}s',
    );
    _timer?.cancel();
    _timer = Timer(delay, () async {
      if (_running) return;
      _running = true;
      try {
        await _action();
        _attempts = 0; // éxito → resetear contador
      } catch (e) {
        _attempts++;
        debugPrint('[Retry] Fallo intento $_attempts: $e');
        if (_attempts < _maxAttempts) _scheduleNext();
      } finally {
        _running = false;
      }
    });
  }

  /// Cancela todos los reintentos pendientes.
  void cancel() {
    _sub?.cancel();
    _timer?.cancel();
    _attempts = 0;
    _running = false;
  }
}

// ── State Notifier ────────────────────────────────────────────────────────────

/// Notifier que refleja el estado de conectividad como `bool`.
/// `true` = online, `false` = offline / sin red.
///
/// Se suscribe automáticamente al crearse — ninguna página necesita
/// llamar a `initialize()` manualmente.
class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    _autoSubscribe();
  }

  StreamSubscription<bool>? _sub;

  void _autoSubscribe() {
    // Lee el estado ya disponible (ConnectivityService se inicializa en main).
    state = ConnectivityService.instance.isOnline;
    _sub = ConnectivityService.instance.onChanged.listen((online) {
      state = online;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// `true` si hay conexión activa; `false` en modo offline.
/// Escuchar este provider en cualquier widget para reaccionar a cambios de red.
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});
