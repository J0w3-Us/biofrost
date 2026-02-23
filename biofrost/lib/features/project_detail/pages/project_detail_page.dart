import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:biofrost/core/cache/cache_service.dart';
import 'package:biofrost/core/errors/app_exceptions.dart';
import 'package:biofrost/core/models/project_read_model.dart';
import 'package:biofrost/core/router/app_router.dart';
import 'package:biofrost/core/services/analytics_service.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/core/widgets/ui_kit.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';
import 'package:biofrost/features/evaluations/pages/evaluation_panel.dart';
import 'package:biofrost/features/project_detail/widgets/comments_section.dart';
import 'package:biofrost/features/project_detail/widgets/star_rating_section.dart';
import 'package:biofrost/features/sharing/sharing.dart';
import 'package:biofrost/features/showcase/providers/projects_provider.dart';

/// Pantalla de detalle de un proyecto.
///
/// Parametrizada por [projectId] vía GoRouter path parameter.
/// Muestra: info general, equipo, stack, canvas (read-only).
/// Si el usuario es Docente: muestra [EvaluationSection].
///
/// ### Módulo 3 — funciones integradas
/// - **Caché offline**: usa [projectDetailProvider] que persiste en disco.
/// - **Analíticas**: registra la visita y el proyecto en "vistos recientemente".
/// - **Share**: botón en AppBar para compartir la URL del proyecto.
/// - **Offline banner**: indicador visual cuando no hay red.
class ProjectDetailPage extends ConsumerStatefulWidget {
  const ProjectDetailPage({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage> {
  bool _analyticsTracked = false;

  @override
  Widget build(BuildContext context) {
    final asyncProject = ref.watch(projectDetailProvider(widget.projectId));
    final isDocente = ref.watch(isDocenteProvider);

    // Registrar analíticas una sola vez al cargar el proyecto exitosamente.
    if (!_analyticsTracked) {
      asyncProject.whenData((_) {
        if (!_analyticsTracked) {
          _analyticsTracked = true;
          ref
              .read(analyticsServiceProvider)
              .trackProjectVisit(widget.projectId);
          ref.read(cacheServiceProvider).addRecentlyViewed(widget.projectId);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.surface0,
      body: asyncProject.when(
        loading: () => const _DetailSkeleton(),
        error: (e, _) => BioErrorView(
          message: e is NetworkException
              ? 'Sin conexión. El proyecto no está en caché.'
              : 'Error al cargar el proyecto.',
          isOffline: e is NetworkException,
          onRetry: () =>
              ref.invalidate(projectDetailProvider(widget.projectId)),
        ),
        data: (project) => _DetailContent(
          project: project,
          isDocente: isDocente,
        ),
      ),
    );
  }
}

// ── Contenido completo ────────────────────────────────────────────────────

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.project, required this.isDocente});
  final ProjectDetailReadModel project;
  final bool isDocente;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── AppBar colapsable con imagen del proyecto ─────────────────
        SliverAppBar(
          expandedHeight: project.hasThumbnail ? 240 : 120,
          pinned: true,
          backgroundColor: AppTheme.surface0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.go(AppRoutes.showcase),
          ),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(
                AppTheme.sp16, 0, AppTheme.sp16, AppTheme.sp16),
            title: Text(
              project.titulo,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            background: project.hasThumbnail
                ? _ProjectHero(url: project.thumbnailUrl!)
                : const _ProjectHeroPlaceholder(),
          ),
          actions: [
            // ── Botón Compartir — Módulo 5 ────────────────────────
            IconButton(
              icon: const Icon(Icons.ios_share_rounded,
                  color: AppTheme.textSecondary),
              tooltip: 'Compartir proyecto',
              onPressed: () => _SharingSheet.show(context, project),
            ),
            const SizedBox(width: AppTheme.sp8),
          ],
        ),

        // ── Contenido ──────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(AppTheme.sp16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Meta info (estado, materia, ciclo)
              _MetaRow(project: project),
              const SizedBox(height: AppTheme.sp20),

              // Descripción del proyecto (si existe)
              if (project.descripcion != null &&
                  project.descripcion!.isNotEmpty) ...[
                _Section(
                  title: 'Descripción',
                  child: Text(
                    project.descripcion!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.sp20),
              ],

              // Video Pitch
              if (project.hasVideo) ...[
                _VideoPitchCard(url: project.videoUrl!),
                const SizedBox(height: AppTheme.sp20),
              ],

              // Links externos (repo + demo)
              if (project.hasRepo || project.demoUrl != null) ...[
                _ExternalLinksRow(project: project),
                const SizedBox(height: AppTheme.sp20),
              ],

              // Stack tecnológico
              _Section(
                title: 'Stack tecnológico',
                child: _StackGrid(project.stackTecnologico),
              ),
              const SizedBox(height: AppTheme.sp20),

              // Equipo
              _Section(
                title: 'Equipo (${project.memberCount})',
                child: _TeamList(project.members),
              ),
              const SizedBox(height: AppTheme.sp20),

              // Canvas (read-only)
              if (project.canvasBlocks.isNotEmpty) ...[
                _Section(
                  title: 'Canvas del proyecto',
                  child: _CanvasViewer(blocks: project.canvasBlocks),
                ),
                const SizedBox(height: AppTheme.sp20),
              ],

              // Rating de la comunidad (visible para todos)
              const BioDivider(label: 'CALIFICACIÓN'),
              const SizedBox(height: AppTheme.sp16),
              StarRatingSection(projectId: project.id),
              const SizedBox(height: AppTheme.sp20),

              // Comentarios (visibles para todos, escribir requiere auth)
              const BioDivider(label: 'COMENTARIOS'),
              const SizedBox(height: AppTheme.sp16),
              CommentsSection(projectId: project.id),
              const SizedBox(height: AppTheme.sp20),

              // Evaluaciones (solo Docente)
              if (isDocente) ...[
                const BioDivider(label: 'EVALUACIONES'),
                const SizedBox(height: AppTheme.sp16),
                EvaluationSection(
                  projectId: project.id,
                  docenteTitularId: project.docenteId,
                ),
              ],

              const SizedBox(height: AppTheme.sp40),
            ]),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _ProjectHero — Imagen thumbnail desde Supabase Storage
// ══════════════════════════════════════════════════════════════════════════════

class _ProjectHero extends StatelessWidget {
  const _ProjectHero({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => const _ProjectHeroPlaceholder(),
          errorWidget: (_, __, ___) => const _ProjectHeroPlaceholder(),
        ),
        // Gradiente para que el título sea legible sobre la imagen
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, AppTheme.surface0],
              stops: [0.4, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectHeroPlaceholder extends StatelessWidget {
  const _ProjectHeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surface1, AppTheme.surface2],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.folder_copy_outlined,
          size: 40,
          color: AppTheme.textDisabled,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _VideoPitchCard — Video principal del proyecto
// ══════════════════════════════════════════════════════════════════════════════

class _VideoPitchCard extends StatelessWidget {
  const _VideoPitchCard({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface1,
          borderRadius: AppTheme.bLG,
          border: Border.all(color: AppTheme.border),
        ),
        padding: const EdgeInsets.all(AppTheme.sp16),
        child: Row(
          children: [
            // Thumbnail / icono play
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.play_circle_filled_rounded,
                color: AppTheme.textPrimary,
                size: 30,
              ),
            ),
            const SizedBox(width: AppTheme.sp16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Video Pitch',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _displayUrl(url),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.textDisabled,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.open_in_new_rounded,
                          size: 12, color: AppTheme.textDisabled),
                      SizedBox(width: 4),
                      Text(
                        'Reproducir',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppTheme.textDisabled,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _ExternalLinksRow — Repositorio y Demo side by side
// ══════════════════════════════════════════════════════════════════════════════

class _ExternalLinksRow extends StatelessWidget {
  const _ExternalLinksRow({required this.project});
  final ProjectDetailReadModel project;

  @override
  Widget build(BuildContext context) {
    final hasRepo = project.hasRepo;
    final hasDemo = project.demoUrl != null && project.demoUrl!.isNotEmpty;

    return Row(
      children: [
        if (hasRepo) ...[
          Expanded(
            child: _LinkCard(
              icon: Icons.code_rounded,
              label: 'Repositorio',
              url: project.repositorioUrl!,
            ),
          ),
          if (hasDemo) const SizedBox(width: AppTheme.sp8),
        ],
        if (hasDemo)
          Expanded(
            child: _LinkCard(
              icon: Icons.public_rounded,
              label: 'Demo',
              url: project.demoUrl!,
            ),
          ),
      ],
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.icon,
    required this.label,
    required this.url,
  });
  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.sp12, vertical: AppTheme.sp12),
        decoration: BoxDecoration(
          color: AppTheme.surface1,
          borderRadius: AppTheme.bMD,
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: AppTheme.sp8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    _displayUrl(url),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppTheme.textDisabled,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: AppTheme.textDisabled),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _SharingSheet — Módulo 5: menú de opciones de sharing
// ══════════════════════════════════════════════════════════════════════════════

class _SharingSheet extends StatelessWidget {
  const _SharingSheet({required this.project});
  final ProjectDetailReadModel project;

  static Future<void> show(
    BuildContext context,
    ProjectDetailReadModel project,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SharingSheet(project: project),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Compartir proyecto',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            project.titulo,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),

          // ── Opciones ─────────────────────────────────────────────────────
          _ShareOption(
            icon: Icons.link_rounded,
            title: 'Compartir link',
            subtitle: 'WhatsApp, LinkedIn, correo...',
            onTap: () {
              Navigator.pop(context);
              SharingService.shareProjectLink(project);
            },
          ),
          _ShareOption(
            icon: Icons.qr_code_rounded,
            title: 'Código QR',
            subtitle: 'Genera y guarda el QR del proyecto',
            onTap: () {
              Navigator.pop(context);
              QrModal.show(context, project: project);
            },
          ),
          _ShareOption(
            icon: Icons.image_rounded,
            title: 'Tarjeta como imagen',
            subtitle: 'Guarda o comparte la tarjeta en PNG',
            onTap: () {
              Navigator.pop(context);
              ProjectCardCapture.show(context, project: project);
            },
          ),
          _ShareOption(
            icon: Icons.picture_as_pdf_rounded,
            title: 'Exportar PDF',
            subtitle: 'One-Pager con QR, equipo y stack',
            onTap: () {
              Navigator.pop(context);
              ProjectPdfExporter.exportAndShare(context, project);
            },
            isLast: true,
          ),
        ],
      ),
    );
  }
}

// ── Opción individual del sharing sheet ──────────────────────────────────────

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Icon(icon, color: AppTheme.textPrimary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textDisabled,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            color: AppTheme.border.withValues(alpha: 0.5),
            height: 1,
          ),
      ],
    );
  }
}

