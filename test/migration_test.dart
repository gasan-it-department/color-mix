import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/weighing/session_repository.dart';
import 'package:colormix_studio/shared/models/weighing_session.dart';

void main() {
  test('a v1 database gets the tolerance column and keeps its rows', () async {
    // weighing_sessions the way schema 1 made it, with one session in it
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE weighing_sessions (
              id TEXT NOT NULL PRIMARY KEY,
              formula_id TEXT NULL,
              formula_name TEXT NOT NULL,
              scale_id TEXT NOT NULL,
              scale_name TEXT NOT NULL,
              current_step_index INTEGER NOT NULL DEFAULT 0,
              planned_total_dg INTEGER NOT NULL,
              measured_total_mg INTEGER NULL,
              status TEXT NOT NULL,
              started_at INTEGER NOT NULL,
              finished_at INTEGER NULL
            )''');
          raw.execute('''
            CREATE TABLE weighing_steps (
              id TEXT NOT NULL PRIMARY KEY,
              session_id TEXT NOT NULL,
              position INTEGER NOT NULL,
              ingredient_name TEXT NOT NULL,
              display_rgb INTEGER NOT NULL,
              is_developer INTEGER NOT NULL DEFAULT 0,
              target_added_dg INTEGER NOT NULL,
              target_cumulative_dg INTEGER NOT NULL,
              actual_cumulative_mg INTEGER NULL,
              actual_added_mg INTEGER NULL,
              confirmed_stable INTEGER NULL,
              confirmed_at INTEGER NULL
            )''');
          raw.execute('''
            INSERT INTO weighing_sessions (id, formula_name, scale_id,
              scale_name, planned_total_dg, measured_total_mg, status,
              started_at)
            VALUES ('old', 'Rose Gold Demo', 'sim', 'Simulated scale', 1200,
              121000, 'completed', 1793000000)''');
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(db.close);

    final s = (await SessionRepository(db).load('old'))!;
    expect(s.formulaName, 'Rose Gold Demo');
    expect(s.status, SessionStatus.completed);
    expect(s.measuredTotalMg, 121000);
    expect(s.toleranceMg, isNull);
  });
}
