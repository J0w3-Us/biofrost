import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/features/showcase/data/project_repository.dart';
import 'package:biofrost/features/showcase/domain/models/project_read_model.dart';

/// Proyectos asociados al usuario (lider) — usados para extraer stacks y banner.
final userProjectsProvider =
    FutureProvider.family<List<ProjectReadModel>, String>((ref, userId) async {
  final repo = ref.read(projectRepositoryProvider);
  final all = await repo.getPublicProjects();
  final mine = all.where((p) => p.liderId == userId).toList();
  return mine;
});
