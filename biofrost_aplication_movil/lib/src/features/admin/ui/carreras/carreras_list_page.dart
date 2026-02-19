import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_carreras_notifier.dart';
import '../../data/models/read/carrera_read_model.dart';
import 'carrera_form_page.dart';

/// [Query] Lista de carreras con acciones CRUD.
class CarrerasListPage extends ConsumerStatefulWidget {
  const CarrerasListPage({super.key});

  @override
  ConsumerState<CarrerasListPage> createState() => _CarrerasListPageState();
}

class _CarrerasListPageState extends ConsumerState<CarrerasListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminCarrerasProvider.notifier).loadCarreras(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminCarrerasProvider);

    ref.listen(adminCarrerasProvider, (_, next) {
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
                  ref.read(adminCarrerasProvider.notifier).loadCarreras(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(adminCarrerasProvider.notifier).loadCarreras(),
        child: state.isLoading && state.carreras.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.carreras.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text('Sin carreras registradas.'),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => ref
                          .read(adminCarrerasProvider.notifier)
                          .loadCarreras(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.carreras.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _CarreraCard(carrera: state.carreras[i]),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CarreraFormPage())),
        icon: const Icon(Icons.add),
        label: const Text('Nueva carrera'),
      ),
    );
  }
}

class _CarreraCard extends ConsumerWidget {
  const _CarreraCard({required this.carrera});
  final CarreraReadModel carrera;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.school)),
        title: Text(carrera.nombre),
        subtitle: Text('Nivel: ${carrera.nivel}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Eliminar',
          color: Theme.of(context).colorScheme.error,
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialogCtx) => AlertDialog(
              title: const Text('Eliminar carrera'),
              content: Text('¿Eliminar "${carrera.nombre}"?'),
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
                        .read(adminCarrerasProvider.notifier)
                        .deleteCarrera(carrera.id);
                  },
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
