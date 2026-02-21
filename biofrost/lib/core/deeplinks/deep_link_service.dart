import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Servicio que escucha deep links entrantes y los emite como rutas de app.
///
/// Soporta el esquema `biofrost://` y URL universales `https://biofrost.utm.mx`.
///
/// ### Rutas soportadas
/// | Uri                            | Ruta interna       |
/// |--------------------------------|--------------------|
/// | `biofrost://project/{id}`      | `/project/{id}`    |
/// | `biofrost://ranking`           | `/ranking`         |
/// | `biofrost://showcase`          | `/showcase`        |
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();
  final _routeController = StreamController<String>.broadcast();

  Stream<String> get onRoute => _routeController.stream;

  StreamSubscription<Uri>? _sub;

  // ── Inicialización ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // Link inicial (app abierta desde terminated state)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _processUri(initialLink);
      }
    } catch (e) {
      debugPrint('[DeepLink] Error leyendo link inicial: $e');
    }

    // Links en caliente (app en background/foreground)
    _sub = _appLinks.uriLinkStream.listen(
      _processUri,
      onError: (e) => debugPrint('[DeepLink] Stream error: $e'),
    );
  }

  // ── Procesamiento ──────────────────────────────────────────────────────────

  void _processUri(Uri uri) {
    debugPrint('[DeepLink] URI recibida: $uri');
    final route = _mapToRoute(uri);
    if (route != null) {
      debugPrint('[DeepLink] → Ruta: $route');
      _routeController.add(route);
    }
  }

  String? _mapToRoute(Uri uri) {
    // Esquema personalizado: biofrost://
    // Universal links: https://biofrost.utm.mx/...
    final segments = uri.pathSegments;

    if (segments.isEmpty) {
      final host = uri.host;
      return switch (host) {
        'ranking'  => '/ranking',
        'showcase' => '/showcase',
        _          => '/showcase',
      };
    }

    return switch (segments.first) {
      'project' when segments.length >= 2 => '/project/${segments[1]}',
      'ranking'                           => '/ranking',
      'showcase'                          => '/showcase',
      _                                   => null,
    };
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  void dispose() {
    _sub?.cancel();
    _routeController.close();
  }
}

// ── State & Provider ──────────────────────────────────────────────────────────

class DeepLinkState {
  const DeepLinkState({this.pendingRoute});
  final String? pendingRoute;
  DeepLinkState copyWith({String? pendingRoute}) =>
      DeepLinkState(pendingRoute: pendingRoute);
}

class DeepLinkNotifier extends StateNotifier<DeepLinkState> {
  DeepLinkNotifier() : super(const DeepLinkState());

  StreamSubscription<String>? _sub;

  Future<void> initialize() async {
    await DeepLinkService.instance.initialize();
    _sub = DeepLinkService.instance.onRoute.listen((route) {
      state = DeepLinkState(pendingRoute: route);
    });
  }

  void consumeRoute() => state = const DeepLinkState();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final deepLinkProvider =
    StateNotifierProvider<DeepLinkNotifier, DeepLinkState>((ref) {
  return DeepLinkNotifier();
});
