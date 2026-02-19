import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_groups_notifier.dart';
import '../../data/models/read/group_read_model.dart';
import 'group_form_page.dart';

/// [Query] Lista de grupos con opción de crear, editar y eliminar.
class GroupsListPage extends ConsumerStatefulWidget {
  const GroupsListPage({super.key});

  @override
  ConsumerState<GroupsListPage> createState() => _GroupsListPageState();
}

class _GroupsListPageState extends ConsumerState<GroupsListPage> {
  @override
  void initState() {
    super.initState();
    // Carga inicial al montar la pantalla
    Future.microtask(() => ref.read(adminGroupsProvider.notifier).loadGroups());
  }

  void _handleFeedback(AdminGroupsState state) {
    if (state.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.successMessage!),
          backgroundColor: Colors.green,
        ),
      );
    }
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: () =>
                ref.read(adminGroupsProvider.notifier).loadGroups(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminGroupsProvider);

    ref.listen(adminGroupsProvider, (_, next) => _handleFeedback(next));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminGroupsProvider.notifier).loadGroups(),
        child: state.isLoading && state.groups.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.groups.isEmpty
            ? _EmptyState(
                onRefresh: () =>
                    ref.read(adminGroupsProvider.notifier).loadGroups(),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) => _GroupCard(group: state.groups[i]),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const GroupFormPage()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo grupo'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.group});
  final GroupReadModel group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.group)),
        title: Text(group.nombre),
        subtitle: Text(
          '${group.carrera} — ${group.turno} | ${group.cicloActivo}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!group.activo)
              const Chip(label: Text('Inactivo'), padding: EdgeInsets.zero),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GroupFormPage(existing: group),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              color: Theme.of(context).colorScheme.error,
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: Text(
          '¿Eliminar "${group.nombre}"? Esta acción es irreversible.',
        ),
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
              ref.read(adminGroupsProvider.notifier).deleteGroup(group.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_off, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Sin grupos registrados.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}
