import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/formulation/formula_seed.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';

class FormulaRepository {
  FormulaRepository(this._db);

  final AppDatabase _db;

  /// newest first. re-emits whenever a formula or ingredient changes
  Stream<List<ColorFormula>> watchAll({int? limit}) {
    final query = _db.select(_db.formulas)
      ..orderBy([
        (f) => OrderingTerm.desc(f.updatedAt),
        (f) => OrderingTerm.asc(f.name),
      ]);
    if (limit != null) query.limit(limit);

    return query.watch().asyncMap(_withIngredients);
  }

  Future<ColorFormula?> find(String id) async {
    final row = await (_db.select(
      _db.formulas,
    )..where((f) => f.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return (await _withIngredients([row])).single;
  }

  /// insert or replace, ingredients included
  Future<void> save(ColorFormula f) {
    return _db.transaction(() async {
      await _db
          .into(_db.formulas)
          .insertOnConflictUpdate(
            FormulasCompanion.insert(
              id: f.id,
              name: f.name,
              targetRgb: f.targetRgb,
              presetId: Value(f.presetId),
              isDemo: Value(f.isDemo),
              totalDyeDg: f.totalDyeDg,
              developerRatioHundredths: Value(f.developerRatio?.hundredths),
              developerVolume: Value(f.developerVolume),
              developerForm: Value(f.developerForm),
              developerDg: Value(f.developerDg),
              totalMixtureDg: f.totalMixtureDg,
              notes: Value(f.notes),
              createdAt: f.createdAt,
              updatedAt: f.updatedAt,
            ),
          );

      await (_db.delete(
        _db.formulaIngredients,
      )..where((i) => i.formulaId.equals(f.id))).go();
      await _db.batch((b) {
        b.insertAll(_db.formulaIngredients, [
          for (final (i, ing) in f.ingredients.indexed)
            FormulaIngredientsCompanion.insert(
              id: ing.id,
              formulaId: f.id,
              position: i,
              name: ing.name,
              percentHundredths: ing.percentHundredths,
              requiredDg: ing.requiredDg,
              displayRgb: ing.displayRgb,
              form: Value(ing.form),
            ),
        ]);
      });
    });
  }

  /// ingredients go with it, past sessions keep their copy
  Future<void> delete(String id) =>
      (_db.delete(_db.formulas)..where((f) => f.id.equals(id))).go();

  /// a copy with new ids, dated now, named "X (copy)" or "X (copy 2)" if
  /// that's taken. a demo stays a demo. null if the formula is gone
  Future<ColorFormula?> duplicate(String id) async {
    final f = await find(id);
    if (f == null) return null;

    final names =
        await (_db.selectOnly(_db.formulas)..addColumns([_db.formulas.name]))
            .map((r) => r.read(_db.formulas.name)!)
            .get();

    final now = clock.now();
    final copy = ColorFormula(
      id: newId(),
      name: copyName(f.name, names.toSet()),
      targetRgb: f.targetRgb,
      presetId: f.presetId,
      isDemo: f.isDemo,
      ingredients: [
        for (final i in f.ingredients)
          FormulaIngredient(
            id: newId(),
            name: i.name,
            percentHundredths: i.percentHundredths,
            requiredDg: i.requiredDg,
            displayRgb: i.displayRgb,
            form: i.form,
          ),
      ],
      totalDyeDg: f.totalDyeDg,
      developerRatio: f.developerRatio,
      developerVolume: f.developerVolume,
      developerForm: f.developerForm,
      developerDg: f.developerDg,
      totalMixtureDg: f.totalMixtureDg,
      notes: f.notes,
      createdAt: now,
      updatedAt: now,
    );
    await save(copy);
    return copy;
  }

  Future<List<ColorFormula>> _withIngredients(List<FormulaRow> rows) async {
    if (rows.isEmpty) return const [];

    final ids = rows.map((r) => r.id).toList();
    final ingredientRows =
        await (_db.select(_db.formulaIngredients)
              ..where((i) => i.formulaId.isIn(ids))
              ..orderBy([(i) => OrderingTerm.asc(i.position)]))
            .get();

    final byFormula = <String, List<FormulaIngredient>>{};
    for (final r in ingredientRows) {
      (byFormula[r.formulaId] ??= []).add(
        FormulaIngredient(
          id: r.id,
          name: r.name,
          percentHundredths: r.percentHundredths,
          requiredDg: r.requiredDg,
          displayRgb: r.displayRgb,
          form: r.form,
        ),
      );
    }

    return [
      for (final r in rows)
        ColorFormula(
          id: r.id,
          name: r.name,
          targetRgb: r.targetRgb,
          presetId: r.presetId,
          isDemo: r.isDemo,
          ingredients: byFormula[r.id] ?? const [],
          totalDyeDg: r.totalDyeDg,
          developerRatio: r.developerRatioHundredths == null
              ? null
              : DeveloperRatio(r.developerRatioHundredths!),
          developerVolume: r.developerVolume,
          developerForm: r.developerForm,
          developerDg: r.developerDg,
          totalMixtureDg: r.totalMixtureDg,
          notes: r.notes,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
        ),
    ];
  }
}

final _copySuffix = RegExp(r' \(copy(?: (\d+))?\)$');

/// "Rose Gold" -> "Rose Gold (copy)", then "(copy 2)", "(copy 3)"... copying
/// a copy counts on from the same base name
String copyName(String name, Set<String> taken) {
  final base = name.replaceFirst(_copySuffix, '');
  var candidate = '$base (copy)';
  for (var n = 2; taken.contains(candidate); n++) {
    candidate = '$base (copy $n)';
  }
  return candidate;
}
