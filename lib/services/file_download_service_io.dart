import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'export_file_delivery.dart';

ExportFileDelivery createFileDownloadService() => _IoFileDownloadService();

class _IoFileDownloadService implements ExportFileDelivery {
  @override
  Future<void> deliver({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([
      XFile(file.path, mimeType: mimeType, name: fileName),
    ]);
  }
}
