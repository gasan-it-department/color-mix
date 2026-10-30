import 'dart:convert';

import 'package:colormix_studio/features/formulation/formula_math.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';
import 'package:colormix_studio/shared/models/weighing_session.dart';

// the backup file: plain json, formulas and weighing sessions in full, the
// same integer units as the database (dg, mg, hundredths). readable enough
// to check by eye, strict enough that a damaged file is refused whole
// rather than half restored

const backupFormat = 'colormix-backup';

/// bump when the shape changes, and keep reading the old ones
const backupVersion = 1;

class Backup {
  const Backup({
    required this.formulas,
    required this.sessions,
    this.exportedAt,
    this.appVersion,
  });

  final List<ColorFormula> formulas;
  final List<WeighingSession> sessions;
  final DateTime? exportedAt;
  final String? appVersion;
}

/// what's wrong with a file, worded for the stylist
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// colormix-backup-2026-10-29.json
String backupFileName(DateTime at) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'colormix-backup-${at.year}-${two(at.month)}-${two(at.day)}.json';
}

String encodeBackup(Backup b) => const JsonEncoder.withIndent('  ').convert({
  'format': backupFormat,
  'version': backupVersion,
  'app': b.appVersion,
  'exportedAt': b.exportedAt?.toUtc().toIso8601String(),
  'formulas': [for (final f in b.formulas) _formulaToJson(f)],
  'sessions': [for (final s in b.sessions) _sessionToJson(s)],
});

/// throws [BackupFormatException]
Backup decodeBackup(String text) {
  final Object? root;
  try {
    root = jsonDecode(text);
  } on FormatException {
    throw const BackupFormatException(_notOurs);
  }
  if (root is! Map<String, Object?> || root['format'] != backupFormat) {
    throw const BackupFormatException(_notOurs);
  }
  final version = root['version'];
  if (version is! int) throw const BackupFormatException(_notOurs);
  if (version > backupVersion) {
    throw const BackupFormatException(
      'This backup comes from a newer version of the app. Update the app, '
      'then restore it.',
    );
  }

  final r = _Reader(root, 'the file');
  return Backup(
    appVersion: r.optString('app'),
    exportedAt: r.optDate('exportedAt'),
    formulas: [for (final m in r.list('formulas')) _formulaFromJson(m)],
    sessions: [for (final m in r.list('sessions')) _sessionFromJson(m)],
  );
}

const _notOurs =
    'This isn\'t a ColorMix Studio backup. Pick the .json file the app '
    'saved.';

// ── formulas ───────────────────────────────────────────────

Map<String, Object?> _formulaToJson(ColorFormula f) => {
  'id': f.id,
  'name': f.name,
  'targetRgb': f.targetRgb,
  'presetId': f.presetId,
  'isDemo': f.isDemo,
  'totalDyeDg': f.totalDyeDg,
  'developerRatioHundredths': f.developerRatio?.hundredths,
  'developerVolume': f.developerVolume,
  'developerForm': f.developerForm.name,
  'developerDensityMilli': f.developerDensityMilli,
  'unit': f.unit.name,
  'developerDg': f.developerDg,
  'totalMixtureDg': f.totalMixtureDg,
  'notes': f.notes,
  'createdAt': f.createdAt.toUtc().toIso8601String(),
  'updatedAt': f.updatedAt.toUtc().toIso8601String(),
  'ingredients': [
    for (final i in f.ingredients)
      {
        'id': i.id,
        'name': i.name,
        'percentHundredths': i.percentHundredths,
        'requiredDg': i.requiredDg,
        'displayRgb': i.displayRgb,
        'form': i.form.name,
        'densityMilli': i.densityMilli,
      },
  ],
};

