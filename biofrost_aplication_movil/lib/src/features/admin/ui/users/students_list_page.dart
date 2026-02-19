import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_users_notifier.dart';
import '../../data/models/commands/update_student_group_command.dart';
import '../../data/models/read/user_read_model.dart';

/// [Query] Lista de alumnos con opción de cambiarles el grupo.
class StudentsListPage extends ConsumerStatefulWidget {
  const StudentsListPage({super.key});

  @override
  ConsumerState<StudentsListPage> createState() => _StudentsListPageState();
}

class _StudentsListPageState extends ConsumerState<StudentsListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminUsersProvider.notifier).loadStudents(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);

    ref.listen(adminUsersProvider, (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () =>
                  ref.read(adminUsersProvider.notifier).loadStudents(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminUsersProvider.notifier).loadStudents(),
        child: state.isLoading && state.students.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.students.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text('Sin alumnos registrados.'),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.students.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _StudentCard(student: state.students[i]),
              ),
      ),
    );
  }
}

class _StudentCard extends ConsumerWidget {
  const _StudentCard({required this.student});
  final UserReadModel student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: student.fotoUrl != null
              ? NetworkImage(student.fotoUrl!)
              : null,
          child: student.fotoUrl == null
              ? Text(student.nombre[0].toUpperCase())
              : null,
        ),
        title: Text(student.nombreCompleto),
        subtitle: Text(
          '${student.matricula ?? "Sin matrícula"} · Grupo: ${student.grupoId ?? "Sin grupo"}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Cambiar grupo',
          onPressed: () => _showChangeGroupDialog(context, ref),
        ),
      ),
    );
  }

  void _showChangeGroupDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: student.grupoId ?? '');
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Cambiar grupo — ${student.nombreCompleto}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Nuevo ID de Grupo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref
                  .read(adminUsersProvider.notifier)
                  .updateStudentGroup(
                    student.id,
                    UpdateStudentGroupCommand(grupoId: ctrl.text.trim()),
                  );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
