import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/services/drive_file_picker.dart';

void main() {
  test('validates supported file signatures instead of extension alone', () {
    expect(
      DriveFilePicker.mimeTypeFor(
        'pdf',
        Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d]),
      ),
      'application/pdf',
    );
    expect(
      DriveFilePicker.mimeTypeFor(
        'png',
        Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]),
      ),
      'image/png',
    );
    expect(
      () => DriveFilePicker.mimeTypeFor(
        'pdf',
        Uint8List.fromList([0x50, 0x4b, 0x03, 0x04]),
      ),
      throwsStateError,
    );
  });
}
