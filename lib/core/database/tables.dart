import 'package:drift/drift.dart';

import 'package:colormix_studio/shared/models/weighing_session.dart';

// dg = decigrams (0.1 g), mg = milligrams, rgb = 0xRRGGBB

@DataClassName('FormulaRow')
class Formulas extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get targetRgb => integer()();
  TextColumn get presetId => text().nullable()();
  BoolColumn get isDemo => boolean().withDefault(const Constant(false))();
  IntColumn get totalDyeDg => integer()();
  IntColumn get developerRatioHundredths => integer().nullable()();
  IntColumn get developerVolume => integer().nullable()();
  IntColumn get developerDg => integer().withDefault(const Constant(0))();
  IntColumn get totalMixtureDg => integer()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FormulaIngredientRow')
class FormulaIngredients extends Table {
  TextColumn get id => text()();
  TextColumn get formulaId =>
      text().references(Formulas, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get name => text()();
  IntColumn get percentHundredths => integer()();
  IntColumn get requiredDg => integer()();
  IntColumn get displayRgb => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WeighingSessionRow')
class WeighingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get formulaId => text().nullable().references(
    Formulas,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get formulaName => text()();
  TextColumn get scaleId => text()();
  TextColumn get scaleName => text()();
  IntColumn get currentStepIndex => integer().withDefault(const Constant(0))();
  IntColumn get plannedTotalDg => integer()();
  IntColumn get measuredTotalMg => integer().nullable()();
  TextColumn get status => textEnum<SessionStatus>()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WeighingStepRow')
class WeighingSteps extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId =>
      text().references(WeighingSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get ingredientName => text()();
  IntColumn get displayRgb => integer()();
  BoolColumn get isDeveloper => boolean().withDefault(const Constant(false))();
  IntColumn get targetAddedDg => integer()();
  IntColumn get targetCumulativeDg => integer()();
  IntColumn get actualCumulativeMg => integer().nullable()();
  IntColumn get actualAddedMg => integer().nullable()();
  BoolColumn get confirmedStable => boolean().nullable()();
  DateTimeColumn get confirmedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SettingRow')
class AppSettingsTable extends Table {
  @override
  String get tableName => 'app_settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
