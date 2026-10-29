import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// where backup files go and come from. the system's own save and open
/// pickers, so the stylist chooses the place: Downloads, Drive, a USB stick.
/// tests swap in a fake
abstract interface class BackupFiles {
  /// false when the save was cancelled
  Future<bool> save(String fileName, Uint8List bytes);

  /// the chosen file's bytes, null when cancelled
  Future<Uint8List?> open();
}

final backupFilesProvider = Provider<BackupFiles>(
  (ref) => const PickerBackupFiles(),
);

class PickerBackupFiles implements BackupFiles {
  const PickerBackupFiles();

  @override
  Future<bool> save(String fileName, Uint8List bytes) async {
    final where = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/json',
      dialogTitle: 'Save the backup',
    );
    return where != null;
  }

  @override
  Future<Uint8List?> open() async {
    // any type: some android file managers label .json files as plain
    // bytes, and a filter would hide them. the contents get checked anyway
    final file = await FilePicker.pickFile(dialogTitle: 'Open a backup');
    return file?.readAsBytes();
  }
}
