import 'package:flutter/widgets.dart';

import 'ui/profile_page.dart';

/// Rutas del módulo Profile.
class ProfileRoutes {
  ProfileRoutes._();

  static final Map<String, WidgetBuilder> routes = {
    ProfilePage.routeName: (_) => const ProfilePage(),
  };
}
