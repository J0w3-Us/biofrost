import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui_kit.dart';
import '../../auth/application/auth_notifier.dart';
import '../data/models/create_project_command.dart';
import '../data/repositories/cached_projects_repository.dart';

class ProjectCreatePage extends ConsumerStatefulWidget {
  const ProjectCreatePage({super.key});

  static const routeName = '/projects/create';

  @override
  ConsumerState<ProjectCreatePage> createState() => _ProjectCreatePageState();
}

class _ProjectCreatePageState extends ConsumerState<ProjectCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _materiaCtrl = TextEditingController();
  final _materiaIdCtrl = TextEditingController();
  final _cicloCtrl = TextEditingController();
  final _stackCtrl = TextEditingController();
  final _repoCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  // Stack tecnológico acumulado
  final List<String> _stackItems = [];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _materiaCtrl.dispose();
    _materiaIdCtrl.dispose();
    _cicloCtrl.dispose();
    _stackCtrl.dispose();
    _repoCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  void _addStack() {
    final item = _stackCtrl.text.trim();
    if (item.isEmpty) return;
    setState(() {
      if (!_stackItems.contains(item)) _stackItems.add(item);
      _stackCtrl.clear();
    });
  }

  void _removeStack(String item) {
    setState(() => _stackItems.remove(item));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_stackItems.isEmpty) {
      setState(() => _errorMessage = 'Agrega al menos una tecnología');
      return;
    }

    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final command = CreateProjectCommand(
        titulo: _tituloCtrl.text.trim(),
        materia: _materiaCtrl.text.trim(),
        materiaId: _materiaIdCtrl.text.trim(),
        ciclo: _cicloCtrl.text.trim(),
        stackTecnologico: List.unmodifiable(_stackItems),
        userId: user.uid,
        userGroupId: user.grupoId ?? '',
        repositorioUrl: _repoCtrl.text.trim().isEmpty
            ? null
            : _repoCtrl.text.trim(),
        videoUrl: _videoCtrl.text.trim().isEmpty
            ? null
            : _videoCtrl.text.trim(),
      );

      await ref.read(projectsRepositoryProvider).create(command);

      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Nuevo Proyecto',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Error ─────────────────────────────────────────────────────
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── Título ────────────────────────────────────────────────────
              BifrostInput(
                label: 'Título del Proyecto',
                controller: _tituloCtrl,
                hint: 'Ej: Sistema de Gestión Académica',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Materia ───────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: BifrostInput(
                      label: 'Materia',
                      controller: _materiaCtrl,
                      hint: 'Desarrollo Móvil',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: BifrostInput(
                      label: 'ID Materia',
                      controller: _materiaIdCtrl,
                      hint: 'DSM-501',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Ciclo ─────────────────────────────────────────────────────
              BifrostInput(
                label: 'Ciclo',
                controller: _cicloCtrl,
                hint: '2024-1',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  final ok = RegExp(r'^\d{4}-\d$').hasMatch(v.trim());
                  return ok ? null : 'Formato: 2024-1';
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Stack Tecnológico ─────────────────────────────────────────
              Text(
                'Stack Tecnológico',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: BifrostInput(
                      label: 'Tecnología',
                      controller: _stackCtrl,
                      hint: 'Flutter, Firebase...',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    onPressed: _addStack,
                    icon: const Icon(
                      Icons.add_circle_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (_stackItems.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _stackItems.map((tech) {
                    return Chip(
                      label: Text(
                        tech,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      deleteIconColor: AppColors.textMuted,
                      onDeleted: () => _removeStack(tech),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              // ── Repositorio (opcional) ────────────────────────────────────
              BifrostInput(
                label: 'Repositorio URL (opcional)',
                controller: _repoCtrl,
                hint: 'https://github.com/usuario/repo',
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Video (opcional) ──────────────────────────────────────────
              BifrostInput(
                label: 'Video URL (opcional)',
                controller: _videoCtrl,
                hint: 'https://youtube.com/...',
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Botón Crear ───────────────────────────────────────────────
              BifrostButton(
                label: 'Crear Proyecto',
                icon: Icons.rocket_launch_rounded,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
