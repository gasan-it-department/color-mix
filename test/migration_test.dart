import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/features/weighing/session_repository.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';
import 'package:colormix_studio/shared/models/weighing_session.dart';

// older databases built by hand the way their schema made them, with a row
// or two in each table, then opened by today's app

/// schema 1. v2 adds weighing_sessions.tolerance_mg, v3 the form columns, v4
/// the unit and densities
void createV1(void Function(String sql) exec) {
  exec('''
    CREATE TABLE formulas (
      id TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      target_rgb INTEGER NOT NULL,
      preset_id TEXT NULL,
      is_demo INTEGER NOT NULL DEFAULT 0,
      total_dye_dg INTEGER NOT NULL,
      developer_ratio_hundredths INTEGER NULL,
      developer_volume INTEGER NULL,
      developer_dg INTEGER NOT NULL DEFAULT 0,
      total_mixture_dg INTEGER NOT NULL,
      notes TEXT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )''');
  exec('''
    CREATE TABLE formula_ingredients (
      id TEXT NOT NULL PRIMARY KEY,
      formula_id TEXT NOT NULL REFERENCES formulas (id) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      name TEXT NOT NULL,
      percent_hundredths INTEGER NOT NULL,
      required_dg INTEGER NOT NULL,
      display_rgb INTEGER NOT NULL
    )''');
  exec('''
    CREATE TABLE weighing_sessions (
      id TEXT NOT NULL PRIMARY KEY,
      formula_id TEXT NULL REFERENCES formulas (id) ON DELETE SET NULL,
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
  exec('''
    CREATE TABLE weighing_steps (
      id TEXT NOT NULL PRIMARY KEY,
      session_id TEXT NOT NULL
        REFERENCES weighing_sessions (id) ON DELETE CASCADE,
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
  exec('''
    CREATE TABLE app_settings (
      key TEXT NOT NULL PRIMARY KEY,
      value TEXT NOT NULL
    )''');

  exec('''
    INSERT INTO formulas (id, name, target_rgb, total_dye_dg,
      developer_ratio_hundredths, developer_dg, total_mixture_dg,
      created_at, updated_at)
    VALUES ('f', 'Rose Gold Demo', 12021369, 600, 100, 600, 1200,
      1793000000, 1793000000)''');
  exec('''
    INSERT INTO formula_ingredients (id, formula_id, position, name,
      percent_hundredths, required_dg, display_rgb)
    VALUES ('a', 'f', 0, 'Color A', 10000, 600, 1)''');
  exec('''
    INSERT INTO weighing_sessions (id, formula_id, formula_name, scale_id,
      scale_name, planned_total_dg, measured_total_mg, status, started_at)
    VALUES ('old', 'f', 'Rose Gold Demo', 'sim', 'Simulated scale', 1200,
      121000, 'completed', 1793000000)''');
  exec('''
    INSERT INTO weighing_steps (id, session_id, position, ingredient_name,
      display_rgb, target_added_dg, target_cumulative_dg, actual_added_mg)
    VALUES ('old-0', 'old', 0, 'Color A', 1, 600, 600, 60100)''');
}

AppDatabase openOld(int version) => AppDatabase(
  NativeDatabase.memory(
    setup: (db) {
      createV1(db.execute);
      if (version >= 2) {
        db.execute(
          'ALTER TABLE weighing_sessions ADD COLUMN tolerance_mg INTEGER NULL',
        );
        db.execute('UPDATE weighing_sessions SET tolerance_mg = 300');
      }
      if (version >= 3) {
        for (final table in ['formula_ingredients', 'weighing_steps']) {
          db.execute(
            "ALTER TABLE $table ADD COLUMN form TEXT NOT NULL DEFAULT 'cream'",
          );
        }
        db.execute(
          'ALTER TABLE formulas ADD COLUMN developer_form TEXT NOT NULL '
          "DEFAULT 'cream'",
        );
      }
      db.execute('PRAGMA user_version = $version');
    },
  ),
);

void main() {
  for (final version in [1, 2, 3]) {
    test('a v$version database opens with everything kept, forms as cream, '
        'grams', () async {
      final db = openOld(version);
      addTearDown(db.close);

      final s = (await SessionRepository(db).load('old'))!;
      expect(s.formulaName, 'Rose Gold Demo');
      expect(s.status, SessionStatus.completed);
      expect(s.measuredTotalMg, 121000);
      // v1 never recorded a tolerance, v2 did
      expect(s.toleranceMg, version == 1 ? isNull : 300);
      expect(s.steps.single.actualAddedMg, 60100);
      expect(s.steps.single.form, ProductForm.cream);

      final f = (await FormulaRepository(db).find('f'))!;
      expect(f.ingredients.single.form, ProductForm.cream);
      expect(f.developerForm, ProductForm.cream);
      expect(f.unit, MeasureUnit.g);
      expect(f.ingredients.single.densityMilli, isNull);
      expect(f.developerDensityMilli, isNull);

      // and the new columns take a write
      await FormulaRepository(db).save(
        f.copyWith(
          ingredients: [
            f.ingredients.single.copyWith(
              form: ProductForm.powder,
              densityMilli: () => 450,
            ),
          ],
          developerForm: ProductForm.liquid,
          developerDensityMilli: () => 1010,
          unit: MeasureUnit.oz,
        ),
      );
      final again = (await FormulaRepository(db).find('f'))!;
      expect(again.ingredients.single.form, ProductForm.powder);
      expect(again.ingredients.single.densityMilli, 450);
      expect(again.developerForm, ProductForm.liquid);
      expect(again.developerDensityMilli, 1010);
      expect(again.unit, MeasureUnit.oz);
    });
  }
}
