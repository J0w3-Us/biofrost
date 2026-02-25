/// Colección de widgets atómicos reutilizables en toda la app.
///
/// Todos siguen el sistema de diseño de [AppTheme]:
/// - [BioButton]   → Botón primario / secundario
/// - [BioInput]    → Campo de texto
/// - [BioAvatar]   → Avatar de usuario (URL directa)
/// - [UserAvatar]  → Avatar inteligente: foto real o fallback de iniciales
/// - [BioChip]     → Chip de tecnología o estado
/// - [BioCard]     → Contenedor tarjeta
/// - [BioSkeleton] → Placeholder de carga
/// - [BioDivider]  → Separador con etiqueta opcional
/// - [BioErrorView]→ Vista de error con reintentar
/// - [BioEmptyView]→ Vista de lista vacía
library ui_kit;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:biofrost/core/theme/app_theme.dart';

// ── BioButton ────────────────────────────────────────────────────────────

enum BioButtonVariant { primary, secondary, ghost }

class BioButton extends StatelessWidget {
  const BioButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = BioButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onTap;
  final BioButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null || isLoading;

    Color bg, fg, border;
    switch (variant) {
      case BioButtonVariant.primary:
        bg = isDisabled ? AppTheme.surface3 : AppTheme.white;
        fg = isDisabled ? AppTheme.textDisabled : AppTheme.black;
        border = Colors.transparent;
      case BioButtonVariant.secondary:
        bg = Colors.transparent;
        fg = AppTheme.white;
        border = AppTheme.border;
      case BioButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppTheme.textSecondary;
        border = Colors.transparent;
    }

    return AnimatedOpacity(
      opacity: isDisabled && !isLoading ? 0.5 : 1,
      duration: AppTheme.animFast,
      child: Material(
        color: bg,
        borderRadius: AppTheme.bFull,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: AppTheme.bFull,
          splashColor: fg.withAlpha(20),
          highlightColor: fg.withAlpha(10),
          child: Container(
            width: width ?? double.infinity,
            height: height,
            decoration: BoxDecoration(
              borderRadius: AppTheme.bFull,
              border: Border.all(color: border),
            ),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: fg),
                        const SizedBox(width: AppTheme.sp8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: fg,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── BioInput ─────────────────────────────────────────────────────────────

class BioInput extends StatefulWidget {
  const BioInput({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
    this.autofocus = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final bool autofocus;
  final bool enabled;
  final int maxLines;
  final int? minLines;

  @override
  State<BioInput> createState() => _BioInputState();
}

class _BioInputState extends State<BioInput> {
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        labelText: widget.label,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 18, color: AppTheme.textDisabled)
            : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textDisabled,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : widget.suffixIcon,
      ),
    );
  }
}

// ── BioAvatar ────────────────────────────────────────────────────────────

class BioAvatar extends StatelessWidget {
  const BioAvatar({
    super.key,
    required this.url,
    this.size = 40,
    this.showBorder = false,
  });

  final String url;
  final double size;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            showBorder ? Border.all(color: AppTheme.border, width: 1.5) : null,
      ),
      child: ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppTheme.surface2,
            child: const Icon(Icons.person, color: AppTheme.textDisabled),
          ),
        ),
      ),
    );
  }
}

// ── UserAvatar ───────────────────────────────────────────────────────────

/// Avatar inteligente y universal.
///
/// Equivalente al componente `UserAvatar.jsx` de IntegradorHub.
/// - Si [imageUrl] es válida → muestra la foto con [CachedNetworkImage].
/// - Si la URL es nula o se rompe → genera un círculo con las iniciales del [name].
///
/// Implementa el fix documentado en docs/Historial_De_Avances_Completados.md
/// § Funcionalidad de Foto de Perfil: avatares correctos sin deformación.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.showBorder = false,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final bool showBorder;

  /// Iniciales del nombre (máximo 2 caracteres).
  String get _initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  /// Color de fondo determinista basado en el nombre.
  Color get _bgColor {
    final colors = [
      const Color(0xFF4F46E5), // Indigo
      const Color(0xFF0891B2), // Cyan
      const Color(0xFF059669), // Emerald
      const Color(0xFFD97706), // Amber
      const Color(0xFFDC2626), // Red
      const Color(0xFF7C3AED), // Violet
      const Color(0xFFDB2777), // Pink
      const Color(0xFF2563EB), // Blue
    ];
    final idx = name.isEmpty ? 0 : name.codeUnitAt(0) % colors.length;
    return colors[idx];
  }

  bool get _hasValidUrl =>
      imageUrl != null && imageUrl!.isNotEmpty && imageUrl!.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final container = _hasValidUrl
        ? CachedNetworkImage(
            imageUrl: imageUrl!,
            imageBuilder: (_, imageProvider) => DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            errorWidget: (_, __, ___) => _InitialsFallback(
              initials: _initials,
              bgColor: _bgColor,
              size: size,
            ),
            placeholder: (_, __) => _InitialsFallback(
              initials: _initials,
              bgColor: _bgColor,
              size: size,
            ),
          )
        : _InitialsFallback(
            initials: _initials,
            bgColor: _bgColor,
            size: size,
          );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            showBorder ? Border.all(color: AppTheme.border, width: 1.5) : null,
      ),
      child: ClipOval(child: container),
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  const _InitialsFallback({
    required this.initials,
    required this.bgColor,
    required this.size,
  });

  final String initials;
  final Color bgColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

// ── BioChip ──────────────────────────────────────────────────────────────