// ── Subsecciones de detalle ───────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.project});
  final ProjectDetailReadModel project;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.sp8,
      runSpacing: AppTheme.sp8,
      children: [
        StatusBadge(estado: project.estado),
        if (project.materia.isNotEmpty) _MetaChip(project.materia),
        if (project.ciclo != null) _MetaChip(project.ciclo!),
        if (project.puntosTotales != null)
          _MetaChip('${project.puntosTotales} pts', icon: Icons.star_rounded),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.label, {this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: AppTheme.bFull,
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: AppTheme.textDisabled),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDisabled,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppTheme.sp12),
        child,
      ],
    );
  }
}

class _StackGrid extends StatelessWidget {
  const _StackGrid(this.stack);
  final List<String> stack;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.sp8,
      runSpacing: AppTheme.sp8,
      children: stack.map((tech) => BioChip(label: tech)).toList(),
    );
  }
}

class _TeamList extends StatelessWidget {
  const _TeamList(this.members);
  final List<ProjectMemberReadModel> members;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: members.map((m) => _MemberTile(m)).toList(),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile(this.member);
  final ProjectMemberReadModel member;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sp8),
      child: Row(
        children: [
          BioAvatar(url: member.avatarUrl, size: 36),
          const SizedBox(width: AppTheme.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.nombre,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (member.matricula != null)
                  Text(
                    member.matricula!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppTheme.textDisabled,
                    ),
                  ),
              ],
            ),
          ),
          if (member.esLider)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surface3,
                borderRadius: AppTheme.bFull,
                border: Border.all(color: AppTheme.borderFocus),
              ),
              child: const Text(
                'LÍDER',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Canvas en modo solo-lectura.
/// Muestra cada bloque como una card con tipo y contenido.
class _CanvasViewer extends StatelessWidget {
  const _CanvasViewer({required this.blocks});
  final List<Map<String, dynamic>> blocks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: blocks.map((block) => _CanvasBlock(block)).toList(),
    );
  }
}

