import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_materias_notifier.dart';
import '../../data/models/read/materia_read_model.dart';
import 'materia_form_page.dart';

/// [Query] Lista de materias con acciones CRUD.
class MateriasListPage extends ConsumerStatefulWidget {
  const MateriasListPage({super.key});

  @override
  ConsumerState<MateriasListPage> createState() => _MateriasListPageState();
}

class _MateriasListPageState extends ConsumerState<MateriasListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminMateriasProvider.notifier).loadMaterias(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminMateriasProvider);

    ref.listen(adminMateriasProvider, (_, next) {
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
                  ref.read(adminMateriasProvider.notifier).loadMaterias(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(adminMateriasProvider.notifier).loadMaterias(),
        child: state.isLoading && state.materias.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.materias.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.book_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text('Sin materias registradas.'),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => ref
                          .read(adminMateriasProvider.notifier)
                          .loadMaterias(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.materias.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _MateriaCard(materia: state.materias[i]),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MateriaFormPage())),
        icon: const Icon(Icons.add),
        label: const Text('Nueva materia'),
      ),
    );
  }
}

class _MateriaCard extends ConsumerWidget {
  const _MateriaCard({required this.materia});
  final MateriaReadModel materia;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(materia.cuatrimestre.toString())),
        title: Text(materia.nombre),
        subtitle: Text(
          'Clave: ${materia.clave}${materia.esAltaPrioridad ? " · Alta prioridad" : ""}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!materia.activo)
              const Chip(label: Text('Inactiva'), padding: EdgeInsets.zero),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MateriaFormPage(existing: materia),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              color: Theme.of(context).colorScheme.error,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Eliminar materia'),
                  content: Text('¿Eliminar "${materia.nombre}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        ref
                            .read(adminMateriasProvider.notifier)
                            .deleteMateria(materia.id);
                      },
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
