import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:biofrost/core/cache/cache_service.dart';
import 'package:biofrost/core/errors/app_exceptions.dart';
import 'package:biofrost/core/models/project_read_model.dart';
import 'package:biofrost/core/router/app_router.dart';
import 'package:biofrost/core/services/analytics_service.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/core/widgets/ui_kit.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';
import 'package:biofrost/features/evaluations/pages/evaluation_panel.dart';
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
        // ── AppBar colapsable ───────────────────────────────────────
        SliverAppBar(
          expandedHeight: 120,
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
          ),
          actions: [
            if (project.hasVideo)
              IconButton(
                icon: const Icon(Icons.play_circle_outline_rounded,
                    color: AppTheme.textSecondary),
                tooltip: 'Ver video',
                onPressed: () {/* Abrir video en webview/url */},
              ),
            if (project.hasRepo)
              IconButton(
                icon: const Icon(Icons.code_rounded,
                    color: AppTheme.textSecondary),
                tooltip: 'Repositorio',
                onPressed: () {/* Abrir repo */},
              ),
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
              width: 40, height: 4,
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
                  width: 44, height: 44,
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
    final type = block['type'] as String? ?? 'Bloque';
    final content =
        block['content'] as String? ?? block['text'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.sp8),
      padding: const EdgeInsets.all(AppTheme.sp12),
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: AppTheme.bMD,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDisabled,
              letterSpacing: 1,
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: AppTheme.sp6),
            Text(
              content,
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
    );
  }
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
