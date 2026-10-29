import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colormix_studio/core/bluetooth/scale_device.dart';
import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/features/backup/backup_file.dart';
import 'package:colormix_studio/features/backup/backup_files.dart';
import 'package:colormix_studio/features/backup/backup_repository.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/features/weighing/session_repository.dart';
import 'package:colormix_studio/features/weighing/weighing_state.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';
import 'package:colormix_studio/shared/models/weighing_session.dart';

import 'product_form_test.dart' show mixedForms;
import 'test_app.dart';

/// remembers what was saved, hands back whatever it's told to
class FakeBackupFiles implements BackupFiles {
  String? savedName;
  Uint8List? saved;
  Uint8List? toOpen;
  bool cancel = false;

  @override
  Future<bool> save(String fileName, Uint8List bytes) async {
    if (cancel) return false;
    savedName = fileName;
    saved = bytes;
    return true;
  }

  @override
  Future<Uint8List?> open() async => cancel ? null : toOpen;
}

/// mixedForms saved, plus a finished session with Color A moved on 2 g over
Future<void> seed(AppDatabase db) async {
  await FormulaRepository(db).save(mixedForms());
  final repo = SessionRepository(db);
  WeighingState net(WeighingState s, int mg) =>
      s.withReading(liveMg: 250000 + mg, stable: true, overload: false);

  var s = WeighingState.start(
    sessionId: 'sess',
    formula: mixedForms(),
    toleranceMg: 300,
    deviceName: 'ColorMix Scale',
    connection: ScaleConnectionState.connectedSupported,
    startedAt: DateTime(2026, 10, 28, 9),
  );
  await repo.start(s, scaleId: 'AA:BB');
  s = net(s, 0).zero().beginPouring();
  s = net(s, 32000).confirmStep(DateTime(2026, 10, 28, 9, 1), manual: true);
  for (final c in [50000, 62000, 122000]) {
    s = net(s, c).confirmStep(DateTime(2026, 10, 28, 9, 2));
  }
  await repo.finish(
    net(s, 122000).complete(),
    SessionStatus.completed,
    at: DateTime(2026, 10, 28, 9, 3),
  );
}

AppDatabase emptyDb() => AppDatabase(NativeDatabase.memory());

