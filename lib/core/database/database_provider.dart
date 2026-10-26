import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/database/app_database.dart';

/// opened in main() and overridden there, tests override with an in-memory db
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);