class _CanvasBlock extends StatelessWidget {
  const _CanvasBlock(this.block);
  final Map<String, dynamic> block;

  @override
  Widget build(BuildContext context) {
    final type = block['type'] as String? ?? 'text';
    final content =
        block['content'] as String? ?? block['text'] as String? ?? '';

    switch (type) {
      // ── Encabezados ─────────────────────────────────────────────
      case 'h1':
      case 'heading':
        if (content.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding:
              const EdgeInsets.only(bottom: AppTheme.sp16, top: AppTheme.sp8),
          child: Text(
            content,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),
        );

      case 'h2':
        if (content.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding:
              const EdgeInsets.only(bottom: AppTheme.sp12, top: AppTheme.sp6),
          child: Text(
            content,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),
        );

      case 'h3':
        if (content.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding:
              const EdgeInsets.only(bottom: AppTheme.sp8, top: AppTheme.sp4),
          child: Text(
            content,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              height: 1.3,
            ),
          ),
        );

      // ── Texto cuerpo ─────────────────────────────────────────────
      case 'text':
        if (content.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.sp12),
          child: Text(
            content,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.7,
            ),
          ),
        );

      // ── Código ───────────────────────────────────────────────────
      case 'code':
        if (content.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.sp12),
          padding: const EdgeInsets.all(AppTheme.sp12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: AppTheme.bMD,
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.terminal_rounded,
                  size: 14, color: AppTheme.textDisabled),
              const SizedBox(width: AppTheme.sp8),
              Expanded(
                child: Text(
                  content,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );

      // ── Imagen ───────────────────────────────────────────────────
      case 'image':
        if (content.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.sp12),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: AppTheme.bMD,
            border: Border.all(color: AppTheme.border),
          ),
          child: CachedNetworkImage(
            imageUrl: content,
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: (_, __) => Container(
              height: 180,
              color: AppTheme.surface2,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 120,
              color: AppTheme.surface2,
              child: const Center(
                child: Icon(Icons.broken_image_rounded,
                    color: AppTheme.textDisabled, size: 32),
              ),
            ),
          ),
        );

      // ── Video en canvas ──────────────────────────────────────────
      case 'video':
        if (content.isEmpty) return const SizedBox.shrink();
        return _CanvasVideoCard(
          url: content,
          margin: const EdgeInsets.only(bottom: AppTheme.sp12),
        );

      // ── Link ─────────────────────────────────────────────────────
      case 'link':
        if (content.isEmpty) return const SizedBox.shrink();
        return _CanvasLinkCard(
          url: content,
          margin: const EdgeInsets.only(bottom: AppTheme.sp12),
        );

      // ── Fallback: cualquier otro tipo ────────────────────────────
      default:
        if (content.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.sp12),
          child: Text(
            content,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.7,
            ),
          ),
        );
    }
  }
}

