import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/database/database_provider.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';

final formulaRepositoryProvider = Provider<FormulaRepository>(
  (ref) => FormulaRepository(ref.watch(databaseProvider)),
);

final formulasProvider = StreamProvider<List<ColorFormula>>(
  (ref) => ref.watch(formulaRepositoryProvider).watchAll(),
);

/// dashboard list
final recentFormulasProvider = StreamProvider<List<ColorFormula>>(
  (ref) => ref.watch(formulaRepositoryProvider).watchAll(limit: 5),
);
