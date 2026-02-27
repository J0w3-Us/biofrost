/// CQRS Commands para el dominio de comentarios.

// ── Command: Publicar comentario ──────────────────────────────────────

/// CommandModel para publicar un nuevo comentario en un proyecto.
///
/// Persiste en Supabase tabla `comments`.
class PostCommentCommand {
  const PostCommentCommand({
    required this.projectId,
    required this.userId,
    required this.userName,
    required this.text,
    this.userAvatarUrl,
  });

  final String projectId;
  final String userId;
  final String userName;
  final String text;
  final String? userAvatarUrl;

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'userId': userId,
        'text': text,
      };
}
