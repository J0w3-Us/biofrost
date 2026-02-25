import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:biofrost/features/auth/pages/login_page.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';
import 'package:biofrost/features/profile/pages/profile_page.dart';
import 'package:biofrost/features/project_detail/pages/project_detail_page.dart';
import 'package:biofrost/features/ranking/pages/ranking_page.dart';
import 'package:biofrost/features/showcase/pages/showcase_page.dart';

/// Rutas de la aplicación — constantes para evitar strings sueltos.
abstract class AppRoutes {
  // Públicas (Visitante + Docente)
  static const String splash = '/';
  static const String login = '/login';
  static const String showcase = '/showcase';
  static const String ranking = '/ranking';
  static const String projectDetail = '/project/:id';

  static const String profile = '/profile';

  /// Genera la ruta de detalle con el ID ya inyectado.
  static String projectDetailOf(String id) => '/project/$id';
}

// ── GoRouter Provider ───────────────────────────────────────────────────

/// [ChangeNotifier] que re-evalúa el redirect del router cada vez que
/// [authProvider] cambia de estado.
///
/// Sin esto, el redirect usa `ref.read` que solo lee una vez y GoRouter
/// nunca sabe que el estado cambió → no redirige después del login.
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    // Escucha cada cambio de authProvider y notifica al GoRouter
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

/// Router configurado como Provider para poder leer el estado de auth.
///
/// Guards:
/// - Rutas protegidas → [AuthStateAuthenticated] con rol Docente.
/// - Rutas públicas → cualquier estado (incluye Visitante).
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.showcase,
    debugLogDiagnostics: true,
    // refreshListenable hace que redirect() se re-evalúe cada vez que
    // _AuthRouterNotifier llama notifyListeners() (= cada cambio de auth).
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;

      // Rutas protegidas (solo Docente autenticado)
      const protectedRoutes = [AppRoutes.profile];
      final isProtected = protectedRoutes.any(
        (r) => location.startsWith(r),
      );

      if (isProtected) {
        final isDocente =
            authState is AuthStateAuthenticated && authState.user.isDocente;
        if (!isDocente) return AppRoutes.login;
      }

      // Mientras carga → no redirigir (splash)
      if (authState is AuthStateLoading) return null;

      // Docente autenticado en login → ir a showcase (panel consolidado)
      if (location == AppRoutes.login && authState is AuthStateAuthenticated) {
        return AppRoutes.showcase;
      }

      // Visitante en login → showcase
      if (location == AppRoutes.login && authState is AuthStateVisitor) {
        return AppRoutes.showcase;
      }

      return null; // Sin redirect
    },
    routes: [
      // ── Login ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // ── Showcase (público) ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.showcase,
        name: 'showcase',
        builder: (context, state) => const ShowcasePage(),
      ),

      // ── Ranking (público) ─────────────────────────────────────────
      GoRoute(
        path: AppRoutes.ranking,
        name: 'ranking',
        builder: (context, state) => const RankingPage(),
      ),

      // ── Detalle de Proyecto (público) ─────────────────────────────
      GoRoute(
        path: AppRoutes.projectDetail,
        name: 'projectDetail',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return ProjectDetailPage(projectId: projectId);
        },
      ),
      // Docente projects page removed; routes consolidated to showcase/profile.
      // ── Perfil (solo Docente) ─────────────────────────────────────
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );
});
