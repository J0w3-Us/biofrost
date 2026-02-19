import 'package:flutter/material.dart';

import 'ui/project_create_page.dart';
import 'ui/project_detail_page.dart';
import 'ui/projects_page.dart';

export 'ui/projects_page.dart';
export 'ui/project_detail_page.dart';
export 'ui/project_create_page.dart';

/// Registra todas las rutas del módulo de Proyectos.
///
/// Uso:
/// ```dart
/// routes: {
///   ...projectsRoutes(),
/// }
/// ```
Map<String, WidgetBuilder> projectsRoutes() {
  return {
    // /projects — lista (mi proyecto + grupo)
    ProjectsPage.routeName: (_) => const ProjectsPage(),

    // /projects/detail — recibe projectId como argument
    ProjectDetailPage.routeName: (ctx) {
      final projectId = ModalRoute.of(ctx)?.settings.arguments as String? ?? '';
      return ProjectDetailPage(projectId: projectId);
    },

    // /projects/create — formulario de creación
    ProjectCreatePage.routeName: (_) => const ProjectCreatePage(),
  };
}