// ── Card de video en canvas ───────────────────────────────────────────────

class _CanvasVideoCard extends StatelessWidget {
  const _CanvasVideoCard({required this.url, this.margin});
  final String url;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: AppTheme.bMD,
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchUrl(url),
          borderRadius: AppTheme.bMD,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.sp16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.play_circle_filled_rounded,
                    color: AppTheme.textPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.sp12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Video',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _displayUrl(url),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppTheme.textDisabled,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new_rounded,
                    size: 16, color: AppTheme.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Card de link en canvas ────────────────────────────────────────────────

class _CanvasLinkCard extends StatelessWidget {
  const _CanvasLinkCard({required this.url, this.margin});
  final String url;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: AppTheme.bMD,
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchUrl(url),
          borderRadius: AppTheme.bMD,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.sp12),
            child: Row(
              children: [
                const Icon(Icons.link_rounded,
                    size: 18, color: AppTheme.textDisabled),
                const SizedBox(width: AppTheme.sp8),
                Expanded(
                  child: Text(
                    _displayUrl(url),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.open_in_new_rounded,
                    size: 14, color: AppTheme.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers de URL ────────────────────────────────────────────────────────

Future<void> _launchUrl(String rawUrl) async {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null) return;
  if (await canLaunchUrl(uri))
    await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _displayUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null) return rawUrl;
  final host = uri.host.replaceFirst('www.', '');
  return host.isNotEmpty ? host : rawUrl;
}

// ── Skeleton de carga ─────────────────────────────────────────────────────

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.sp16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.sp16),
            BioSkeleton(width: 200, height: 28, borderRadius: AppTheme.bSM),
            const SizedBox(height: AppTheme.sp8),
            BioSkeleton(width: 140, height: 16, borderRadius: AppTheme.bSM),
            const SizedBox(height: AppTheme.sp24),
            BioSkeleton(
                width: double.infinity, height: 80, borderRadius: AppTheme.bMD),
            const SizedBox(height: AppTheme.sp16),
            BioSkeleton(
                width: double.infinity,
                height: 120,
                borderRadius: AppTheme.bMD),
          ],
        ),
      ),
    );
  }
}
