import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'src/core/firebase/firebase_service.dart';
import 'src/features/auth/application/auth_notifier.dart';
import 'src/features/auth/ui/group_selector_page.dart';
import 'src/features/auth/ui/login_page.dart';
import 'src/features/auth/ui/register_page.dart';
import 'src/features/evaluations/evaluations_routes.dart';
import 'src/features/profile/ui/profile_page.dart';
import 'src/features/projects/projects_routes.dart';
import 'src/features/teams/teams_routes.dart';
import 'src/features/showcase/ui/showcase_page.dart';
import 'src/features/storage/ui/storage_page.dart';
import 'src/ui/app_shell.dart';
import 'src/ui/ui_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Firebase es opcional — si google-services.json no está presente la app
  // arranca igual; auth/storage mostrarán un error claro al usuario.
  try {
    await FirebaseService.initialize();
  } on Object catch (_) {
    // Cualquier error nativo que escape el catch interno no bloquea runApp.
  }
  runApp(const ProviderScope(child: BifrostApp()));
}

class BifrostApp extends StatelessWidget {
  const BifrostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bifrost',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C3AED),
          secondary: Color(0xFF5B21B6),
        ),
      ),
      initialRoute: '/',
      builder: (context, child) =>
          OfflineBanner(child: child ?? const SizedBox.shrink()),
      routes: {
        // ── Guard raíz ────────────────────────────────────────────────────
        '/': (_) => const _AuthGuard(),

        // ── Auth ──────────────────────────────────────────────────────────
        LoginPage.routeName: (_) => const LoginPage(), // /login
        RegisterPage.routeName: (_) => const RegisterPage(), // /register
        GroupSelectorPage.routeName:
            (_) => // /group-selector
                const GroupSelectorPage(),

        // ── Storage ───────────────────────────────────────────────────────
        StoragePage.routeName: (_) => const StoragePage(), // /storage
        // ── Profile ──────────────────────────────────────────────────────────
        ProfilePage.routeName: (_) => const ProfilePage(), // /profile
        // ── Showcase ─────────────────────────────────────────────────────────
        ShowcasePage.routeName: (_) => const ShowcasePage(), // /showcase
        // ── Evaluations ──────────────────────────────────────────────────────
        ...evaluationsRoutes(), // /evaluations
        // ── Teams ────────────────────────────────────────────────────────────
        ...teamsRoutes(), // /teams
        // ── Projects ─────────────────────────────────────────────────────────
        ...projectsRoutes(), // /projects
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Guard raíz
// ---------------------------------------------------------------------------

/// Determina la primera pantalla según el estado de autenticación.
///
/// Estados:
///   loading        → [_SplashScreen] (restaurando sesión del dispositivo)
///   unauthenticated → [LoginPage]    (sin sesión → ir a login)
///   authenticated  → [_HomeStub]     (sesión activa → pantalla principal)
class _AuthGuard extends ConsumerWidget {
  const _AuthGuard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return switch (auth.status) {
      AuthStatus.loading => const _SplashScreen(),
      // La AppShell maneja ambos estados (guest y autenticado).
      // El FAB de login se muestra automáticamente cuando no hay sesión.
      AuthStatus.unauthenticated || AuthStatus.error => const AppShell(),
      AuthStatus.authenticated => const AppShell(),
    };
  }
}

// ---------------------------------------------------------------------------
// Splash (solo visual — sin lógica de navegación)
// ---------------------------------------------------------------------------

/// Pantalla de carga mientras se restaura la sesión guardada.
/// Solo se muestra durante el cold-start mientras [AuthNotifier._restore]
/// está en curso. El [_AuthGuard] cambia de widget automáticamente al terminar.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hub_rounded, color: AppColors.primary, size: 64),
            SizedBox(height: 24),
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
            SizedBox(height: 16),
            Text(
              'Bifrost',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
