import 'package:flutter/material.dart';

import '../../../../ui/ui_kit.dart';
import '../../data/models/member_model.dart';

/// Chip visual para un miembro del proyecto (avatar + nombre + rol).
class ProjectMemberChip extends StatelessWidget {
  const ProjectMemberChip({
    super.key,
    required this.member,
    this.isLeader = false,
    this.onRemove,
  });

  final MemberModel member;
  final bool isLeader;

  /// Si se provee, muestra un botón de eliminar (solo visible al líder).
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isLeader
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          BifrostAvatar(
            name: member.nombre,
            imageUrl: member.fotoUrl,
            size: AvatarSize.xs,
          ),
          const SizedBox(width: AppSpacing.xs),

          // Nombre + rol
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                member.nombre,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                isLeader ? 'Líder' : member.rol,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          // Botón eliminar
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
