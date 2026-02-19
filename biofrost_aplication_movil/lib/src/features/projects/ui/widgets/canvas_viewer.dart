import 'package:flutter/material.dart';

import '../../../../ui/ui_kit.dart';
import '../../../showcase/data/models/canvas_block_model.dart';

/// Vista de solo lectura del canvas de un proyecto.
/// Renderiza los bloques en orden y los muestra de forma legible.
class CanvasViewer extends StatelessWidget {
  const CanvasViewer({super.key, required this.blocks});

  final List<CanvasBlockModel> blocks;

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return Center(
        child: Text(
          'Sin contenido en el canvas',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
      );
    }

    final sorted = [...blocks]..sort((a, b) => a.order.compareTo(b.order));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sorted.map((block) => _buildBlock(block)).toList(),
    );
  }

  Widget _buildBlock(CanvasBlockModel block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: switch (block.type) {
        'h1' || 'heading' => Text(
          block.content,
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
        'h2' => Text(
          block.content,
          style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
        ),
        'h3' => Text(
          block.content,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        'text' => Text(
          block.content,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        'quote' => Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.6),
                width: 3,
              ),
            ),
            color: AppColors.primary.withValues(alpha: 0.05),
          ),
          child: Text(
            block.content,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        'bullet' => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6, right: 6),
              child: Icon(Icons.circle, size: 6, color: AppColors.textMuted),
            ),
            Expanded(
              child: Text(
                block.content,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        'code' => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            block.content,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Color(0xFF89B4FA),
            ),
          ),
        ),
        'divider' => const Divider(color: AppColors.border, height: 24),
        'image' => _buildImage(block),
        'video' => _buildVideoPlaceholder(block),
        _ => Text(
          block.content,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      },
    );
  }

  Widget _buildImage(CanvasBlockModel block) {
    final url = block.imageUrl;
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 120,
          color: AppColors.surfaceVariant,
          child: const Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: AppColors.textMuted,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder(CanvasBlockModel block) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.play_circle_rounded,
            color: AppColors.textMuted,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              block.content.isNotEmpty ? block.content : 'Video',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
