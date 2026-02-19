import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_notifier.dart';

/// Pantalla de setup inicial mostrada en el primer login (RN-302).
///
/// Indica al usuario que su cuenta ha sido creada y explica los
/// próximos pasos según su rol. El administrador asignará grupos/materias.
class GroupSelectorPage extends ConsumerWidget {
  const GroupSelectorPage({super.key});

  static const routeName = '/group-selector';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Ícono de bienvenida ──────────────────────────────────
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF7C3AED),
                  size: 44,
                ),
              ),

              // ── Título ───────────────────────────────────────────────
              Text(
                user != null
                    ? '¡Bienvenido, ${user.nombre}!'
                    : '¡Bienvenido a Bifrost!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              // ── Rol badge ─────────────────────────────────────────────
              if (user != null) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _rolColor(user.rol).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _rolColor(user.rol).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _rolIcon(user.rol),
                          color: _rolColor(user.rol),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.rol,
                          style: TextStyle(
                            color: _rolColor(user.rol),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Mensaje por rol ───────────────────────────────────────
              _RoleMessage(rol: user?.rol ?? ''),
              const SizedBox(height: 40),

              // ── CTA ───────────────────────────────────────────────────
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continuar a la app',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),

              TextButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
                child: const Text(
                  'Salir / Cerrar sesión',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _rolColor(String rol) {
    switch (rol) {
      case 'Alumno':
        return const Color(0xFF3B82F6);
      case 'Docente':
        return const Color(0xFF10B981);
      case 'Admin':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B); // Invitado
    }
  }

  static IconData _rolIcon(String rol) {
    switch (rol) {
      case 'Alumno':
        return Icons.school_outlined;
      case 'Docente':
        return Icons.badge_outlined;
      case 'Admin':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.person_outline;
    }
  }
}

// ---------------------------------------------------------------------------
// Mensaje contextual por rol
// ---------------------------------------------------------------------------

class _RoleMessage extends StatelessWidget {
  const _RoleMessage({required this.rol});

  final String rol;

  @override
  Widget build(BuildContext context) {
    final (title, body, icon) = switch (rol) {
      'Alumno' => (
        'Tu cuenta está lista',
        'El administrador asignará tu grupo y carrera. '
            'Podrás ver y gestionar tus proyectos una vez asignado.',
        Icons.info_outline_rounded,
      ),
      'Docente' => (
        'Perfil pendiente de asignación',
        'El administrador configurará tus grupos y materias. '
            'Por ahora puedes explorar la plataforma.',
        Icons.schedule_outlined,
      ),
      'Admin' => (
        'Acceso de administrador',
        'Tienes acceso completo al panel de administración.',
        Icons.admin_panel_settings_outlined,
      ),
      _ => (
        'Acceso como invitado',
        'Puedes explorar los proyectos públicos de la plataforma Bifrost.',
        Icons.explore_outlined,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF7C3AED), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
