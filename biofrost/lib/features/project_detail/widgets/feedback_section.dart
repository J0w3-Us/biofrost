import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/core/models/comment_read_model.dart';
import 'package:biofrost/core/models/evaluation_read_model.dart';
import 'package:biofrost/core/services/connectivity_service.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/core/widgets/ui_kit.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';
import 'package:biofrost/features/evaluations/providers/evaluation_provider.dart';
import 'package:biofrost/features/project_detail/providers/comments_provider.dart';

/// Sección unificada de retroalimentación.
///
/// - Todos los usuarios autenticados: pueden publicar comentarios.
/// - Docentes: pueden alternar entre "Comentario" y "Sugerencia" (evaluación).
///
/// El feed muestra:
///   - Comentarios de la comunidad (burbujas).
///   - Evaluaciones tipo sugerencia de docentes (cards con badge).
class FeedbackSection extends ConsumerStatefulWidget {
  const FeedbackSection({
    super.key,
    required this.projectId,
    this.docenteTitularId,
  });

  final String projectId;
  final String? docenteTitularId;

  @override
  ConsumerState<FeedbackSection> createState() => _FeedbackSectionState();
}

enum _PostType { comentario, sugerencia }

class _FeedbackSectionState extends ConsumerState<FeedbackSection> {
  final _ctrl = TextEditingController();
  _PostType _type = _PostType.comentario;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();

