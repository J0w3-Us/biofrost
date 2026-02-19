import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../ui/ui_kit.dart';
import '../data/models/canvas_block_model.dart';
import '../data/models/public_project_read_model.dart';

/// Pantalla de detalle de un proyecto público.
///
/// Recibe el modelo completo desde la lista (sin re-fetch adicional).
class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({super.key, required this.project});

  final PublicProjectReadModel project;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ────────────────────────────────────────────────
          _DetailSliverAppBar(project: project),

          // ── Body ───────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.lg,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Materia + Ciclo
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.book_outlined,
                        label: project.materia,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label: project.ciclo,
                      color: AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Stack tecnológico
                if (project.stackTecnologico.isNotEmpty) ...[
                  Text(
                    'Stack tecnológico',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: project.stackTecnologico
                        .map((s) => _DetailTechChip(label: s))
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Descripción
                if (project.displayDescription.isNotEmpty) ...[
                  Text(
                    'Descripción',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    project.displayDescription,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Canvas
                if (project.canvas.isNotEmpty) ...[
                  Text(
                    'Documentación del proyecto',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _CanvasView(blocks: project.canvas),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Equipo
                _TeamSection(project: project),
                const SizedBox(height: AppSpacing.lg),

                // Links
                if (project.hasRepo || project.hasDemo || project.hasVideo)
                  _LinksSection(project: project),

                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SliverAppBar
// ---------------------------------------------------------------------------

class _DetailSliverAppBar extends StatelessWidget {
  const _DetailSliverAppBar({required this.project});

  final PublicProjectReadModel project;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
        title: Text(
          project.titulo,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        background: project.hasThumbnail
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    project.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _heroGradient(project.stackTecnologico),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : _heroGradient(project.stackTecnologico),
      ),
    );
  }

  static Widget _heroGradient(List<String> stack) {
    final c = _colorFor(stack);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withValues(alpha: 0.9), AppColors.surface],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.rocket_launch_rounded,
          color: Colors.white30,
          size: 72,
        ),
      ),
    );
  }

  static Color _colorFor(List<String> stack) {
    if (stack.isEmpty) return AppColors.primary;
    final s = stack.first.toLowerCase();
    if (s.contains('flutter') || s.contains('dart')) {
      return const Color(0xFF54C5F8);
    }
    if (s.contains('react') || s.contains('next')) {
      return const Color(0xFF61DAFB);
    }
    if (s.contains('.net') || s.contains('c#') || s.contains('csharp')) {
      return const Color(0xFF512BD4);
    }
    if (s.contains('python')) return const Color(0xFF3776AB);
    if (s.contains('node') || s.contains('js')) {
      return const Color(0xFF68A063);
    }
    if (s.contains('firebase')) return const Color(0xFFFFA000);
    return AppColors.primary;
  }
}

// ---------------------------------------------------------------------------
// Canvas view
// ---------------------------------------------------------------------------

class _CanvasView extends StatelessWidget {
  const _CanvasView({required this.blocks});

  final List<CanvasBlockModel> blocks;

  @override
  Widget build(BuildContext context) {
    return BifrostCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: blocks.map((b) => _CanvasBlockWidget(block: b)).toList(),
      ),
    );
  }
}

class _CanvasBlockWidget extends StatelessWidget {
  const _CanvasBlockWidget({required this.block});

  final CanvasBlockModel block;

  @override
  Widget build(BuildContext context) {
    if (block.isDivider) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Divider(color: AppColors.border, height: 1),
      );
    }

    if (block.isMedia) {
      if (block.type == 'image') {
        final url = block.imageUrl ?? block.content;
        if (url.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                height: 80,
                color: AppColors.surfaceVariant,
                child: const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        );
      }
      // Video — mostrar URL copiable
      final url = block.content;
      if (url.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: _LinkRow(
          icon: Icons.play_circle_outline_rounded,
          label: 'Video del proyecto',
          url: url,
          color: AppColors.warning,
        ),
      );
    }

    if (block.isCode) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          block.content,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }

    if (block.isList) {
      if (block.content.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                block.content,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Text / headings / quote
    if (block.content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _verticalPadding(block.type)),
      child: Text(block.content, style: _textStyle(block.type)),
    );
  }

  double _verticalPadding(String type) {
    switch (type) {
      case 'h1':
        return AppSpacing.sm.toDouble();
      case 'h2':
      case 'h3':
        return 4;
      default:
        return 2;
    }
  }

  TextStyle _textStyle(String type) {
    switch (type) {
      case 'h1':
        return AppTextStyles.heading2.copyWith(color: AppColors.textPrimary);
      case 'h2':
        return AppTextStyles.heading3.copyWith(color: AppColors.textPrimary);
      case 'h3':
        return AppTextStyles.labelLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        );
      case 'quote':
        return AppTextStyles.body.copyWith(
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        );
      default:
        return AppTextStyles.body.copyWith(
          color: AppColors.textPrimary,
          height: 1.6,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Team section
// ---------------------------------------------------------------------------

class _TeamSection extends StatelessWidget {
  const _TeamSection({required this.project});

  final PublicProjectReadModel project;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Equipo',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        BifrostCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              BifrostListTile(
                leading: const Icon(
                  Icons.star_rounded,
                  color: AppColors.warning,
                  size: 18,
                ),
                title: project.liderNombre,
                subtitle: 'Líder del proyecto',
              ),
              const Divider(height: 1, color: AppColors.border, indent: 52),
              BifrostListTile(
                leading: const Icon(
                  Icons.groups_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                title:
                    '${project.miembrosCount} integrante${project.miembrosCount != 1 ? 's' : ''}',
                subtitle: 'Equipo total',
              ),
              if (project.docenteNombre != null) ...[
                const Divider(height: 1, color: AppColors.border, indent: 52),
                BifrostListTile(
                  leading: const Icon(
                    Icons.school_rounded,
                    color: AppColors.info,
                    size: 18,
                  ),
                  title: project.docenteNombre!,
                  subtitle: 'Docente',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Links section
// ---------------------------------------------------------------------------

class _LinksSection extends StatelessWidget {
  const _LinksSection({required this.project});

  final PublicProjectReadModel project;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enlaces',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        BifrostCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            children: [
              if (project.hasRepo)
                _LinkRow(
                  icon: Icons.code_rounded,
                  label: 'Repositorio',
                  url: project.repositorioUrl!,
                  color: AppColors.success,
                ),
              if (project.hasDemo)
                _LinkRow(
                  icon: Icons.open_in_new_rounded,
                  label: 'Demo en línea',
                  url: project.demoUrl!,
                  color: AppColors.info,
                ),
              if (project.hasVideo)
                _LinkRow(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Video del proyecto',
                  url: project.videoUrl!,
                  color: AppColors.warning,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.url,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String url;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  url,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.copy_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'URL copiada al portapapeles',
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tech chip (local — mirrors card variant)
// ---------------------------------------------------------------------------

class _DetailTechChip extends StatelessWidget {
  const _DetailTechChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info chip
// ---------------------------------------------------------------------------

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