ColorFormula _formulaFromJson(Map<String, Object?> m) {
  final r = _Reader(m, 'a formula');
  final name = r.string('name');
  final where = 'formula "$name"';
  final ri = _Reader(m, where);

  final ingredients = [
    for (final im in ri.list('ingredients'))
      () {
        final ir = _Reader(im, where);
        return FormulaIngredient(
          id: ir.string('id'),
          name: ir.string('name'),
          percentHundredths: ir.count('percentHundredths'),
          requiredDg: ir.count('requiredDg'),
          displayRgb: ir.rgb('displayRgb'),
          form: ir.form('form'),
          densityMilli: ir.optDensity('densityMilli'),
        );
      }(),
  ];
  final ratio = ri.optCount('developerRatioHundredths');
  final f = ColorFormula(
    id: ri.string('id'),
    name: name,
    targetRgb: ri.rgb('targetRgb'),
    presetId: ri.optString('presetId'),
    isDemo: ri.boolean('isDemo'),
    ingredients: ingredients,
    totalDyeDg: ri.count('totalDyeDg'),
    developerRatio: ratio == null || ratio == 0 ? null : DeveloperRatio(ratio),
    developerVolume: ri.optCount('developerVolume'),
    developerForm: ri.form('developerForm'),
    developerDensityMilli: ri.optDensity('developerDensityMilli'),
    unit: ri.unit('unit'),
    developerDg: ri.count('developerDg'),
    totalMixtureDg: ri.count('totalMixtureDg'),
    notes: ri.optString('notes'),
    createdAt: ri.date('createdAt'),
    updatedAt: ri.date('updatedAt'),
  );

  // the same rules the editor saves by, so nothing odd gets in
  final parts = f.ingredients;
  if (parts.isEmpty || parts.length > maxParts) {
    throw BackupFormatException(_damaged('$where has ${parts.length} colors'));
  }
  if (parts.fold(0, (s, i) => s + i.percentHundredths) != fullPercent) {
    throw BackupFormatException(
      _damaged('$where\'s percentages don\'t add up to 100%'),
    );
  }
  if (parts.fold(0, (s, i) => s + i.requiredDg) != f.totalDyeDg) {
    throw BackupFormatException(
      _damaged('$where\'s weights don\'t add up to its dye amount'),
    );
  }
  if (f.totalDyeDg + f.developerDg != f.totalMixtureDg) {
    throw BackupFormatException(
      _damaged('$where\'s mixture isn\'t dye plus developer'),
    );
  }
  return f;
}

// ── sessions ───────────────────────────────────────────────

Map<String, Object?> _sessionToJson(WeighingSession s) => {
  'id': s.id,
  'formulaId': s.formulaId,
  'formulaName': s.formulaName,
  'scaleId': s.deviceId,
  'scaleName': s.deviceName,
  'currentStepIndex': s.currentStepIndex,
  'plannedTotalDg': s.plannedTotalDg,
  'measuredTotalMg': s.measuredTotalMg,
  'toleranceMg': s.toleranceMg,
  'status': s.status.name,
  'startedAt': s.startedAt.toUtc().toIso8601String(),
  'finishedAt': s.completedAt?.toUtc().toIso8601String(),
  'steps': [
    for (final x in s.steps)
      {
        'id': x.id,
        'position': x.position,
        'ingredientName': x.ingredientName,
        'displayRgb': x.displayRgb,
        'isDeveloper': x.isDeveloper,
        'form': x.form.name,
        'targetAddedDg': x.targetAddedDg,
        'targetCumulativeDg': x.targetCumulativeDg,
        'actualCumulativeMg': x.actualCumulativeMg,
        'actualAddedMg': x.actualAddedMg,
        'confirmedStable': x.confirmedStable,
        'confirmedAt': x.confirmedAt?.toUtc().toIso8601String(),
      },
  ],
};

