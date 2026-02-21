import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:biofrost/core/errors/app_exceptions.dart';
import 'package:biofrost/core/router/app_router.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/core/widgets/ui_kit.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';

/// Pantalla de autenticación.
///
/// Permite:
/// - Login con email @utm.mx + contraseña (rol Docente)
/// - Acceso como Visitante (sin auth)
///
/// Estados gestionados por [authProvider]:
/// - [AuthStateLoading] → muestra spinner sobre el botón
/// - [AuthStateError]   → muestra mensaje bajo el formulario
/// - [AuthStateAuthenticated] → router redirige automáticamente
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Auth ────────────────────────────────────────────────────────────

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier).loginAsDocente(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    // La redirección la maneja el router reactivo.
  }

  void _continueAsVisitor() {
    ref.read(authProvider.notifier).continueAsVisitor();
    context.go(AppRoutes.showcase);
  }

  // ── Validación ──────────────────────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu correo.';
    if (!value.contains('@')) return 'Ingresa un correo válido.';
    if (!value.endsWith('@utm.mx')) return 'Usa tu correo institucional (@utm.mx).';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña.';
    if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
    return null;
  }

  // ── Error display ────────────────────────────────────────────────────

  String _errorMessage(AppException e) => switch (e) {
        AuthException(:final message) =>
          message.isEmpty ? 'Credenciales incorrectas.' : message,
        ForbiddenException(:final message) =>
          message.isEmpty ? 'Esta app es solo para Docentes y Visitantes.' : message,
        NetworkException(:final message) =>
          message.isEmpty ? 'Sin conexión. Verifica tu red.' : message,
        _ => 'Ocurrió un error. Intenta de nuevo.',
      };

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthStateLoading;
    final error = authState is AuthStateError ? authState.exception : null;

    return Scaffold(
      backgroundColor: AppTheme.surface0,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.sp24,
              vertical: AppTheme.sp40,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppTheme.sp40),

                  // ── Logotipo / título ──────────────────────────────
                  _LogoSection(),

                  const SizedBox(height: AppTheme.sp48),

                  // ── Formulario ────────────────────────────────────
                  BioInput(
                    controller: _emailCtrl,
                    hint: 'usuario@utm.mx',
                    label: 'Correo institucional',
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: AppTheme.sp16),

                  BioInput(
                    controller: _passwordCtrl,
                    hint: '••••••••',
                    label: 'Contraseña',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: AppTheme.sp8),

                  // ── Error inline ───────────────────────────────────
                  if (error != null) ...[
                    const SizedBox(height: AppTheme.sp12),
                    _ErrorBanner(message: _errorMessage(error)),
                  ],

                  const SizedBox(height: AppTheme.sp32),

                  // ── Botón principal ───────────────────────────────
                  BioButton(
                    label: 'Iniciar sesión',
                    onTap: isLoading ? null : _login,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: AppTheme.sp16),

                  // ── Divisor ────────────────────────────────────────
                  const BioDivider(label: 'O CONTINÚA COMO'),

                  const SizedBox(height: AppTheme.sp16),

                  // ── Visitante ─────────────────────────────────────
                  BioButton(
                    label: 'Visitante',
                    onTap: isLoading ? null : _continueAsVisitor,
                    variant: BioButtonVariant.secondary,
                    icon: Icons.person_outline_rounded,
                  ),

                  const SizedBox(height: AppTheme.sp32),

                  // ── Nota informativa ──────────────────────────────
                  const _InfoNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets internos ──────────────────────────────────────────────────

class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícono minimalista
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: AppTheme.bMD,
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: AppTheme.black,
            size: 28,
          ),
        ),
        const SizedBox(height: AppTheme.sp20),
        const Text(
          'Biofrost',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: AppTheme.sp6),
        const Text(
          'Plataforma de proyectos UTM',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1,
      duration: AppTheme.animNormal,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.sp12),
        decoration: BoxDecoration(
          color: AppTheme.error.withAlpha(26),
          borderRadius: AppTheme.bSM,
          border: Border.all(color: AppTheme.error.withAlpha(77)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppTheme.error, size: 16),
            const SizedBox(width: AppTheme.sp8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppTheme.error,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sp16),
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: AppTheme.bMD,
        border: Border.all(color: AppTheme.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: AppTheme.textDisabled),
          SizedBox(width: AppTheme.sp12),
          Expanded(
            child: Text(
              'Los Docentes inician sesión con su cuenta\ninstitucional @utm.mx. '
              'Los Visitantes acceden sin auth para explorar proyectos públicos.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppTheme.textDisabled,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
