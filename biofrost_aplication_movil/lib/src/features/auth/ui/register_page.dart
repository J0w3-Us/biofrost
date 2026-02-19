import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/register_notifier.dart';
import '../data/models/commands/register_command.dart';
import 'group_selector_page.dart';
import 'login_page.dart';

/// Formulario de registro extendido con detección automática de rol.
///
/// Implements RF-Auth-02: Registro diferenciado por rol institucional (RN-301).
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  static const routeName = '/register';

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Campos base
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _apPaternoCtrl = TextEditingController();
  final _apMaternoCtrl = TextEditingController();

  // Alumno
  final _grupoIdCtrl = TextEditingController();
  final _carreraIdCtrl = TextEditingController();

  // Docente / Invitado
  final _profesionCtrl = TextEditingController();
  final _organizacionCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String _detectedRol = '';

  // Catálogos (best-effort desde API, fallback hardcoded — mismo patrón web)
  final List<Map<String, String>> _grupos = [
    {'id': '5A', 'nombre': '5A'},
    {'id': '5B', 'nombre': '5B'},
    {'id': '5C', 'nombre': '5C'},
    {'id': '6A', 'nombre': '6A'},
    {'id': '6B', 'nombre': '6B'},
    {'id': '6C', 'nombre': '6C'},
  ];
  final List<Map<String, String>> _carreras = [
    {'id': 'dsm', 'nombre': 'Desarrollo de Software Multiplataforma'},
    {'id': 'im', 'nombre': 'Ingeniería Mecatrónica'},
    {'id': 'isc', 'nombre': 'Ingeniería en Sistemas Computacionales'},
    {'id': 'la', 'nombre': 'Licenciatura en Administración'},
  ];

  String? _selectedGrupoId;
  String? _selectedCarreraId;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    _nombreCtrl.dispose();
    _apPaternoCtrl.dispose();
    _apMaternoCtrl.dispose();
    _grupoIdCtrl.dispose();
    _carreraIdCtrl.dispose();
    _profesionCtrl.dispose();
    _organizacionCtrl.dispose();
    super.dispose();
  }

  void _onEmailChanged(String email) {
    final rol = RegisterNotifier.detectRol(email.trim());
    setState(() => _detectedRol = rol);
    ref.read(registerProvider.notifier).detectRolFromEmail(email);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final rol = RegisterNotifier.detectRol(email);
    final matricula = RegisterNotifier.extractMatricula(email);

    final cmd = RegisterCommand(
      firebaseUid: '', // replaced with real UID inside RegisterNotifier
      email: email,
      nombre: _nombreCtrl.text.trim(),
      apellidoPaterno: _apPaternoCtrl.text.trim(),
      apellidoMaterno: _apMaternoCtrl.text.trim(),
      rol: rol,
      grupoId: rol == 'Alumno' ? _selectedGrupoId : null,
      carreraId: rol == 'Alumno' ? _selectedCarreraId : null,
      matricula: matricula,
      profesion: rol == 'Docente' ? _profesionCtrl.text.trim() : null,
      organizacion: rol == 'Invitado' ? _organizacionCtrl.text.trim() : null,
    );

    await ref
        .read(registerProvider.notifier)
        .register(email: email, password: _passwordCtrl.text, cmd: cmd);
  }

  Color _rolColor() {
    switch (_detectedRol) {
      case 'Alumno':
        return const Color(0xFF3B82F6);
      case 'Docente':
        return const Color(0xFF10B981);
      case 'Invitado':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _rolIcon() {
    switch (_detectedRol) {
      case 'Alumno':
        return Icons.school_outlined;
      case 'Docente':
        return Icons.badge_outlined;
      case 'Invitado':
        return Icons.person_outline;
      default:
        return Icons.email_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registerProvider);

    ref.listen<RegisterState>(registerProvider, (_, next) {
      if (!mounted) return;
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
      }
      if (next.successMessage != null) {
        // Actualizar estado global de auth y navegar
        Navigator.of(context).pushReplacementNamed(GroupSelectorPage.routeName);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(LoginPage.routeName),
        ),
        title: const Text(
          'Crear cuenta',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Sección: Cuenta ─────────────────────────────────────
                _SectionHeader(label: 'Cuenta'),
                const SizedBox(height: 12),

                // Email + badge de rol detectado
                _BifrostField(
                  controller: _emailCtrl,
                  label: 'Correo institucional',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: _onEmailChanged,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu correo';
                    if (!v.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),

                // Badge de rol detectado
                if (_detectedRol.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 4),
                      Icon(_rolIcon(), color: _rolColor(), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Rol detectado: $_detectedRol',
                        style: TextStyle(
                          color: _rolColor(),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),

                _BifrostField(
                  controller: _passwordCtrl,
                  label: 'Contraseña',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.next,
                  suffixIcon: _togglePassButton(
                    value: _obscurePass,
                    onTap: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _BifrostField(
                  controller: _confirmPassCtrl,
                  label: 'Confirmar contraseña',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.next,
                  suffixIcon: _togglePassButton(
                    value: _obscureConfirm,
                    onTap: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v != _passwordCtrl.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ── Sección: Datos personales ────────────────────────────
                _SectionHeader(label: 'Datos personales'),
                const SizedBox(height: 12),

                _BifrostField(
                  controller: _nombreCtrl,
                  label: 'Nombre(s)',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 14),

                _BifrostField(
                  controller: _apPaternoCtrl,
                  label: 'Apellido paterno',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 14),

                _BifrostField(
                  controller: _apMaternoCtrl,
                  label: 'Apellido materno',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 24),

                // ── Sección: Datos por rol ───────────────────────────────
                if (_detectedRol == 'Alumno') ...[
                  _SectionHeader(label: 'Datos de alumno'),
                  const SizedBox(height: 12),
                  _BifrostDropdown(
                    label: 'Grupo',
                    icon: Icons.group_outlined,
                    value: _selectedGrupoId,
                    items: _grupos.map((g) {
                      return DropdownMenuItem(
                        value: g['id'],
                        child: Text(g['nombre']!),
                      );
                    }).toList(),
                    validator: (v) => v == null ? 'Selecciona tu grupo' : null,
                    onChanged: (v) => setState(() => _selectedGrupoId = v),
                  ),
                  const SizedBox(height: 14),
                  _BifrostDropdown(
                    label: 'Carrera',
                    icon: Icons.school_outlined,
                    value: _selectedCarreraId,
                    items: _carreras.map((c) {
                      return DropdownMenuItem(
                        value: c['id'],
                        child: Text(
                          c['nombre']!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    validator: (v) =>
                        v == null ? 'Selecciona tu carrera' : null,
                    onChanged: (v) => setState(() => _selectedCarreraId = v),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_detectedRol == 'Docente') ...[
                  _SectionHeader(label: 'Datos de docente'),
                  const SizedBox(height: 12),
                  _BifrostField(
                    controller: _profesionCtrl,
                    label: 'Profesión / Especialidad',
                    prefixIcon: Icons.work_outline,
                    textInputAction: TextInputAction.done,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'El administrador asignará tus grupos y materias.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_detectedRol == 'Invitado') ...[
                  _SectionHeader(label: 'Datos de invitado'),
                  const SizedBox(height: 12),
                  _BifrostField(
                    controller: _organizacionCtrl,
                    label: 'Organización (opcional)',
                    prefixIcon: Icons.business_outlined,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Botón de registro ────────────────────────────────────
                _BifrostButton(
                  onPressed: regState.isLoading ? null : _submit,
                  isLoading: regState.isLoading,
                  label: 'Crear cuenta',
                ),
                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿Ya tienes cuenta? ',
                      style: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushReplacementNamed(LoginPage.routeName),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Inicia sesión',
                        style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _togglePassButton({required bool value, required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(
        value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: const Color(0xFF6B7280),
        size: 22,
      ),
      onPressed: onTap,
    );
  }
}

// ============================================================================
// Shared widgets (re-exports de login_page pattern)
// ============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFD1D5DB),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _BifrostField extends StatelessWidget {
  const _BifrostField({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.textInputAction,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF6B7280), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }
}

class _BifrostDropdown extends StatelessWidget {
  const _BifrostDropdown({
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.value,
    this.validator,
  });

  final String label;
  final IconData icon;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: const Color(0xFF1A1A2E),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        errorStyle: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _BifrostButton extends StatelessWidget {
  const _BifrostButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          disabledBackgroundColor: const Color(0xFF4C1D95),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
