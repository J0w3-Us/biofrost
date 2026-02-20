import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_notifier.dart';
import '../features/auth/ui/login_page.dart';
import '../features/evaluations/ui/evaluations_page.dart';
import '../features/profile/ui/profile_page.dart';
import '../features/projects/ui/projects_page.dart';
import '../features/showcase/ui/showcase_page.dart';
import '../features/teams/ui/teams_page.dart';
import 'ui_kit.dart';

/// Índice de la tab activa — provider global para la shell.
final shellIndexProvider = StateProvider<int>((ref) => 0);

/// Shell principal de la app.
///
/// Renderiza un [NavigationBar] inferior con 5 destinos y mantiene cada
/// tab viva en memoria mediante [IndexedStack] para preservar el scroll
/// y el estado de cada módulo al cambiar de tab.
///
/// Uso en `main.dart`:
/// ```dart
/// AuthStatus.authenticated => const AppShell(),
/// ```
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellIndexProvider);
    final user = ref.watch(authProvider).user;
    final isGuest = user == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: index,
        children: [
          const ProjectsPage(),
          const ShowcasePage(),
          const TeamsPage(),
          // Evaluaciones sin proyecto seleccionado — muestra estado informativo
          const EvaluationsPage(projectId: ''),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: _ShellNavBar(
        index: index,
        isGuest: isGuest,
        onDestinationSelected: (i) =>
            ref.read(shellIndexProvider.notifier).state = i,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation Bar
// ---------------------------------------------------------------------------

class _ShellNavBar extends StatelessWidget {
  const _ShellNavBar({
    required this.index,
    required this.onDestinationSelected,
    required this.isGuest,
  });

  final int index;
  final ValueChanged<int> onDestinationSelected;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          _dest(
            Icons.rocket_launch_outlined,
            Icons.rocket_launch_rounded,
            'Proyectos',
          ),
          _dest(
            Icons.auto_awesome_outlined,
            Icons.auto_awesome_rounded,
            'Showcase',
          ),
          _dest(Icons.group_outlined, Icons.group_rounded, 'Equipos'),
          _dest(Icons.grade_outlined, Icons.grade_rounded, 'Eval.'),
          _dest(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
        ],
      ),
    );
  }

  NavigationDestination _dest(
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    return NavigationDestination(
      icon: Icon(icon, color: AppColors.textMuted, size: 22),
      selectedIcon: Icon(selectedIcon, color: AppColors.primary, size: 22),
      label: label,
    );
  }
}

// ---------------------------------------------------------------------------
// Login FAB — se muestra dentro del shell cuando no hay sesión
// ---------------------------------------------------------------------------

/// Widget que envuelve su [child] y añade un FAB de "Iniciar sesión"
/// cuando el usuario no está autenticado.
class AuthAwareFab extends ConsumerWidget {
  const AuthAwareFab({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(authProvider).user == null;

    if (!isGuest) return child;

    return Stack(
      children: [
        child,
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.login_rounded, size: 20),
            label: const Text(
              'Iniciar sesión',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: () =>
                Navigator.of(context).pushNamed(LoginPage.routeName),
          ),
        ),
      ],
    );
  }
}
