import 'package:flutter/widgets.dart';

import 'ui/showcase_page.dart';

/// Rutas del módulo Showcase.
class ShowcaseRoutes {
  ShowcaseRoutes._();

  static final Map<String, WidgetBuilder> routes = {
    ShowcasePage.routeName: (_) => const ShowcasePage(),
  };
}
