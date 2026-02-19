import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../models/student_read_model.dart';
import '../models/teacher_read_model.dart';

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

abstract class ITeamsRepository {
  /// `GET /api/teams/available-students?groupId=`
  Future<List<StudentReadModel>> getAvailableStudents(String groupId);

  /// `GET /api/teams/available-teachers?groupId=`
  Future<List<TeacherReadModel>> getAvailableTeachers(String groupId);
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class TeamsRepository implements ITeamsRepository {
  const TeamsRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<StudentReadModel>> getAvailableStudents(String groupId) async {
    final data = await _client.get(
      '/api/teams/available-students?groupId=$groupId',
    );
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(StudentReadModel.fromJson)
          .toList();
    }
    return [];
  }

  @override
  Future<List<TeacherReadModel>> getAvailableTeachers(String groupId) async {
    final data = await _client.get(
      '/api/teams/available-teachers?groupId=$groupId',
    );
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(TeacherReadModel.fromJson)
          .toList();
    }
    return [];
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final teamsRepositoryProvider = Provider<ITeamsRepository>((ref) {
  return TeamsRepository(ref.read(apiClientProvider));
});
