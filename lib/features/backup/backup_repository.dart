import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/database/app_database.dart';
import 'package:colormix_studio/core/database/database_provider.dart';
import 'package:colormix_studio/features/backup/backup_file.dart';
import 'package:colormix_studio/features/saved_formulas/formula_repository.dart';
import 'package:colormix_studio/features/weighing/session_repository.dart';

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => BackupRepository(ref.watch(databaseProvider)),
);

/// what a restore did
class RestoreResult {
  const RestoreResult({
    required this.addedFormulas,
    required this.keptFormulas,
    required this.addedSessions,
    required this.keptSessions,
  });

  final int addedFormulas;

  /// already on this device, left as they were
  final int keptFormulas;
  final int addedSessions;
  final int keptSessions;
}

/// everything into one file, and back. a restore only adds: whatever is
/// already here (same id) is left alone, so restoring the same file twice,
/// or an older one, never overwrites newer work
class BackupRepository {
  BackupRepository(this._db)
    : _formulas = FormulaRepository(_db),
      _sessions = SessionRepository(_db);

  final AppDatabase _db;
  final FormulaRepository _formulas;
  final SessionRepository _sessions;

  Future<Backup> export() async => Backup(
    formulas: await _formulas.watchAll().first,
    sessions: await _sessions.watchSessions().first,
    exportedAt: clock.now(),
    appVersion: AppInfo.version,
  );

  Future<RestoreResult> restore(Backup b) {
    return _db.transaction(() async {
      final formulaIds = {
        for (final r in await _db.select(_db.formulas).get()) r.id,
      };
      final sessionIds = {
        for (final r in await _db.select(_db.weighingSessions).get()) r.id,
      };

      var addedFormulas = 0;
      for (final f in b.formulas) {
        if (formulaIds.contains(f.id)) continue;
        await _formulas.save(f);
        formulaIds.add(f.id);
        addedFormulas++;
      }

      var addedSessions = 0;
      for (final s in b.sessions) {
        if (sessionIds.contains(s.id)) continue;
        await _sessions.insertWhole(
          s,
          formulaExists:
              s.formulaId != null && formulaIds.contains(s.formulaId),
        );
        sessionIds.add(s.id);
        addedSessions++;
      }

      return RestoreResult(
        addedFormulas: addedFormulas,
        keptFormulas: b.formulas.length - addedFormulas,
        addedSessions: addedSessions,
        keptSessions: b.sessions.length - addedSessions,
      );
    });
  }
}
