import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:biofrost/core/errors/app_exceptions.dart';
import 'package:biofrost/core/router/app_router.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/core/widgets/ui_kit.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';

enum _AuthMode { login, register }

/// Pantalla de autenticación con Login y Registro integrados.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  // ── Modo ─────────────────────────────────────────────────────────────
  _AuthMode _mode = _AuthMode.login;

  // ── Claves de formulario ─────────────────────────────────────────────
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // ── Controllers: Login ───────────────────────────────────────────────
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // ── Controllers: Register ────────────────────────────────────────────
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _organizacionCtrl = TextEditingController(); // Para evaluadores con Gmail

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
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _organizacionCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Auth ─────────────────────────────────────────────────────────────

  Future<void> _login() async {
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).loginAsDocente(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  Future<void> _register() async {
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).registerDocente(
          email: _regEmailCtrl.text.trim(),
          password: _regPassCtrl.text,
          nombre: _nombreCtrl.text.trim(),
          apellidoPaterno: _apellidoCtrl.text.trim().isEmpty
              ? null
              : _apellidoCtrl.text.trim(),
          organizacion: _organizacionCtrl.text.trim().isEmpty
              ? null
              : _organizacionCtrl.text.trim(),
        );
  }

  void _switchMode(_AuthMode newMode) {
    if (_mode == newMode) return;
    // Pre-llena el email en registro si ya fue escrito en login
    if (newMode == _AuthMode.register && _emailCtrl.text.isNotEmpty) {
      _regEmailCtrl.text = _emailCtrl.text;
    }
    // Limpia error previo para que no contamine el nuevo modo
    ref.read(authProvider.notifier).clearError();
    setState(() => _mode = newMode);
  }

  void _continueAsVisitor() {
    ref.read(authProvider.notifier).continueAsVisitor();
    context.go(AppRoutes.showcase);
  }

  // ── Validación ───────────────────────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu correo.';
    if (!value.contains('@')) return 'Ingresa un correo válido.';
    // Permitir emails institucionales Y Gmail para evaluadores
    if (!value.endsWith('@utmetropolitana.edu.mx') && !value.endsWith('@gmail.com'))
      return 'Usa tu correo institucional (@utmetropolitana.edu.mx) o Gmail (@gmail.com)';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña.';
    if (value.length < 6) return 'Mínimo 6 caracteres.';
    return null;
  }

  String? _validateNombre(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu nombre.';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña.';
    if (value != _regPassCtrl.text) return 'Las contraseñas no coinciden.';
    return null;
  }

  // ── Error display ─────────────────────────────────────────────────────

  String _errorMessage(AppException e) => switch (e) {
        AuthException(:final message) =>
          message.isEmpty ? 'Credenciales incorrectas.' : message,
        ForbiddenException(:final message) =>
          message.isEmpty ? 'Sin acceso. Contacta al administrador.' : message,
        NetworkException(:final message) =>
          message.isEmpty ? 'Sin conexión. Verifica tu red.' : message,
        _ => 'Ocurrió un error. Intenta de nuevo.',
      };

  /// True si el error sugiere que el usuario no tiene cuenta aún.
  bool _isNoAccountError(AppException? e) {
    if (e is! AuthException) return false;
    return e.code == 'no-account' ||
        (e.message.contains('Regístrate') || e.message.contains('registr'));
  }

  /// True si el error sugiere que el correo ya tiene cuenta (en registro).
  bool _isAlreadyExistsError(AppException? e) {
    if (e is! AuthException) return false;
    return e.code == 'email-already-in-use';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthStateLoading;
    final error = authState is AuthStateError ? authState.exception : null;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.sp24,
              vertical: AppTheme.sp32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.sp20),

                // ── Logotipo ──────────────────────────────────────
                _LogoSection(),

                const SizedBox(height: AppTheme.sp32),

                // ── Toggle Login / Registro ────────────────────────
                _ModeToggle(
                  mode: _mode,
                  onChanged: _switchMode,
                ),

                const SizedBox(height: AppTheme.sp32),

                // ── Formulario animado ─────────────────────────────
                AnimatedSwitcher(
                  duration: AppTheme.animNormal,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: _mode == _AuthMode.login
                      ? _LoginForm(
                          key: const ValueKey(_AuthMode.login),
                          formKey: _loginFormKey,
                          emailCtrl: _emailCtrl,
                          passwordCtrl: _passwordCtrl,
                          isLoading: isLoading,
                          errorMessage:
                              error != null ? _errorMessage(error) : null,
                          suggestRegister: _isNoAccountError(error),
                          onSwitchToRegister: () =>
                              _switchMode(_AuthMode.register),
                          onLogin: isLoading ? null : _login,
                          validateEmail: _validateEmail,
                          validatePassword: _validatePassword,
                        )
                      : _RegisterForm(
                          key: const ValueKey(_AuthMode.register),
                          formKey: _registerFormKey,
                          nombreCtrl: _nombreCtrl,
                          apellidoCtrl: _apellidoCtrl,
                          emailCtrl: _regEmailCtrl,
                          passwordCtrl: _regPassCtrl,
                          confirmCtrl: _confirmPassCtrl,
                          organizacionCtrl: _organizacionCtrl,
                          isLoading: isLoading,
                          errorMessage:
                              error != null ? _errorMessage(error) : null,
                          suggestLogin: _isAlreadyExistsError(error),
                          onSwitchToLogin: () => _switchMode(_AuthMode.login),
                          onRegister: isLoading ? null : _register,
                          validateEmail: _validateEmail,
                          validatePassword: _validatePassword,
                          validateNombre: _validateNombre,
                          validateConfirm: _validateConfirm,
                        ),
                ),

                // ── Visitante (solo en modo login) ─────────────────
                if (_mode == _AuthMode.login) ...[
                  const SizedBox(height: AppTheme.sp16),
                  const BioDivider(label: 'O CONTINÚA COMO'),
                  const SizedBox(height: AppTheme.sp16),
                  BioButton(
                    label: 'Visitante',
                    onTap: isLoading ? null : _continueAsVisitor,
                    variant: BioButtonVariant.secondary,
                    icon: Icons.person_outline_rounded,
                  ),
                ],

                const SizedBox(height: AppTheme.sp32),

                // ── Nota eliminada: la información de dominio
                // está embebida en el placeholder del campo de email.
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets internos ──────────────────────────────────────────────────

