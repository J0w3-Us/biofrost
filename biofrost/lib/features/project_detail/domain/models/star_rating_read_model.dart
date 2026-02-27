import 'package:equatable/equatable.dart';

/// ReadModel de calificación por estrellas — CQRS Query.
class StarRatingReadModel extends Equatable {
  const StarRatingReadModel({
    required this.projectId,
    required this.average,
    required this.totalVotes,
    this.userStars,
  });

  final String projectId;

  /// Promedio de estrellas (1.0 – 5.0).
  final double average;

  /// Cantidad total de votos emitidos.
  final int totalVotes;

  /// Estrellas que dio el usuario actual (1-5). Null si no ha votado.
  final int? userStars;

  // ── Computed ───────────────────────────────────────────────────────

  String get averageDisplay => average.toStringAsFixed(1);

  bool get hasVoted => userStars != null;

  String get averageLabel {
    if (average >= 4.5) return 'Excelente';
    if (average >= 3.5) return 'Muy bueno';
    if (average >= 2.5) return 'Bueno';
    if (average >= 1.5) return 'Regular';
    return 'Bajo';
  }

  StarRatingReadModel copyWith({
    double? average,
    int? totalVotes,
    int? userStars,
    bool clearUserStars = false,
  }) {
    return StarRatingReadModel(
      projectId: projectId,
      average: average ?? this.average,
      totalVotes: totalVotes ?? this.totalVotes,
      userStars: clearUserStars ? null : (userStars ?? this.userStars),
    );
  }

  @override
  List<Object?> get props => [projectId, average, totalVotes, userStars];
}
