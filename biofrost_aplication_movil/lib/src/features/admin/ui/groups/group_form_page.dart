import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_groups_notifier.dart';
import '../../data/models/commands/create_group_command.dart';
import '../../data/models/commands/update_group_command.dart';
import '../../data/models/read/group_read_model.dart';

/// Formulario para crear o editar un grupo.
/// Si [existing] es nulo → modo creación; de lo contrario → modo edición.
class GroupFormPage extends ConsumerStatefulWidget {
  const GroupFormPage({super.key, this.existing});

  final GroupReadModel? existing;

  @override
  ConsumerState<GroupFormPage> createState() => _GroupFormPageState();
}

class _GroupFormPageState extends ConsumerState<GroupFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _carreraCtrl;
  late final TextEditingController _turnoCtrl;
  late final TextEditingController _cicloCtrl;

  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.existing != null;
    _nombreCtrl = TextEditingController(text: widget.existing?.nombre ?? '');
    _carreraCtrl = TextEditingController(text: widget.existing?.carrera ?? '');
    _turnoCtrl = TextEditingController(text: widget.existing?.turno ?? '');
    _cicloCtrl = TextEditingController(
      text: widget.existing?.cicloActivo ?? '',
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _carreraCtrl.dispose();
    _turnoCtrl.dispose();
    _cicloCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(adminGroupsProvider.notifier);

    if (_isEdit) {
      await notifier.updateGroup(
        widget.existing!.id,
        UpdateGroupCommand(
          nombre: _nombreCtrl.text.trim(),
          carrera: _carreraCtrl.text.trim(),
          turno: _turnoCtrl.text.trim(),
          cicloActivo: _cicloCtrl.text.trim(),
        ),
      );
    } else {
      await notifier.createGroup(
        CreateGroupCommand(
          nombre: _nombreCtrl.text.trim(),
          carrera: _carreraCtrl.text.trim(),
          turno: _turnoCtrl.text.trim(),
          cicloActivo: _cicloCtrl.text.trim(),
        ),
      );
    }

    final state = ref.read(adminGroupsProvider);
    if (state.errorMessage == null && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar grupo' : 'Nuevo grupo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField(
                controller: _nombreCtrl,
                label: 'Nombre del grupo',
                hint: 'Ej: DSM-401',
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _carreraCtrl,
                label: 'Carrera',
                hint: 'Ej: Desarrollo de Software Multiplataforma',
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _turnoCtrl,
                label: 'Turno',
                hint: 'Ej: Matutino',
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _cicloCtrl,
                label: 'Ciclo activo',
                hint: 'Ej: 2025-1',
              ),
              const SizedBox(height: 32),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEdit ? 'Guardar cambios' : 'Crear grupo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
    );
  }
}
