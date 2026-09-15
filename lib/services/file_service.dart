import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileServiceException implements Exception {
  final String message;
  const FileServiceException(this.message);
  @override
  String toString() => message;
}

class PickedFileResult {
  final String path;
  final String fileName;
  final int sizeBytes;
  const PickedFileResult({required this.path, required this.fileName, required this.sizeBytes});
}

/// Lớp trừu tượng hóa toàn bộ thao tác file/hình ảnh để UI không phụ thuộc
/// trực tiếp vào các package cụ thể (file_picker/image_picker/open_filex/
/// share_plus). Nếu sau này đổi package, chỉ cần sửa file này.
class FileService {
  final ImagePicker _imagePicker = ImagePicker();

  static const _allowedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'webp'];

  Future<PickedFileResult?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
      );
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.single;
      if (file.path == null) return null;
      return await _persistToAppStorage(File(file.path!), file.name);
    } catch (e) {
      throw FileServiceException('Không thể chọn file: $e');
    }
  }

  Future<PickedFileResult?> pickImage() async {
    try {
      final xfile = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (xfile == null) return null;
      return await _persistToAppStorage(File(xfile.path), xfile.name);
    } catch (e) {
      throw FileServiceException('Không thể chọn ảnh: $e');
    }
  }

  Future<PickedFileResult?> takePhoto() async {
    try {
      final xfile = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (xfile == null) return null;
      return await _persistToAppStorage(File(xfile.path), xfile.name);
    } catch (e) {
      throw FileServiceException('Không thể chụp ảnh: $e');
    }
  }

  Future<PickedFileResult> _persistToAppStorage(File source, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${dir.path}/attachments');
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }
      final safeName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final destination = File('${attachmentsDir.path}/$safeName');
      final saved = await source.copy(destination.path);
      final size = await saved.length();
      return PickedFileResult(path: saved.path, fileName: fileName, sizeBytes: size);
    } catch (e) {
      throw FileServiceException('Không thể lưu file vào bộ nhớ ứng dụng: $e');
    }
  }

  Future<void> openFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw const FileServiceException(
          'Đây là dữ liệu minh họa (Demo Mode) nên file thực tế không tồn tại trên máy.',
        );
      }
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        throw FileServiceException('Không thể mở file: ${result.message}');
      }
    } on FileServiceException {
      rethrow;
    } catch (e) {
      throw FileServiceException('Không thể mở file: $e');
    }
  }

  Future<void> shareFile(String path, {String? text}) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw const FileServiceException(
          'Đây là dữ liệu minh họa (Demo Mode) nên file thực tế không tồn tại trên máy.',
        );
      }
      await Share.shareXFiles([XFile(path)], text: text);
    } on FileServiceException {
      rethrow;
    } catch (e) {
      throw FileServiceException('Không thể chia sẻ file: $e');
    }
  }

  Future<void> shareText(String text) async {
    try {
      await Share.share(text);
    } catch (e) {
      throw FileServiceException('Không thể chia sẻ nội dung: $e');
    }
  }
}
