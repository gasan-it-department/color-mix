import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/widgets/confirm_sheet.dart';
import 'package:colormix_studio/core/widgets/section_card.dart';
import 'package:colormix_studio/features/backup/backup_file.dart';
import 'package:colormix_studio/features/backup/backup_files.dart';
import 'package:colormix_studio/features/backup/backup_repository.dart';

String _count(int n, String one) => n == 1 ? '1 $one' : '$n ${one}s';

/// settings: save everything to a file, or bring a file back
class BackupCard extends ConsumerStatefulWidget {
  const BackupCard({super.key});

  @override
  ConsumerState<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<BackupCard> {
  bool _busy = false;

  /// the last outcome, stays put until the next try
  String? _note;
  bool _noteIsProblem = false;

  void _say(String text, {bool problem = false}) => setState(() {
    _note = text;
    _noteIsProblem = problem;
  });

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final b = await ref.read(backupRepositoryProvider).export();
      final name = backupFileName(clock.now());
      final saved = await ref
          .read(backupFilesProvider)
          .save(name, utf8.encode(encodeBackup(b)));
      if (!saved) return;
      _say(
        'Saved $name: ${_count(b.formulas.length, 'formula')} and '
        '${_count(b.sessions.length, 'weighing session')}.',
      );
    } catch (_) {
      _say('Couldn\'t save the backup. Try again.', problem: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(backupFilesProvider).open();
      if (bytes == null || !mounted) return;

      final Backup b;
      try {
        b = decodeBackup(utf8.decode(bytes, allowMalformed: true));
      } on BackupFormatException catch (e) {
        _say(e.message, problem: true);
        return;
      }

      final from = b.exportedAt == null
          ? ''
          : ', saved ${DateFormat.yMMMd().format(b.exportedAt!)}';
      final ok = await showConfirmSheet(
        context,
        title: 'Restore this backup?',
        message:
            'It has ${_count(b.formulas.length, 'formula')} and '
            '${_count(b.sessions.length, 'weighing session')}$from. Only '
            'what isn\'t on this device yet is added, nothing here is '
            'changed or removed.',
        confirmLabel: 'Restore',
      );
      if (!ok || !mounted) return;

      final r = await ref.read(backupRepositoryProvider).restore(b);
      final added = r.addedFormulas + r.addedSessions == 0
          ? 'Nothing new to add'
          : 'Added ${_count(r.addedFormulas, 'formula')} and '
                '${_count(r.addedSessions, 'weighing session')}';
      final kept = r.keptFormulas + r.keptSessions == 0
          ? ''
          : '. ${_count(r.keptFormulas, 'formula')} and '
                '${_count(r.keptSessions, 'session')} were already here';
      _say('$added$kept.');
    } catch (_) {
      _say(
        'Couldn\'t restore the backup, nothing was changed. Try again.',
        problem: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return SectionCard(
      title: 'Backup',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formulas and weighing history are kept on this device only. '
            'Save a backup file to keep them when you change phones or '
            'reinstall the app.',
            style: muted,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: _busy ? null : _save,
                child: const Text('Save backup'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _restore,
                child: const Text('Restore'),
              ),
            ],
          ),
          if (_note != null) ...[
            const SizedBox(height: 10),
            Text(
              _note!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _noteIsProblem ? context.status.danger : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
