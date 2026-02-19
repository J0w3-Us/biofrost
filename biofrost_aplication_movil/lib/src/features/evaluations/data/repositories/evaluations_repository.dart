import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../models/create_evaluation_command.dart';
import '../models/evaluation_read_model.dart';

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

abstract class IEvaluationsRepository {
  /// `GET /api/evaluations/project/{projectId}`
  Future<List<EvaluationReadModel>> getByProject(String projectId);

  /// `POST /api/Evaluations`
  Future<void> create(CreateEvaluationCommand command);
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class EvaluationsRepository implements IEvaluationsRepository {
  const EvaluationsRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<EvaluationReadModel>> getByProject(String projectId) async {
    final data = await _client.get('/api/evaluations/project/$projectId');
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(EvaluationReadModel.fromJson)
          .toList();
    }
    return [];
  }

  @override
  Future<void> create(CreateEvaluationCommand command) async {
    await _client.post('/api/Evaluations', body: command.toJson());
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final evaluationsRepositoryProvider = Provider<IEvaluationsRepository>((ref) {
  return EvaluationsRepository(ref.read(apiClientProvider));
});
