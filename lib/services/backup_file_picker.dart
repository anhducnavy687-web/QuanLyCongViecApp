import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PickedBackupFile {
  const PickedBackupFile({
    required this.name,
    required this.size,
    required this.bytes,
  });
  final String name;
  final int size;
  final Uint8List bytes;
}

abstract class BackupFilePicker {
  Future<PickedBackupFile?> pickJson();
}

/// file_picker supplies bytes on Web and mobile; no dart:io or cloud storage.
class DeviceBackupFilePicker implements BackupFilePicker {
  const DeviceBackupFilePicker();

  @override
  Future<PickedBackupFile?> pickJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    if (file.bytes == null) {
      throw const BackupImportException('Không thể đọc nội dung file đã chọn.');
    }
    return PickedBackupFile(
      name: file.name,
      size: file.size,
      bytes: file.bytes!,
    );
  }
}

class BackupImportException implements Exception {
  const BackupImportException(this.message);
  final String message;
  @override
  String toString() => message;
}
