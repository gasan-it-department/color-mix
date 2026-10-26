import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:colormix_studio/core/database/tables.dart';
import 'package:colormix_studio/shared/models/weighing_session.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Formulas,
    FormulaIngredients,
    WeighingSessions,
    WeighingSteps,
    AppSettingsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// tests pass an in-memory executor
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2: sessions keep the tolerance they were weighed with
      if (from < 2) {
        await m.addColumn(weighingSessions, weighingSessions.toleranceMg);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _open() {
    return driftDatabase(
      name: 'colormix',
      // web is only a dev preview, the files live in web/
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
