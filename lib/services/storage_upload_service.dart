import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import 'file_service.dart';

/// Tải file đính kèm lên Firebase Storage theo đúng path chuẩn:
/// users/{uid}/profiles/{profileId}/attachments/{attachmentId}
///
/// Chỉ được gọi khi app đang ở chế độ đã đăng nhập Firebase (KHÔNG dùng ở
/// Demo Mode). Mọi lỗi được bọc lại thành [FileServiceException] với thông
/// điệp tiếng Việt để UI hiển thị thân thiện thay vì crash.
class StorageUploadService {
  Future<String> uploadAttachment({
    required String uid,
    required String profileId,
    required String attachmentId,
    required File file,
    required String fileName,
  }) async {
    try {
      final ref = FirebaseStorage.instance
          .ref('users/$uid/profiles/$profileId/attachments/$attachmentId-$fileName');
      final task = await ref.putFile(file);
      return await task.ref.getDownloadURL();
    } catch (e) {
      throw FileServiceException('Tải file lên máy chủ thất bại: $e');
    }
  }

  Future<void> deleteAttachment({
    required String uid,
    required String profileId,
    required String storagePath,
  }) async {
    try {
      await FirebaseStorage.instance.ref(storagePath).delete();
    } catch (_) {
      // Bỏ qua lỗi xóa file trên Storage để không chặn việc xóa metadata.
    }
  }
}
