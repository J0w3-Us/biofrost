import 'package:flutter/material.dart';

import 'ui/teams_page.dart';

export 'ui/teams_page.dart';

/// Rutas del módulo de equipos.
Map<String, WidgetBuilder> teamsRoutes() {
  return {
    TeamsPage.routeName: (_) => const TeamsPage(), // /teams
  };
}
