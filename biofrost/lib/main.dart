import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/cache/cache_service.dart';
import 'core/config/app_config.dart';
import 'core/deeplinks/deep_link_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/services/connectivity_service.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/widgets/ui_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ──────────────────────────────────────────────────────────────
  await Firebase.initializeApp();

  // ── Supabase (Storage + Comments) ─────────────────────────────────────────
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // ── Módulo 3: Caché ───────────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();

  // ── Módulo 3: Notificaciones Push ─────────────────────────────────────────
  // No se bloquea main() — el diálogo de permiso de Android 13 se resuelve
  // en background para que runApp() no quede esperando al usuario.
  NotificationService.instance.initialize().catchError(
        (e) => debugPrint('[Boot] Notificaciones no disponibles: $e'),
      );

  // ── Módulo 3: Deep Links ──────────────────────────────────────────────────
  await DeepLinkService.instance.initialize();

  // ── Módulo 3: Conectividad Offline ───────────────────────────────────────
  await ConnectivityService.instance.initialize();

  runApp(
    ProviderScope(
      // Inyectar SharedPreferences para que CacheService esté disponible
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const BiofrostApp(),
    ),
  );
}

/// Widget raíz de la aplicación Biofrost.
class BiofrostApp extends ConsumerWidget {
  const BiofrostApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // ── Reaccionar a deep links ────────────────────────────────────────────
    ref.listen<DeepLinkState>(deepLinkProvider, (_, next) {
      final route = next.pendingRoute;
      if (route != null) {
        router.go(route);
        ref.read(deepLinkProvider.notifier).consumeRoute();
      }
    });

    // ── Reaccionar a taps en notificaciones ───────────────────────────────
    ref.listen<NotificationState>(notificationProvider, (_, next) {
      final route = next.pendingRoute;
      if (route != null) {
        router.go(route);
        ref.read(notificationProvider.notifier).consumeRoute();
      }
    });

    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Biofrost — IntegradorHub',
      debugShowCheckedModeBanner: false,
      theme: themeMode == AppThemeModeOption.dark
          ? AppTheme.dark()
          : AppTheme.light(),
      routerConfig: router,
      // ── Banner offline global (Módulo 4.2) ──────────────────────────────
      // Envuelve la navegación completa para que el banner aparezca en
      // cualquier pantalla sin repetir código en cada página.
      builder: (context, child) => Consumer(
        builder: (ctx, ref, _) {
          final isOnline = ref.watch(connectivityProvider);
          return Column(
            children: [
              OfflineBanner(isOnline: isOnline),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  }
}
