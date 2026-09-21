import 'dart:typed_data';

abstract interface class ExportFileDelivery {
  Future<void> deliver({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  });
}
