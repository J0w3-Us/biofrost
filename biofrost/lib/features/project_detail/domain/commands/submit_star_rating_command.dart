/// CQRS Command para emitir calificación de estrellas.

// ── Command: Votar con estrellas ──────────────────────────────────────

/// CommandModel para emitir una calificación de estrellas.
///
/// Endpoint: POST /api/projects/{id}/rate
/// Body: { userId, stars }
class SubmitStarRatingCommand {
  const SubmitStarRatingCommand({
    required this.projectId,
    required this.stars,
    required this.userId,
  });

  final String projectId;

  /// Valor de 1 a 5 estrellas.
  final int stars;
  final String userId;

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'stars': stars,
        'userId': userId,
      };
}
