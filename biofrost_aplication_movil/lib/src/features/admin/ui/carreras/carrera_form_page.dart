import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_carreras_notifier.dart';
import '../../data/models/commands/create_carrera_command.dart';

/// Formulario para crear una carrera nueva.
/// (El backend no expone PUT para carreras; solo POST y DELETE.)
class CarreraFormPage extends ConsumerStatefulWidget {
  const CarreraFormPage({super.key});

  @override
  ConsumerState<CarreraFormPage> createState() => _CarreraFormPageState();
}

class _CarreraFormPageState extends ConsumerState<CarreraFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _nivelCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _nivelCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(adminCarrerasProvider.notifier)
        .createCarrera(
          CreateCarreraCommand(
            nombre: _nombreCtrl.text.trim(),
            nivel: _nivelCtrl.text.trim(),
          ),
        );

    final state = ref.read(adminCarrerasProvider);
    if (state.errorMessage == null && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminCarrerasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva carrera')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Desarrollo de Software Multiplataforma',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nivelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nivel',
                  hintText: 'Ej: TSU, Ingeniería',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
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
                      : const Text('Crear carrera'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
