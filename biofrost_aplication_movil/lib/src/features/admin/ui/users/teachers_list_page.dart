import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_users_notifier.dart';
import '../../data/models/read/user_read_model.dart';

/// [Query] Lista de docentes — solo visualización por ahora.
/// La edición de asignaciones es compleja (multi-select por carrera/materia/grupos)
/// y se implementará en una pantalla de detalle futura.
class TeachersListPage extends ConsumerStatefulWidget {
  const TeachersListPage({super.key});

  @override
  ConsumerState<TeachersListPage> createState() => _TeachersListPageState();
}

class _TeachersListPageState extends ConsumerState<TeachersListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminUsersProvider.notifier).loadTeachers(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);

    ref.listen(adminUsersProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () =>
                  ref.read(adminUsersProvider.notifier).loadTeachers(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminUsersProvider.notifier).loadTeachers(),
        child: state.isLoading && state.teachers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.teachers.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_search_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text('Sin docentes registrados.'),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.teachers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _TeacherCard(teacher: state.teachers[i]),
              ),
      ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  const _TeacherCard({required this.teacher});
  final UserReadModel teacher;

  @override
  Widget build(BuildContext context) {
    final asignaciones = teacher.asignaciones ?? [];
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundImage: teacher.fotoUrl != null
              ? NetworkImage(teacher.fotoUrl!)
              : null,
          child: teacher.fotoUrl == null
              ? Text(teacher.nombre[0].toUpperCase())
              : null,
        ),
        title: Text(teacher.nombreCompleto),
        subtitle: Text(teacher.email),
        children: asignaciones.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Sin asignaciones registradas.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ]
            : asignaciones
                  .map(
                    (a) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.assignment_outlined, size: 18),
                      title: Text('Materia: ${a.materiaId}'),
                      subtitle: Text(
                        'Carrera: ${a.carreraId} · Grupos: ${a.gruposIds.join(", ")}',
                      ),
                    ),
                  )
                  .toList(),
      ),
    );
  }
}
