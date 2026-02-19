import 'package:flutter/material.dart';

import 'ui/storage_page.dart';

export 'application/storage_notifier.dart';
export 'data/models/commands/upload_file_command.dart';
export 'data/models/read/uploaded_file_read_model.dart';
export 'data/repositories/storage_repository.dart';
export 'ui/storage_page.dart';

/// Rutas del módulo de Storage.
class StorageRoutes {
  static final Map<String, WidgetBuilder> routes = {
    StoragePage.routeName: (_) => const StoragePage(),
  };
}