// ── _ModeToggle — Segmented control Login / Registro ─────────────────────

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});
  final _AuthMode mode;
  final void Function(_AuthMode) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: AppTheme.bMD,
      ),
      child: Row(
        children: [
          _ModeTab(
            label: 'Iniciar sesión',
            isActive: mode == _AuthMode.login,
            onTap: () => onChanged(_AuthMode.login),
          ),
          _ModeTab(
            label: 'Registrarse',
            isActive: mode == _AuthMode.register,
            onTap: () => onChanged(_AuthMode.register),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.surface0 : Colors.transparent,
            borderRadius: AppTheme.bSM,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppTheme.textPrimary : AppTheme.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

// ── _LoginForm ────────────────────────────────────────────────────────────

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.isLoading,
    required this.errorMessage,
    required this.suggestRegister,
    required this.onSwitchToRegister,
    required this.onLogin,
    required this.validateEmail,
    required this.validatePassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool isLoading;
  final String? errorMessage;
  final bool suggestRegister;
  final VoidCallback onSwitchToRegister;
  final VoidCallback? onLogin;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BioInput(
            controller: emailCtrl,
            hint: 'usuario@utmetropolitana.edu.mx',
            label: 'Correo institucional',
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: validateEmail,
          ),
          const SizedBox(height: AppTheme.sp16),
          BioInput(
            controller: passwordCtrl,
            hint: '••••••••',
            label: 'Contraseña',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onLogin?.call(),
            validator: validatePassword,
          ),

          // ── Error + sugerencia de registro ─────────────────────────
          if (errorMessage != null) ...[
            const SizedBox(height: AppTheme.sp12),
            _ErrorBanner(message: errorMessage!),
            if (suggestRegister) ...[
              const SizedBox(height: AppTheme.sp8),
              GestureDetector(
                onTap: onSwitchToRegister,
                child: const Text(
                  '¿Eres nuevo? Toca aquí para registrarte →',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: AppTheme.sp24),
          BioButton(
            label: 'Iniciar sesión',
            onTap: onLogin,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

// ── _RegisterForm ─────────────────────────────────────────────────────────

class _RegisterForm extends StatefulWidget {
  const _RegisterForm({
    super.key,
    required this.formKey,
    required this.nombreCtrl,
    required this.apellidoCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.organizacionCtrl,
    required this.isLoading,
    required this.errorMessage,
    required this.suggestLogin,
    required this.onSwitchToLogin,
    required this.onRegister,
    required this.validateEmail,
    required this.validatePassword,
    required this.validateNombre,
    required this.validateConfirm,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nombreCtrl;
  final TextEditingController apellidoCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final TextEditingController organizacionCtrl;
  final bool isLoading;
  final String? errorMessage;
  final bool suggestLogin;
  final VoidCallback onSwitchToLogin;
  final VoidCallback? onRegister;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;
  final String? Function(String?) validateNombre;
  final String? Function(String?) validateConfirm;

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en email para mostrar/ocultar campo organización
    widget.emailCtrl.addListener(() {
      setState(() {}); // Trigger rebuild cuando cambia el email
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Nombre + Apellido en row ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: BioInput(
                  controller: widget.nombreCtrl,
                  hint: 'Nombre',
                  label: 'Nombre *',
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: widget.validateNombre,
                ),
              ),
              const SizedBox(width: AppTheme.sp12),
              Expanded(
                flex: 4,
                child: BioInput(
                  controller: widget.apellidoCtrl,
                  hint: 'Apellido paterno',
                  label: 'Apellido (opcional)',
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sp16),

          // ── Correo ────────────────────────────────────────────────
          BioInput(
            controller: widget.emailCtrl,
            hint: 'usuario@utmetropolitana.edu.mx o usuario@gmail.com',
            label: 'Correo *',
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: widget.validateEmail,
          ),
          const SizedBox(height: AppTheme.sp16),

          // ── Organización (solo para Gmail) ────────────────────────
          if (widget.emailCtrl.text.endsWith('@gmail.com')) ...[
            BioInput(
              controller: widget.organizacionCtrl,
              hint: 'Empresa, freelance, etc.',
              label: 'Organización (opcional)',
              prefixIcon: Icons.business_outlined,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppTheme.sp16),
          ],

          // ── Contraseña ────────────────────────────────────────────
          BioInput(
            controller: widget.passwordCtrl,
            hint: '••••••••',
            label: 'Contraseña *',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.next,
            validator: widget.validatePassword,
          ),
          const SizedBox(height: AppTheme.sp16),

          // ── Confirmar contraseña ───────────────────────────────────
          BioInput(
            controller: widget.confirmCtrl,
            hint: '••••••••',
            label: 'Confirmar contraseña *',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => widget.onRegister?.call(),
            validator: widget.validateConfirm,
          ),

          const SizedBox(height: AppTheme.sp8),
          // ── Mostrar / ocultar contraseña ──────────────────────────
          GestureDetector(
            onTap: () => setState(() => _showPassword = !_showPassword),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 14,
                  color: AppTheme.textDisabled,
                ),
                const SizedBox(width: AppTheme.sp6),
                Text(
                  _showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.textDisabled,
                  ),
                ),
              ],
            ),
          ),

          // ── Error + sugerencia de login ────────────────────────────
          if (widget.errorMessage != null) ...[
            const SizedBox(height: AppTheme.sp12),
            _ErrorBanner(message: widget.errorMessage!),
            if (widget.suggestLogin) ...[
              const SizedBox(height: AppTheme.sp8),
              GestureDetector(
                onTap: widget.onSwitchToLogin,
                child: const Text(
                  '¿Ya tienes cuenta? Toca aquí para iniciar sesión →',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: AppTheme.sp24),
          BioButton(
            label: 'Crear cuenta',
            onTap: widget.onRegister,
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }
}

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
