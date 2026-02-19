import 'package:flutter/material.dart';

import 'ui/evaluations_page.dart';

export 'ui/evaluations_page.dart';

/// Helper para construir la ruta de evaluaciones con [projectId] opcional.
///
/// Uso estándar desde ShowcasePage / ProjectDetailPage:
/// ```dart
/// Navigator.of(context).pushNamed(
///   EvaluationsPage.routeName,
///   arguments: projectId,
/// );
/// ```
Map<String, WidgetBuilder> evaluationsRoutes() {
  return {
    EvaluationsPage.routeName: (ctx) {
      final projectId = ModalRoute.of(ctx)?.settings.arguments as String? ?? '';
      return EvaluationsPage(projectId: projectId);
    },
  };
}
