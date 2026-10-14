import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class DrivePickedFile {
  const DrivePickedFile({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });
  final String name;
  final Uint8List bytes;
  final String mimeType;
  int get sizeBytes => bytes.length;
}

class DriveFilePicker {
  const DriveFilePicker();
  static const allowedExtensions = [
    'pdf',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  Future<DrivePickedFile?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) throw StateError('Không thể đọc nội dung file đã chọn.');
    final extension = (file.extension ?? '').toLowerCase();
    final mime = mimeTypeFor(extension, bytes);
    return DrivePickedFile(name: file.name, bytes: bytes, mimeType: mime);
  }

  static String mimeTypeFor(String extension, Uint8List bytes) {
    bool starts(List<int> signature) {
      if (bytes.length < signature.length) return false;
      for (var index = 0; index < signature.length; index++) {
        if (bytes[index] != signature[index]) return false;
      }
      return true;
    }

    final valid = switch (extension) {
      'pdf' => starts([0x25, 0x50, 0x44, 0x46]),
      'jpg' || 'jpeg' => starts([0xff, 0xd8, 0xff]),
      'png' => starts([0x89, 0x50, 0x4e, 0x47]),
      'webp' =>
        bytes.length >= 12 &&
            starts([0x52, 0x49, 0x46, 0x46]) &&
            bytes.sublist(8, 12).join(',') == '87,69,66,80',
      'doc' => starts([0xd0, 0xcf, 0x11, 0xe0]),
      'docx' => starts([0x50, 0x4b]),
      _ => false,
    };
    if (!valid) {
      throw StateError('Nội dung file không khớp định dạng được hỗ trợ.');
    }
    return switch (extension) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw StateError('Định dạng file không được hỗ trợ.'),
    };
  }
}