    if (_type == _PostType.comentario) {
      final ok = await ref
          .read(commentsProvider(widget.projectId).notifier)
          .postComment(widget.projectId);
      if (ok && mounted) _ctrl.clear();
    } else {
      // Sugerencia → evaluación
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final notifier =
          ref.read(evaluationPanelProvider(widget.projectId).notifier);
      notifier.setTipo('sugerencia');
      notifier.setContenido(_ctrl.text.trim());

      final success = await notifier.submitEvaluation(
        projectId: widget.projectId,
        docenteId: user.userId,
        docenteNombre: user.nombreCompleto,
        docenteTitularId: widget.docenteTitularId,
      );
      if (success && mounted) {
        _ctrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sugerencia enviada.'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 3),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(commentsProvider(widget.projectId));
    final evalState = ref.watch(evaluationPanelProvider(widget.projectId));
    final user = ref.watch(currentUserProvider);
    final isDocente = ref.watch(isDocenteProvider);
    final isAuthenticated = user != null;
    final isOnline = ref.watch(connectivityProvider);

    final nonOfficialEvals =
        evalState.evaluations.where((e) => e.tipo != 'oficial').toList();

    final isSubmitting = (_type == _PostType.comentario)
        ? commentsState.isSubmitting
        : evalState.isSubmitting;
    final canPublish = _ctrl.text.isNotEmpty && !isSubmitting && isOnline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Encabezado ────────────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.forum_outlined,
                size: 16, color: AppTheme.textDisabled),
            const SizedBox(width: AppTheme.sp6),
            const Text(
              'Retroalimentación',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDisabled,
                letterSpacing: 0.3,
              ),
            ),
            if (!commentsState.isLoading &&
                commentsState.comments.isNotEmpty) ...[
              const SizedBox(width: AppTheme.sp8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.sp8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surface2,
                  borderRadius: AppTheme.bFull,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  '${commentsState.comments.length + (evalState.evaluations.where((e) => e.tipo != 'oficial').length)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppTheme.sp16),

        // ── Chips de tipo (solo Docentes autenticados) ────────────
        if (isDocente && isAuthenticated) ...[
          Row(
            children: [
              _TypeChip(
                label: 'Comentario',
                icon: Icons.chat_bubble_outline_rounded,
                isSelected: _type == _PostType.comentario,
                onTap: () => setState(() => _type = _PostType.comentario),
              ),
              const SizedBox(width: AppTheme.sp8),
              _TypeChip(
                label: 'Sugerencia',
                icon: Icons.lightbulb_outline_rounded,
                isSelected: _type == _PostType.sugerencia,
                onTap: () => setState(() => _type = _PostType.sugerencia),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sp12),
        ],

        // ── Campo de entrada ──────────────────────────────────────
        _InputArea(
          ctrl: _ctrl,
          isAuthenticated: isAuthenticated,
          isSubmitting: isSubmitting,
          canPublish: canPublish,
          isOnline: isOnline,
          hintText: isAuthenticated
              ? (_type == _PostType.sugerencia
                  ? 'Escribe tu sugerencia para el equipo...'
                  : 'Deja un comentario sobre este proyecto...')
              : 'Inicia sesión para comentar',
          onTextChanged: (t) {
            if (_type == _PostType.comentario) {
              ref.read(commentsProvider(widget.projectId).notifier).setDraft(t);
            }
            setState(() {}); // actualiza canPublish
          },
          onPublish: _submit,
        ),

        const SizedBox(height: AppTheme.sp24),

        // ── Feed ──────────────────────────────────────────────────
        // 1. Cargando comentarios → skeleton
        if (commentsState.isLoading)
          const _CommentsSkeleton()
        // 2. Error en comentarios → banner con retry
        else if (commentsState.hasError)
          BioErrorView(
            message: 'Error al cargar comentarios.',
            onRetry: () => ref
                .read(commentsProvider(widget.projectId).notifier)
                .reload(widget.projectId),
          )
        else ...[
          // 3. Comentarios disponibles
          if (commentsState.comments.isNotEmpty)
            ...commentsState.comments
                .map((c) => _CommentBubble(comment: c)),

          // 4. Evaluaciones/sugerencias (solo Docentes)
          if (isDocente) ...[
            if (evalState.isLoading)
              const _EvalSkeleton()
            else if (evalState.hasError)
              BioErrorView(
                message:
                    evalState.error?.message ?? 'Error al cargar evaluaciones.',
                onRetry: () => ref
                    .read(evaluationPanelProvider(widget.projectId).notifier)
                    .load(widget.projectId, forceRefresh: true),
              )
            else
              ...nonOfficialEvals.map(
                (e) => _EvalEntryCard(
                  evaluation: e,
                  projectId: widget.projectId,
                  userId: user?.userId ?? '',
                ),
              ),
          ],

          // 5. Sin contenido → un solo mensaje vacío
          if (commentsState.comments.isEmpty &&
              (!isDocente ||
                  (!evalState.isLoading &&
                      !evalState.hasError &&
                      nonOfficialEvals.isEmpty)))
            const _EmptyFeed(),
        ],
      ],
    );
  }
}

// ── Chip de tipo de publicación ───────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding:
            const EdgeInsets.symmetric(horizontal: AppTheme.sp12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.white : AppTheme.surface2,
          borderRadius: AppTheme.bFull,
          border:
              Border.all(color: isSelected ? AppTheme.white : AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppTheme.black : AppTheme.textSecondary,
            ),
            const SizedBox(width: AppTheme.sp4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.black : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Área de entrada unificada ─────────────────────────────────────────────

class _InputArea extends StatelessWidget {
  const _InputArea({
    required this.ctrl,
    required this.isAuthenticated,
    required this.isSubmitting,
    required this.canPublish,
    required this.isOnline,
    required this.hintText,
    required this.onTextChanged,
    required this.onPublish,
  });

  final TextEditingController ctrl;
  final bool isAuthenticated;
  final bool isSubmitting;
  final bool canPublish;
  final bool isOnline;
  final String hintText;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sp12),
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: AppTheme.bLG,
        border: Border.all(
          color: isAuthenticated ? AppTheme.border : AppTheme.surface3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: ctrl,
            enabled: isAuthenticated,
            maxLines: 3,
            minLines: 1,
            maxLength: 500,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.textDisabled,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
            onChanged: onTextChanged,
          ),
          if (isAuthenticated) ...[
            const SizedBox(height: AppTheme.sp8),
            Divider(color: AppTheme.border.withAlpha(80), height: 1),
            const SizedBox(height: AppTheme.sp8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${ctrl.text.trim().length}/500',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppTheme.textDisabled,
                  ),
                ),
                GestureDetector(
                  onTap: canPublish ? onPublish : null,
                  child: AnimatedOpacity(
                    opacity: canPublish ? 1.0 : 0.4,
                    duration: AppTheme.animFast,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.sp16, vertical: AppTheme.sp8),
                      decoration: BoxDecoration(
                        color: canPublish ? AppTheme.white : AppTheme.surface3,
                        borderRadius: AppTheme.bFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSubmitting)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.black,
                              ),
                            )
                          else
                            const Icon(Icons.send_rounded,
                                size: 14, color: AppTheme.black),
                          const SizedBox(width: AppTheme.sp6),
                          Text(
                            isSubmitting ? 'Enviando...' : 'Publicar',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Burbuja de comentario ─────────────────────────────────────────────────

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({required this.comment});
  final CommentReadModel comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sp12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(comment: comment),
          const SizedBox(width: AppTheme.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.userName,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: comment.isOwn
                              ? AppTheme.info
                              : AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppTheme.sp8),
                    Text(
                      comment.fechaDisplay,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppTheme.textDisabled,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.sp4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.sp12, vertical: AppTheme.sp10),
                  decoration: BoxDecoration(
                    color: comment.isOwn
                        ? AppTheme.info.withAlpha(20)
                        : AppTheme.surface1,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppTheme.radiusMD),
                      topRight: const Radius.circular(AppTheme.radiusMD),
                      bottomLeft: Radius.circular(comment.isOwn
                          ? AppTheme.radiusMD
                          : AppTheme.radiusXS),
                      bottomRight: Radius.circular(comment.isOwn
                          ? AppTheme.radiusXS
                          : AppTheme.radiusMD),
                    ),
                    border: Border.all(
                      color: comment.isOwn
                          ? AppTheme.info.withAlpha(50)
                          : AppTheme.border,
                    ),
                  ),
                  child: Text(
                    comment.text,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar ─────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.comment});
  final CommentReadModel comment;

  @override
  Widget build(BuildContext context) {
    if (comment.userAvatarUrl != null) {
      return ClipOval(
        child: Image.network(
          comment.userAvatarUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Initials(comment: comment),
        ),
      );
    }
    return _Initials(comment: comment);
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.comment});
  final CommentReadModel comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.border),
      ),
      alignment: Alignment.center,
      child: Text(
        comment.initials,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.sp16),
      child: BioEmptyView(
        message: 'Sin retroalimentación aún',
        subtitle: 'Sé el primero en dejar tu opinión sobre este proyecto.',
        icon: Icons.forum_outlined,
      ),
    );
  }
}