class BioChip extends StatelessWidget {
  const BioChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppTheme.animFast,
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.surface3 : AppTheme.surface2,
        borderRadius: AppTheme.bFull,
        border: Border.all(
          color: isSelected ? AppTheme.borderFocus : AppTheme.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.bFull,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.sp12,
            vertical: AppTheme.sp6,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: color ??
                  (isSelected ? AppTheme.textPrimary : AppTheme.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Badge de estado de proyecto ───────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.estado});
  final String estado;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _resolve(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppTheme.bFull,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static (Color, Color, String) _resolve(String estado) => switch (estado) {
        'Activo' => (AppTheme.badgeGreen, AppTheme.badgeGreenText, 'ACTIVO'),
        'Completado' => (
            AppTheme.badgeBlue,
            AppTheme.badgeBlueText,
            'COMPLETADO'
          ),
        _ => (AppTheme.badgeGray, AppTheme.badgeGrayText, 'BORRADOR'),
      };
}

// ── BioCard ──────────────────────────────────────────────────────────────

class BioCard extends StatelessWidget {
  const BioCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppTheme.animFast,
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTheme.bMD,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.bMD,
          splashColor: Colors.white.withAlpha(8),
          highlightColor: Colors.white.withAlpha(4),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppTheme.sp16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── BioSkeleton ───────────────────────────────────────────────────────────

class BioSkeleton extends StatefulWidget {
  const BioSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<BioSkeleton> createState() => _BioSkeletonState();
}

class _BioSkeletonState extends State<BioSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppTheme.surface2.withAlpha((_anim.value * 255).toInt()),
          borderRadius: widget.borderRadius ?? AppTheme.bSM,
        ),
      ),
    );
  }
}

// ── Skeleton de ProjectCard ───────────────────────────────────────────────

/// Skeleton placeholder para la tarjeta de proyecto (grid 2 columnas).
class ProjectCardSkeleton extends StatelessWidget {
  const ProjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BioSkeleton(
      width: double.infinity,
      height: double.infinity,
      borderRadius: AppTheme.bLG,
    );
  }
}

// ── BioErrorView ─────────────────────────────────────────────────────────

class BioErrorView extends StatelessWidget {
  const BioErrorView({
    super.key,
    required this.message,
    this.isOffline = false,
    this.onRetry,
    this.icon,
  });

  final String message;
  final bool isOffline;
  final VoidCallback? onRetry;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final resolvedIcon = icon ??
        (isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.sp32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(resolvedIcon, size: 48, color: AppTheme.textDisabled),
            const SizedBox(height: AppTheme.sp16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            if (isOffline) ...[
              const SizedBox(height: AppTheme.sp8),
              const Text(
                'Mostrando datos guardados mientras tanto',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppTheme.textDisabled,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.sp24),
              BioButton(
                label: 'Reintentar',
                onTap: onRetry,
                variant: BioButtonVariant.secondary,
                width: 140,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── BioEmptyView ──────────────────────────────────────────────────────────

class BioEmptyView extends StatelessWidget {
  const BioEmptyView({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.search_off_rounded,
  });

  final String message;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.sp32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.textDisabled),
            const SizedBox(height: AppTheme.sp16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.sp8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── BioDivider ────────────────────────────────────────────────────────────

class BioDivider extends StatelessWidget {
  const BioDivider({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return const Divider(height: 1, color: AppTheme.border);
    }
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp12),
          child: Text(
            label!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppTheme.textDisabled,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppTheme.border)),
      ],
    );
  }
}

// ── OfflineBanner ─────────────────────────────────────────────────────────

/// Banner delgado que se muestra cuando el dispositivo pierde conexión.
///
/// Se anima con [AnimatedSwitcher] para una transición suave.
/// Colocar sobre el contenido principal usando [Column] o [Stack].
///
/// ### Ejemplo
/// ```dart
/// Column(children: [
///   OfflineBanner(isOnline: ref.watch(connectivityProvider)),
///   Expanded(child: body),
/// ])
/// ```
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          SizeTransition(sizeFactor: animation, child: child),
      child: isOnline
          ? const SizedBox.shrink(key: ValueKey('online'))
          : Container(
              key: const ValueKey('offline'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: const Color(0xFFB45309), // amber-700
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Sin conexión — mostrando datos guardados',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── CacheAgeBadge ─────────────────────────────────────────────────────────

/// Badge discreto que muestra la antigüedad del último dato en caché.
///
/// Muestra "Actualizado hace X min" junto a un ícono de reloj.
/// Si [savedAt] es `null`, no renderiza nada ([SizedBox.shrink]).
///
/// ### Ejemplo
/// ```dart
/// CacheAgeBadge(savedAt: state.cachedAt)
/// ```
class CacheAgeBadge extends StatelessWidget {
  const CacheAgeBadge({super.key, required this.savedAt});

  final DateTime? savedAt;

  @override
  Widget build(BuildContext context) {
    if (savedAt == null) return const SizedBox.shrink();
    final label = _formatAge(DateTime.now().difference(savedAt!));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.access_time_rounded,
          size: 11,
          color: AppTheme.textDisabled,
        ),
        const SizedBox(width: 4),
        Text(
          'Actualizado hace $label',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppTheme.textDisabled,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  static String _formatAge(Duration age) {
    if (age.inSeconds < 60) return 'un momento';
    if (age.inMinutes < 60) return '${age.inMinutes} min';
    if (age.inHours < 24) return '${age.inHours} h';
    return '${age.inDays} d';
  }
}
