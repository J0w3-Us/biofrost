import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_materias_notifier.dart';
import '../../data/models/commands/create_materia_command.dart';
import '../../data/models/read/materia_read_model.dart';

/// Formulario crear/editar materia.
class MateriaFormPage extends ConsumerStatefulWidget {
  const MateriaFormPage({super.key, this.existing});

  final MateriaReadModel? existing;

  @override
  ConsumerState<MateriaFormPage> createState() => _MateriaFormPageState();
}

class _MateriaFormPageState extends ConsumerState<MateriaFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _claveCtrl;
  late final TextEditingController _carreraIdCtrl;
  late final TextEditingController _cuatrimestreCtrl;
  bool _esAltaPrioridad = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.existing?.nombre ?? '');
    _claveCtrl = TextEditingController(text: widget.existing?.clave ?? '');
    _carreraIdCtrl = TextEditingController(
      text: widget.existing?.carreraId ?? '',
    );
    _cuatrimestreCtrl = TextEditingController(
      text: widget.existing?.cuatrimestre.toString() ?? '',
    );
    _esAltaPrioridad = widget.existing?.esAltaPrioridad ?? false;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _claveCtrl.dispose();
    _carreraIdCtrl.dispose();
    _cuatrimestreCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final cmd = CreateMateriaCommand(
      nombre: _nombreCtrl.text.trim(),
      clave: _claveCtrl.text.trim(),
      carreraId: _carreraIdCtrl.text.trim(),
      cuatrimestre: int.tryParse(_cuatrimestreCtrl.text.trim()) ?? 1,
      esAltaPrioridad: _esAltaPrioridad,
    );

    final notifier = ref.read(adminMateriasProvider.notifier);
    if (_isEdit) {
      await notifier.updateMateria(widget.existing!.id, cmd);
    } else {
      await notifier.createMateria(cmd);
    }

    final state = ref.read(adminMateriasProvider);
    if (state.errorMessage == null && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminMateriasProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar materia' : 'Nueva materia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_nombreCtrl, 'Nombre', 'Ej: Taller de Desarrollo Móvil'),
              const SizedBox(height: 16),
              _field(_claveCtrl, 'Clave', 'Ej: DSM-401A'),
              const SizedBox(height: 16),
              _field(
                _carreraIdCtrl,
                'ID de Carrera',
                'ID de la carrera asociada',
              ),
              const SizedBox(height: 16),
              _field(
                _cuatrimestreCtrl,
                'Cuatrimestre',
                'Ej: 4',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (int.tryParse(v.trim()) == null) {
                    return 'Debe ser un número';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Alta prioridad'),
                value: _esAltaPrioridad,
                onChanged: (v) => setState(() => _esAltaPrioridad = v),
              ),
              const SizedBox(height: 24),
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
                      : Text(_isEdit ? 'Guardar cambios' : 'Crear materia'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _field(
    TextEditingController ctrl,
    String label,
    String hint, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator:
          validator ??
          (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
    );
  }
}
