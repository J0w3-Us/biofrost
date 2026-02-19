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
      AuthStatus.unauthenticated || AuthStatus.error => const LoginPage(),
      AuthStatus.authenticated => const _HomeStub(),
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

/// Home principal — muestra los módulos disponibles al usuario autenticado.
class _HomeStub extends ConsumerWidget {
  const _HomeStub();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final nombre = user?.nombre ?? 'usuario';
    final rol = user?.rol ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.hub_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Bifrost',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          BifrostAvatar(name: nombre, size: AvatarSize.xs),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(LoginPage.routeName);
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Header de bienvenida
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, $nombre!',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      BifrostBadge.forRol(rol),
                      const SizedBox(width: 8),
                      Text(
                        user?.email ?? '',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Grid de módulos
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                _ModuleTile(
                  icon: Icons.cloud_upload_rounded,
                  label: 'Archivos',
                  description: 'Sube y gestiona tus archivos',
                  color: AppColors.primary,
                  onTap: () =>
                      Navigator.of(context).pushNamed(StoragePage.routeName),
                ),
                _ModuleTile(
                  icon: Icons.person_rounded,
                  label: 'Perfil',
                  description: 'Edita tu información',
                  color: AppColors.info,
                  onTap: () =>
                      Navigator.of(context).pushNamed(ProfilePage.routeName),
                ),
                _ModuleTile(
                  icon: Icons.rocket_launch_rounded,
                  label: 'Proyectos',
                  description: 'Gestión de proyectos',
                  color: AppColors.success,
                  onTap: () =>
                      Navigator.of(context).pushNamed(ProjectsPage.routeName),
                ),
                _ModuleTile(
                  icon: Icons.star_rounded,
                  label: 'Showcase',
                  description: 'Galería de proyectos',
                  color: AppColors.warning,
                  onTap: () =>
                      Navigator.of(context).pushNamed(ShowcasePage.routeName),
                ),
                _ModuleTile(
                  icon: Icons.group_rounded,
                  label: 'Equipos',
                  description: 'Alumnos y docentes',
                  color: AppColors.info,
                  onTap: () =>
                      Navigator.of(context).pushNamed(TeamsPage.routeName),
                ),
                _ModuleTile(
                  icon: Icons.grade_rounded,
                  label: 'Evaluaciones',
                  description: 'Revisa y crea evaluaciones',
                  color: AppColors.error,
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(EvaluationsPage.routeName),
                ),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.1,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile de módulo
// ---------------------------------------------------------------------------

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return BifrostCard(
      onTap: enabled ? onTap : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: enabled
                  ? color.withValues(alpha: 0.15)
                  : AppColors.border.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon,
              color: enabled ? color : AppColors.textDisabled,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: AppTextStyles.caption.copyWith(
              color: enabled ? AppColors.textSecondary : AppColors.textDisabled,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
