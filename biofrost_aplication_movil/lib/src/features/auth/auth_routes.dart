import 'package:flutter/material.dart';

import 'ui/group_selector_page.dart';
import 'ui/login_page.dart';
import 'ui/register_page.dart';

/// Mapa de rutas del módulo Auth.
///
/// Registrar en [MaterialApp.routes]:
/// ```dart
/// routes: {
///   ...AuthRoutes.routes,
/// }
/// ```
abstract final class AuthRoutes {
  static const String login = LoginPage.routeName;
  static const String register = RegisterPage.routeName;
  static const String groupSelector = GroupSelectorPage.routeName;

  static final Map<String, WidgetBuilder> routes = {
    LoginPage.routeName: (_) => const LoginPage(),
    RegisterPage.routeName: (_) => const RegisterPage(),
    GroupSelectorPage.routeName: (_) => const GroupSelectorPage(),
  };
}
