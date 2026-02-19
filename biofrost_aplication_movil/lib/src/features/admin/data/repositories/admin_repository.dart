import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../models/commands/create_carrera_command.dart';
import '../models/commands/create_group_command.dart';
import '../models/commands/create_materia_command.dart';
import '../models/commands/update_group_command.dart';
import '../models/commands/update_student_group_command.dart';
import '../models/commands/update_teacher_assignments_command.dart';
import '../models/read/carrera_read_model.dart';
import '../models/read/group_read_model.dart';
import '../models/read/materia_read_model.dart';
import '../models/read/user_read_model.dart';

// ---------------------------------------------------------------------------
// Abstract interface — desacoplado para testing/mock futuro
// ---------------------------------------------------------------------------

abstract class IAdminRepository {
  // Carreras
  Future<List<CarreraReadModel>> getCarreras();
  Future<void> createCarrera(CreateCarreraCommand cmd);
  Future<void> deleteCarrera(String id);

  // Groups
  Future<List<GroupReadModel>> getGroups();
  Future<GroupReadModel> getGroupById(String id);
  Future<void> createGroup(CreateGroupCommand cmd);
  Future<void> updateGroup(String id, UpdateGroupCommand cmd);
  Future<void> deleteGroup(String id);

  // Materias
  Future<List<MateriaReadModel>> getMaterias({String? carreraId});
  Future<List<MateriaReadModel>> getMateriasByCarrera(String carreraId);
  Future<void> createMateria(CreateMateriaCommand cmd);
  Future<void> updateMateria(String id, CreateMateriaCommand cmd);
  Future<void> deleteMateria(String id);

  // Users
  Future<List<UserReadModel>> getStudents({String? grupoId});
  Future<List<UserReadModel>> getTeachers();
  Future<void> updateStudentGroup(String userId, UpdateStudentGroupCommand cmd);
  Future<void> updateTeacherAssignments(
    String userId,
    UpdateTeacherAssignmentsCommand cmd,
  );
}

// ---------------------------------------------------------------------------
// HTTP implementation — usa ApiClient del módulo Core
// ---------------------------------------------------------------------------

class AdminRepository implements IAdminRepository {
  const AdminRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  // -------------------------------------------------------------------------
  // Carreras
  // -------------------------------------------------------------------------

  @override
  Future<List<CarreraReadModel>> getCarreras() async {
    final data = await _client.get('/api/admin/carreras') as List<dynamic>;
    return data
        .map((e) => CarreraReadModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createCarrera(CreateCarreraCommand cmd) =>
      _client.post('/api/admin/carreras', body: cmd.toJson());

  @override
  Future<void> deleteCarrera(String id) =>
      _client.delete('/api/admin/carreras/$id');

  // -------------------------------------------------------------------------
  // Groups
  // -------------------------------------------------------------------------

  @override
  Future<List<GroupReadModel>> getGroups() async {
    final data = await _client.get('/api/admin/groups') as List<dynamic>;
    return data
        .map((e) => GroupReadModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GroupReadModel> getGroupById(String id) async {
    final data =
        await _client.get('/api/admin/groups/$id') as Map<String, dynamic>;
    return GroupReadModel.fromJson(data);
  }

  @override
  Future<void> createGroup(CreateGroupCommand cmd) =>
      _client.post('/api/admin/groups', body: cmd.toJson());

  @override
  Future<void> updateGroup(String id, UpdateGroupCommand cmd) =>
      _client.put('/api/admin/groups/$id', body: cmd.toJson());

  @override
  Future<void> deleteGroup(String id) =>
      _client.delete('/api/admin/groups/$id');

  // -------------------------------------------------------------------------
  // Materias
  // -------------------------------------------------------------------------

  @override
  Future<List<MateriaReadModel>> getMaterias({String? carreraId}) async {
    final data =
        await _client.get(
              '/api/admin/materias',
              query: carreraId != null ? {'carreraId': carreraId} : null,
            )
            as List<dynamic>;
    return data
        .map((e) => MateriaReadModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MateriaReadModel>> getMateriasByCarrera(String carreraId) async {
    final data =
        await _client.get('/api/admin/materias/by-carrera/$carreraId')
            as List<dynamic>;
    return data
        .map((e) => MateriaReadModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createMateria(CreateMateriaCommand cmd) =>
      _client.post('/api/admin/materias', body: cmd.toJson());

  @override
  Future<void> updateMateria(String id, CreateMateriaCommand cmd) =>
      _client.put('/api/admin/materias/$id', body: cmd.toJson());

  @override
  Future<void> deleteMateria(String id) =>
      _client.delete('/api/admin/materias/$id');

  // -------------------------------------------------------------------------
  // Users
  // -------------------------------------------------------------------------

  @override
  Future<List<UserReadModel>> getStudents({String? grupoId}) async {
    final data =
        await _client.get(
              '/api/admin/users/students',
              query: grupoId != null ? {'grupoId': grupoId} : null,
            )
            as List<dynamic>;
    return data
        .map((e) => UserReadModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<UserReadModel>> getTeachers() async {
    final data =
        await _client.get('/api/admin/users/teachers') as List<dynamic>;
    return data
        .map((e) => UserReadModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateStudentGroup(
    String userId,
    UpdateStudentGroupCommand cmd,
  ) => _client.put('/api/admin/users/students/$userId', body: cmd.toJson());

  @override
  Future<void> updateTeacherAssignments(
    String userId,
    UpdateTeacherAssignmentsCommand cmd,
  ) => _client.put('/api/admin/users/teachers/$userId', body: cmd.toJson());
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final adminRepositoryProvider = Provider<IAdminRepository>((ref) {
  return AdminRepository(client: ref.read(apiClientProvider));
});
