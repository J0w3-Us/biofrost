import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/core/models/comment_read_model.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/core/widgets/ui_kit.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';
import 'package:biofrost/features/project_detail/providers/comments_provider.dart';

/// Sección de comentarios de un proyecto.
///
/// - Usuarios autenticados: pueden escribir y publicar comentarios.
/// - Visitantes: ven los comentarios existentes con campo deshabilitado.
///
/// CQRS:
/// - Query: lista de comentarios desde [commentsProvider].
/// - Command: llama a [CommentsNotifier.postComment] con optimistic update.
class CommentsSection extends ConsumerStatefulWidget {
  const CommentsSection({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commentsProvider(widget.projectId));
    final user = ref.watch(currentUserProvider);
    final isAuthenticated = user != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Encabezado ────────────────────────────────────────────
        Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 16,
              color: AppTheme.textDisabled,
            ),
            const SizedBox(width: AppTheme.sp6),
            const Text(
              'Comentarios',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDisabled,
                letterSpacing: 0.3,
              ),
            ),
            if (!state.isLoading && state.comments.isNotEmpty) ...[
              const SizedBox(width: AppTheme.sp8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.sp8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface2,
                  borderRadius: AppTheme.bFull,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  '${state.comments.length}',
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

        // ── Campo para escribir ───────────────────────────────────
        _CommentInput(
          projectId: widget.projectId,
          controller: _controller,
          isAuthenticated: isAuthenticated,
          state: state,
        ),

        const SizedBox(height: AppTheme.sp16),

        // ── Lista de comentarios ──────────────────────────────────
        if (state.isLoading)
          const _CommentsSkeleton()
        else if (state.hasError)
          BioErrorView(
            message: 'Error al cargar comentarios.',
            onRetry: () => ref
                .read(commentsProvider(widget.projectId).notifier)
                .reload(widget.projectId),
          )
        else if (state.isEmpty)
          const _EmptyComments()
        else
          ...state.comments.map(
            (c) => _CommentBubble(comment: c),
          ),
      ],
    );
  }
}

// ── Campo de entrada ──────────────────────────────────────────────────────

class _CommentInput extends ConsumerWidget {
  const _CommentInput({
    required this.projectId,
    required this.controller,
    required this.isAuthenticated,
    required this.state,
  });

  final String projectId;
  final TextEditingController controller;
  final bool isAuthenticated;
  final CommentsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            controller: controller,
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
              hintText: isAuthenticated
                  ? 'Escribe un comentario...'
                  : 'Inicia sesión para comentar',
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
            onChanged: (text) {
              ref.read(commentsProvider(projectId).notifier).setDraft(text);
            },
          ),
          if (isAuthenticated) ...[
            const SizedBox(height: AppTheme.sp8),
            Divider(color: AppTheme.border.withAlpha(80), height: 1),
            const SizedBox(height: AppTheme.sp8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${state.draftText.trim().length}/500',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppTheme.textDisabled,
                  ),
                ),
                // Botón enviar
                GestureDetector(
                  onTap: state.canSubmit
                      ? () async {
                          final ok = await ref
                              .read(commentsProvider(projectId).notifier)
                              .postComment(projectId);
                          if (ok) {
                            controller.clear();
                          }
                        }
                      : null,
                  child: AnimatedOpacity(
                    opacity: state.canSubmit ? 1.0 : 0.4,
                    duration: AppTheme.animFast,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.sp16,
                        vertical: AppTheme.sp8,
                      ),
                      decoration: BoxDecoration(
                        color: state.canSubmit
                            ? AppTheme.white
                            : AppTheme.surface3,
                        borderRadius: AppTheme.bFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.isSubmitting)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.black,
                              ),
                            )
                          else
                            const Icon(
                              Icons.send_rounded,
                              size: 14,
                              color: AppTheme.black,
                            ),
                          const SizedBox(width: AppTheme.sp6),
                          Text(
                            state.isSubmitting ? 'Enviando...' : 'Publicar',
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

// ── Burbuja individual de comentario ──────────────────────────────────────

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
          // Avatar
          _CommentAvatar(comment: comment),
          const SizedBox(width: AppTheme.sp12),

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre + fecha
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

                // Texto del comentario
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.sp12,
                    vertical: AppTheme.sp10,
                  ),
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

// ── Avatar de comentario ──────────────────────────────────────────────────

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({required this.comment});
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
          errorBuilder: (_, __, ___) => _InitialsAvatar(comment: comment),
        ),
      );
    }
    return _InitialsAvatar(comment: comment);
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.comment});
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

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.sp16),
      child: BioEmptyView(
        message: 'Sin comentarios aún',
        subtitle: 'Sé el primero en dejar tu opinión sobre este proyecto.',
        icon: Icons.chat_bubble_outline_rounded,
      ),
    );
  }
}

// ── Skeleton de carga ─────────────────────────────────────────────────────

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
