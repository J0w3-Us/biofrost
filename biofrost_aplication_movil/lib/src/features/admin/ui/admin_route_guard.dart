import 'package:flutter/material.dart';

/// Widget guardian que protege todas las rutas del módulo Admin.
///
/// Uso:
/// ```dart
/// AdminRouteGuard(
///   userRole: currentUserRole,
///   child: AdminShell(),
/// )
/// ```
///
/// Si el rol no es `Admin` muestra una pantalla de acceso denegado en lugar
/// de las pantallas protegidas.
class AdminRouteGuard extends StatelessWidget {
  const AdminRouteGuard({
    super.key,
    required this.userRole,
    required this.child,
  });

  final String? userRole;
  final Widget child;

  static const _adminRole = 'Admin';

  @override
  Widget build(BuildContext context) {
    if (userRole != _adminRole) {
      return const _AccessDeniedScreen();
    }
    return child;
  }
}

class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 72,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Acceso restringido',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Esta sección es exclusiva para administradores.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
