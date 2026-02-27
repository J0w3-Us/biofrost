import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
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
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve the native splash until Flutter draws first frame / we remove it.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ── Firebase ──────────────────────────────────────────────────────────────
  await Firebase.initializeApp();

  // ── Módulo 3: Caché (rápido) ──────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();

  // Notificaciones: inicializar pero no bloquear UI
  NotificationService.instance.initialize().catchError(
        (e) => debugPrint('[Boot] Notificaciones no disponibles: $e'),
      );

  // Ejecutar las inicializaciones pesadas en background una vez que la app
  // haya arrancado para reducir time-to-first-frame.
  Future<void> bootstrapServices() async {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('[Boot] Supabase init falló: $e');
    }

    DeepLinkService.instance.initialize().catchError(
          (e) => debugPrint('[Boot] DeepLink init falló: $e'),
        );

    ConnectivityService.instance.initialize().catchError(
          (e) => debugPrint('[Boot] Connectivity init falló: $e'),
        );
  }

  runApp(
    ProviderScope(
      // Inyectar SharedPreferences para que CacheService esté disponible
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: SplashRemover(
        onBootstrapped: () => Future.microtask(bootstrapServices),
        child: const BiofrostApp(),
      ),
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
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode == AppThemeModeOption.dark
          ? ThemeMode.dark
          : ThemeMode.light,
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

/// Widget wrapper that removes the native splash after the first frame is
/// rendered and triggers optional background bootstrapping.
class SplashRemover extends StatefulWidget {
  final Widget child;
  final VoidCallback? onBootstrapped;

  const SplashRemover({required this.child, this.onBootstrapped, super.key});

  @override
  State<SplashRemover> createState() => _SplashRemoverState();
}

class _SplashRemoverState extends State<SplashRemover> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Remove native splash once first Flutter frame is drawn.
      FlutterNativeSplash.remove();
      widget.onBootstrapped?.call();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
