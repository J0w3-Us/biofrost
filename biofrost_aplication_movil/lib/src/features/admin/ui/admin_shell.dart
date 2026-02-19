import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'groups/groups_list_page.dart';
import 'materias/materias_list_page.dart';
import 'carreras/carreras_list_page.dart';
import 'users/students_list_page.dart';
import 'users/teachers_list_page.dart';

/// Shell principal del módulo Admin.
///
/// Acceso exclusivo: rol `Admin`.
/// Por defecto esta pantalla NO está registrada en las rutas principales de la
/// app. Para habilitarla añadir la entrada correspondiente en admin_routes.dart
/// y registrarla en MaterialApp.routes.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  static const routeName = '/admin';

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _currentIndex = 0;

  final _tabs = const [
    _AdminTab(icon: Icons.group, label: 'Grupos'),
    _AdminTab(icon: Icons.book, label: 'Materias'),
    _AdminTab(icon: Icons.school, label: 'Carreras'),
    _AdminTab(icon: Icons.people, label: 'Alumnos'),
    _AdminTab(icon: Icons.person_search, label: 'Docentes'),
  ];

  final _pages = const [
    GroupsListPage(),
    MateriasListPage(),
    CarrerasListPage(),
    StudentsListPage(),
    TeachersListPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(icon: Icon(t.icon), label: t.label),
            )
            .toList(),
      ),
    );
  }
}

class _AdminTab {
  const _AdminTab({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
