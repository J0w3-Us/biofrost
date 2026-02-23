import 'package:equatable/equatable.dart';

/// ReadModel de calificación por estrellas — para mostrar el rating de un proyecto.
///
/// CQRS Query: solo lectura, optimizado para la UI.
/// Separado del modelo de escritura ([SubmitStarRatingCommand]).
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

  // ── Computed ────────────────────────────────────────────────────────

  /// Promedio formateado con un decimal, ej: "4.3".
  String get averageDisplay => average.toStringAsFixed(1);

  /// True si el usuario ya ha emitido una calificación.
  bool get hasVoted => userStars != null;

  /// Descripción textual del promedio.
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

// ── CommandModel: Votar (CQRS Command) ────────────────────────────────────

/// CommandModel para emitir una calificación de estrellas.
///
/// Endpoint futuro: POST /api/ratings
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