void main() {
  group('file', () {
    late AppDatabase from;
    late AppDatabase to;

    setUp(() {
      from = emptyDb();
      to = emptyDb();
    });
    tearDown(() async {
      await from.close();
      await to.close();
    });

    test('everything comes back the way it went out', () async {
      await seed(from);
      final text = encodeBackup(await BackupRepository(from).export());
      final r = await BackupRepository(to).restore(decodeBackup(text));
      expect(r.addedFormulas, 1);
      expect(r.addedSessions, 1);
      expect(r.keptFormulas + r.keptSessions, 0);

      final f = (await FormulaRepository(to).find('f'))!;
      final orig = mixedForms();
      expect(f.name, orig.name);
      expect(f.targetRgb, orig.targetRgb);
      expect(f.isDemo, orig.isDemo);
      expect(f.developerRatio, orig.developerRatio);
      expect(f.developerForm, ProductForm.liquid);
      expect(f.createdAt, orig.createdAt);
      expect(
        f.ingredients.map((i) => (i.name, i.requiredDg, i.form)),
        orig.ingredients.map((i) => (i.name, i.requiredDg, i.form)),
      );

      final s = (await SessionRepository(to).load('sess'))!;
      final was = (await SessionRepository(from).load('sess'))!;
      expect(s.formulaId, 'f');
      expect(s.status, SessionStatus.completed);
      expect(s.deviceName, 'ColorMix Scale');
      expect(s.measuredTotalMg, was.measuredTotalMg);
      expect(s.toleranceMg, 300);
      expect(s.startedAt, was.startedAt);
      expect(s.completedAt, was.completedAt);
      expect(
        s.steps.map((x) => (x.actualAddedMg, x.confirmedStable, x.form)),
        was.steps.map((x) => (x.actualAddedMg, x.confirmedStable, x.form)),
      );
    });

    test('a restore only adds, it never overwrites', () async {
      await seed(from);
      final b = decodeBackup(
        encodeBackup(await BackupRepository(from).export()),
      );

      // the same formula is already here, renamed since the backup
      await FormulaRepository(to)
          .save(mixedForms().copyWith(name: 'Rose Gold, my version'));

      var r = await BackupRepository(to).restore(b);
      expect(r.addedFormulas, 0);
      expect(r.keptFormulas, 1);
      expect(r.addedSessions, 1);
      expect(
        (await FormulaRepository(to).find('f'))!.name,
        'Rose Gold, my version',
      );

      // the same file again: nothing new
      r = await BackupRepository(to).restore(b);
      expect(r.addedFormulas + r.addedSessions, 0);
      expect(r.keptSessions, 1);
    });

    test('a session whose formula is gone keeps its record unlinked', () async {
      await seed(from);
      await FormulaRepository(from).delete('f');
      final b = decodeBackup(
        encodeBackup(await BackupRepository(from).export()),
      );
      expect(b.formulas, isEmpty);

      await BackupRepository(to).restore(b);
      final s = (await SessionRepository(to).load('sess'))!;
      expect(s.formulaId, isNull);
      expect(s.formulaName, 'Rose Gold Demo');
    });

    test('file names carry the date', () {
      expect(
        backupFileName(DateTime(2026, 3, 7, 22)),
        'colormix-backup-2026-03-07.json',
      );
    });
  });

  group('refused', () {
    Matcher says(String text) => throwsA(
      isA<BackupFormatException>().having(
        (e) => e.message,
        'message',
        contains(text),
      ),
    );

    Future<Map<String, Object?>> good() async {
      final db = emptyDb();
      await seed(db);
      final text = encodeBackup(await BackupRepository(db).export());
      await db.close();
      return jsonDecode(text) as Map<String, Object?>;
    }

    test('anything that isn\'t a backup', () {
      expect(() => decodeBackup('hello'), says('isn\'t a ColorMix'));
      expect(() => decodeBackup('{"a": 1}'), says('isn\'t a ColorMix'));
      expect(() => decodeBackup('[]'), says('isn\'t a ColorMix'));
    });

    test('a backup from a newer app', () async {
      final m = await good()
        ..['version'] = backupVersion + 1;
      expect(() => decodeBackup(jsonEncode(m)), says('newer version'));
    });

    test('a damaged formula, named', () async {
      final m = await good();
      final f = (m['formulas']! as List).single as Map<String, Object?>;
      (f['ingredients']! as List).removeLast();
      expect(
        () => decodeBackup(jsonEncode(m)),
        says('formula "Rose Gold Demo"\'s percentages don\'t add up'),
      );
    });

    test('a wrong field type, named', () async {
      final m = await good();
      final s = (m['sessions']! as List).single as Map<String, Object?>;
      s['status'] = 'done';
      expect(
        () => decodeBackup(jsonEncode(m)),
        says('the "Rose Gold Demo" session has a bad "status"'),
      );
    });
  });

  group('settings', () {
    late AppDatabase db;
    late FakeBackupFiles files;

    setUp(() {
      db = memoryDb();
      files = FakeBackupFiles();
    });
    tearDown(() => db.close());

    Future<void> openSettings(WidgetTester tester) async {
      await pumpApp(
        tester,
        db,
        size: const Size(400, 2400),
        overrides: [backupFilesProvider.overrideWithValue(files)],
      );
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
    }

    testWidgets('save, then restore on a fresh install', (tester) async {
      await tester.runAsync(() => seed(db));
      await openSettings(tester);

      await tester.tap(find.text('Save backup'));
      await tester.pumpAndSettle();
      expect(files.savedName, startsWith('colormix-backup-'));
      expect(
        find.textContaining('1 formula and 1 weighing session'),
        findsOneWidget,
      );
      final bytes = files.saved!;
      await unmountApp(tester);

      // a fresh install somewhere else
      final other = memoryDb();
      addTearDown(other.close);
      files.toOpen = bytes;
      await pumpApp(
        tester,
        other,
        size: const Size(400, 2400),
        overrides: [backupFilesProvider.overrideWithValue(files)],
      );
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();
      expect(find.text('Restore this backup?'), findsOneWidget);
      expect(find.textContaining('nothing here is changed'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
      await tester.pumpAndSettle();
      expect(
        find.text('Added 1 formula and 1 weighing session.'),
        findsOneWidget,
      );

      // it's all there
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Formulas').first);
      await tester.pumpAndSettle();
      expect(find.text('Rose Gold Demo'), findsOneWidget);

      await unmountApp(tester);
    });

    testWidgets('a wrong file says so and changes nothing', (tester) async {
      files.toOpen = Uint8List.fromList(utf8.encode('not a backup'));
      await openSettings(tester);

      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();
      expect(find.text('Restore this backup?'), findsNothing);
      expect(
        find.textContaining('isn\'t a ColorMix Studio backup'),
        findsOneWidget,
      );

      await unmountApp(tester);
    });

    testWidgets('cancelling the picker does nothing', (tester) async {
      files.cancel = true;
      await openSettings(tester);

      await tester.tap(find.text('Save backup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Saved'), findsNothing);
      expect(find.text('Restore this backup?'), findsNothing);

      await unmountApp(tester);
    });
  });
}
