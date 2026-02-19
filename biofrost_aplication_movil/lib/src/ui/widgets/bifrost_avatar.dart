import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_text_styles.dart';

// ============================================================================
// BifrostAvatar
// ============================================================================

/// Avatar de usuario con foto de red, iniciales de fallback y badge de rol.
///
/// Ejemplo:
/// ```dart
/// BifrostAvatar(
///   name: 'Ana García',
///   imageUrl: user.fotoUrl,
///   rol: user.rol,
///   size: AvatarSize.lg,
/// )
/// ```
class BifrostAvatar extends StatelessWidget {
  const BifrostAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.rol,
    this.size = AvatarSize.md,
    this.showRolDot = false,
  });

  final String name;
  final String? imageUrl;
  final String? rol;
  final AvatarSize size;
  final bool showRolDot;

  @override
  Widget build(BuildContext context) {
    final dims = _dimsFor(size);
    final initials = _initials(name);
    final rolColor = rol != null ? AppColors.forRol(rol!) : AppColors.primary;

    final avatar = Container(
      width: dims.size,
      height: dims.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceVariant,
        border: Border.all(color: AppColors.border, width: 1.5),
        image: imageUrl != null && imageUrl!.isNotEmpty
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null || imageUrl!.isEmpty
          ? Center(
              child: Text(
                initials,
                style: AppTextStyles.label.copyWith(
                  fontSize: dims.fontSize,
                  color: AppColors.textPrimary,
                ),
              ),
            )
          : null,
    );

    if (!showRolDot || rol == null) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: dims.dotSize,
            height: dims.dotSize,
            decoration: BoxDecoration(
              color: rolColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static _AvatarDims _dimsFor(AvatarSize s) => switch (s) {
    AvatarSize.xs => _AvatarDims(size: 28, fontSize: 10, dotSize: 8),
    AvatarSize.sm => _AvatarDims(size: 36, fontSize: 12, dotSize: 10),
    AvatarSize.md => _AvatarDims(size: 44, fontSize: 15, dotSize: 12),
    AvatarSize.lg => _AvatarDims(size: 56, fontSize: 18, dotSize: 14),
    AvatarSize.xl => _AvatarDims(size: 72, fontSize: 24, dotSize: 16),
  };
}

// ── AvatarSize ─────────────────────────────────────────────────────────────

enum AvatarSize { xs, sm, md, lg, xl }

class _AvatarDims {
  const _AvatarDims({
    required this.size,
    required this.fontSize,
    required this.dotSize,
  });
  final double size;
  final double fontSize;
  final double dotSize;
}