// ── Skeleton comentarios ──────────────────────────────────────────────────

class _CommentsSkeleton extends StatelessWidget {
  const _CommentsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.sp12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BioSkeleton(
                  width: 36,
                  height: 36,
                  borderRadius: BorderRadius.circular(18)),
              const SizedBox(width: AppTheme.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BioSkeleton(
                        width: 120, height: 13, borderRadius: AppTheme.bSM),
                    const SizedBox(height: AppTheme.sp8),
                    BioSkeleton(
                        width: double.infinity,
                        height: 48,
                        borderRadius: AppTheme.bMD),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skeleton evaluaciones ─────────────────────────────────────────────────

class _EvalSkeleton extends StatelessWidget {
  const _EvalSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.sp8),
          child: BioSkeleton(
            width: double.infinity,
            height: 80,
            borderRadius: AppTheme.bMD,
          ),
        ),
      ),
    );
  }
}

// ── Card de evaluación (sugerencia) en el feed ────────────────────────────

class _EvalEntryCard extends StatelessWidget {
  const _EvalEntryCard({
    required this.evaluation,
    required this.projectId,
    required this.userId,
  });

  final EvaluationReadModel evaluation;
  final String projectId;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.sp8),
      padding: const EdgeInsets.all(AppTheme.sp16),
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: AppTheme.bMD,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Badge de tipo ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: AppTheme.bFull,
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              evaluation.tipo.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDisabled,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.sp10),

          // ── Contenido ─────────────────────────────────────────
          Text(
            evaluation.contenido,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppTheme.sp8),

          // ── Footer: docente + fecha ───────────────────────────
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 11, color: AppTheme.textDisabled),
              const SizedBox(width: 4),
              Text(
                evaluation.docenteNombre,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppTheme.textDisabled,
                ),
              ),
              const Spacer(),
              Text(
                evaluation.fechaFormateada,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppTheme.textDisabled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
