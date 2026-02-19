import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// Campo de texto con el estilo visual estándar de Bifrost.
///
/// Wrapper reactivo sobre [TextFormField] con el tema oscuro integrado.
///
/// Ejemplo:
/// ```dart
/// BifrostInput(
///   controller: _ctrl,
///   label: 'Correo institucional',
///   prefixIcon: Icons.email_outlined,
///   keyboardType: TextInputType.emailAddress,
///   validator: (v) => v!.isEmpty ? 'Requerido' : null,
/// )
/// ```
class BifrostInput extends StatelessWidget {
  const BifrostInput({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      focusNode: focusNode,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
      cursorColor: AppColors.primary,
      decoration: _buildDecoration(),
      validator: validator,
    );
  }

  InputDecoration _buildDecoration() {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textDisabled),
      counterStyle: AppTextStyles.caption,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.textMuted, size: 20)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: enabled ? AppColors.surface : AppColors.surfaceVariant,
      border: _border(AppColors.border),
      enabledBorder: _border(AppColors.border),
      focusedBorder: _border(AppColors.borderFocus, width: 1.5),
      disabledBorder: _border(AppColors.border.withValues(alpha: 0.5)),
      errorBorder: _border(AppColors.error),
      focusedErrorBorder: _border(AppColors.error, width: 1.5),
      errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.base),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Campo de contraseña con toggle de visibilidad incorporado.
class BifrostPasswordInput extends StatefulWidget {
  const BifrostPasswordInput({
    super.key,
    required this.label,
    this.controller,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<BifrostPasswordInput> createState() => _BifrostPasswordInputState();
}

class _BifrostPasswordInputState extends State<BifrostPasswordInput> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return BifrostInput(
      controller: widget.controller,
      label: widget.label,
      obscureText: _obscure,
      prefixIcon: Icons.lock_outline,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: widget.validator,
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textMuted,
          size: 20,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