WeighingSession _sessionFromJson(Map<String, Object?> m) {
  final r = _Reader(m, 'a weighing session');
  final where = 'the "${r.string('formulaName')}" session';
  final sr = _Reader(m, where);
  return WeighingSession(
    id: sr.string('id'),
    formulaId: sr.optString('formulaId'),
    formulaName: sr.string('formulaName'),
    deviceId: sr.string('scaleId'),
    deviceName: sr.string('scaleName'),
    currentStepIndex: sr.count('currentStepIndex'),
    plannedTotalDg: sr.count('plannedTotalDg'),
    // signed: a reading can dip under zero
    measuredTotalMg: sr.optInt('measuredTotalMg'),
    toleranceMg: sr.optCount('toleranceMg'),
    status: sr.status('status'),
    startedAt: sr.date('startedAt'),
    completedAt: sr.optDate('finishedAt'),
    steps: [
      for (final xm in sr.list('steps'))
        () {
          final xr = _Reader(xm, where);
          return WeighingStep(
            id: xr.string('id'),
            position: xr.count('position'),
            ingredientName: xr.string('ingredientName'),
            displayRgb: xr.rgb('displayRgb'),
            isDeveloper: xr.boolean('isDeveloper'),
            form: xr.form('form'),
            targetAddedDg: xr.count('targetAddedDg'),
            targetCumulativeDg: xr.count('targetCumulativeDg'),
            actualCumulativeMg: xr.optInt('actualCumulativeMg'),
            actualAddedMg: xr.optInt('actualAddedMg'),
            confirmedStable: xr.optBool('confirmedStable'),
            confirmedAt: xr.optDate('confirmedAt'),
          );
        }(),
    ],
  );
}

// ── reading safely ─────────────────────────────────────────

String _damaged(String detail) =>
    'This backup is damaged and nothing was restored: $detail.';

/// typed reads that say which formula or session was wrong
class _Reader {
  const _Reader(this.m, this.where);

  final Map<String, Object?> m;
  final String where;

  Never _bad(String key) =>
      throw BackupFormatException(_damaged('$where has a bad "$key"'));

  String string(String key) {
    final v = m[key];
    if (v is! String || v.isEmpty) _bad(key);
    return v;
  }

  String? optString(String key) {
    final v = m[key];
    if (v == null) return null;
    if (v is! String) _bad(key);
    return v;
  }

  int? optInt(String key) {
    final v = m[key];
    if (v == null) return null;
    if (v is! int) _bad(key);
    return v;
  }

  /// zero or more
  int count(String key) {
    final v = m[key];
    if (v is! int || v < 0) _bad(key);
    return v;
  }

  int? optCount(String key) {
    final v = m[key];
    if (v == null) return null;
    if (v is! int || v < 0) _bad(key);
    return v;
  }

  int rgb(String key) {
    final v = m[key];
    if (v is! int || v < 0 || v > 0xFFFFFF) _bad(key);
    return v;
  }

  bool boolean(String key) {
    final v = m[key];
    if (v is! bool) _bad(key);
    return v;
  }

  bool? optBool(String key) {
    final v = m[key];
    if (v == null) return null;
    if (v is! bool) _bad(key);
    return v;
  }

  DateTime date(String key) {
    final v = m[key];
    final d = v is String ? DateTime.tryParse(v) : null;
    if (d == null) _bad(key);
    return d.toLocal();
  }

  DateTime? optDate(String key) => m[key] == null ? null : date(key);

  ProductForm form(String key) {
    final v = ProductForm.values.asNameMap()[m[key]];
    if (v == null) _bad(key);
    return v;
  }

  /// files from before units default to grams
  MeasureUnit unit(String key) {
    if (m[key] == null) return MeasureUnit.g;
    final v = MeasureUnit.values.asNameMap()[m[key]];
    if (v == null) _bad(key);
    return v;
  }

  /// files from before densities have none, which means the usual figure
  int? optDensity(String key) {
    final v = m[key];
    if (v == null) return null;
    if (v is! int || v < minDensityMilli || v > maxDensityMilli) _bad(key);
    return v;
  }

  SessionStatus status(String key) {
    final v = SessionStatus.values.asNameMap()[m[key]];
    if (v == null) _bad(key);
    return v;
  }

  List<Map<String, Object?>> list(String key) {
    final v = m[key];
    if (v is! List || v.any((e) => e is! Map<String, Object?>)) _bad(key);
    return v.cast<Map<String, Object?>>();
  }
}
