// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

import 'export_file_delivery.dart';

ExportFileDelivery createFileDownloadService() => _WebFileDownloadService();

class _WebFileDownloadService implements ExportFileDelivery {
  @override
  Future<void> deliver({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    try {
      html.AnchorElement(href: url)
        ..download = fileName
        ..style.display = 'none'
        ..click();
    } finally {
      html.Url.revokeObjectUrl(url);
    }
  }
}
