import 'package:flutter/material.dart';

import 'ui/admin_route_guard.dart';
import 'ui/admin_shell.dart';

/// Mapa de rutas del módulo Admin.
///
/// ## Uso (cuando se quiera habilitar)
///
/// 1. Importar este archivo en `main.dart`.
/// 2. Añadir `...adminRoutes(userRole)` dentro de `MaterialApp.routes`.
///
/// ```dart
/// import 'src/features/admin/admin_routes.dart';
///
/// MaterialApp(
///   routes: {
///     // ... otras rutas ...
///     ...adminRoutes(userRole: currentUserRole),
///   },
/// );
/// ```
///
/// Por defecto este mapa NO está registrado en la app para no exponer el
/// panel admin en la versión móvil estándar (ver docs/modules/admin.md).
Map<String, WidgetBuilder> adminRoutes({required String? userRole}) {
  return {
    AdminShell.routeName: (_) =>
        AdminRouteGuard(userRole: userRole, child: const AdminShell()),
  };
}
