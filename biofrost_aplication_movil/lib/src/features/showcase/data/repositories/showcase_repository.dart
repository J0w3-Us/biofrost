import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../models/public_project_read_model.dart';

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

abstract class IShowcaseRepository {
  /// Obtiene todos los proyectos públicos del backend.
  /// Endpoint: GET /api/projects/public
  /// No requiere autenticación.
  Future<List<PublicProjectReadModel>> getPublicProjects();
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class ShowcaseRepository implements IShowcaseRepository {
  const ShowcaseRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<PublicProjectReadModel>> getPublicProjects() async {
    final data = await _client.get('/api/projects/public');
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PublicProjectReadModel.fromJson)
          .toList();
    }
    return [];
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final showcaseRepositoryProvider = Provider<IShowcaseRepository>((ref) {
  return ShowcaseRepository(ref.read(apiClientProvider));
});
