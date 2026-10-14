import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/extensions/context_extensions.dart';
import '../core/utils/confirm_destructive_action.dart';
import '../core/utils/repository_action.dart';
import '../models/models.dart';
import '../repositories/app_repository.dart';
import '../repositories/firebase_repository.dart';
import '../services/browser_link_opener.dart';
import '../services/drive_authorization_service.dart';
import '../services/drive_file_picker.dart';
import '../services/file_service.dart';
import '../services/google_drive_service.dart';
import 'section_card.dart';

class AttachmentSection extends StatefulWidget {
  const AttachmentSection({super.key, required this.profileId});
  final String profileId;

  @override
  State<AttachmentSection> createState() => _AttachmentSectionState();
}

class _AttachmentSectionState extends State<AttachmentSection> {
  final _files = FileService();
  final _authorization = DriveAuthorizationService();
  final _picker = const DriveFilePicker();
  bool _busy = false;
  double? _progress;

  GoogleDriveService get _drive =>
      GoogleDriveService(accessToken: () => _authorization.accessToken ?? '');

  Future<void> _authorize() async {
    if (_authorization.accessToken == null) await _authorization.connect();
  }

  Future<void> _uploadToDrive() async {
    final repository = context.read<AppRepository>();
    if (repository is! FirebaseRepository) {
      context.showSnackBar(
        'Không tải tệp thật lên Google Drive trong chế độ Demo.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _progress = null;
    });
    String? uploadedId;
    try {
      // Request popup authorization while this call still originates from the
      // user's tap. Waiting for a file picker first can consume browser user
      // activation and cause Firebase Auth to report popup-blocked.
      await _authorize();
      final picked = await _picker.pick();
      if (picked == null) return;
      final profile = repository.profileById(widget.profileId);
      if (profile == null) throw StateError('Không tìm thấy hồ sơ.');
      final group = repository.groupById(profile.groupId);
      if (group == null) throw StateError('Không tìm thấy nhóm của hồ sơ.');
      final folderId = await _drive.ensureProfileFolder(
        groupId: group.id,
        groupName: group.name,
        profileId: profile.id,
        profileName: _profileFolderName(repository, profile),
      );
      final metadata = await _drive.upload(
        bytes: picked.bytes,
        fileName: picked.name,
        mimeType: picked.mimeType,
        parentId: folderId,
        profileId: profile.id,
        groupId: group.id,
        onProgress: (sent, total) {
          if (mounted && total > 0) setState(() => _progress = sent / total);
        },
      );
      uploadedId = metadata.id;
      final now = DateTime.now();
      await repository.addAttachment(
        Attachment(
          id: const Uuid().v4(),
          profileId: profile.id,
          fileName: metadata.name.isEmpty ? picked.name : metadata.name,
          type: AttachmentType.fromExtension(picked.name.split('.').last),
          localPathOrUrl: metadata.webViewLink,
          sizeBytes: metadata.sizeBytes == 0
              ? picked.sizeBytes
              : metadata.sizeBytes,
          storageProvider: AttachmentStorageProvider.googleDrive,
          externalFileId: metadata.id,
          mimeType: metadata.mimeType,
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (mounted) context.showSnackBar('Đã tải tài liệu lên Google Drive.');
    } catch (error) {
      if (uploadedId != null) {
        try {
          await _drive.trash(uploadedId);
        } catch (_) {}
      }
      if (mounted) context.showSnackBar('$error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
  }

  String _profileFolderName(AppRepository repository, Profile profile) {
    final sameName = repository.profiles
        .where(
          (candidate) =>
              candidate.groupId == profile.groupId &&
              candidate.fullName.trim().toLowerCase() ==
                  profile.fullName.trim().toLowerCase(),
        )
        .toList();
    if (sameName.length < 2) return profile.fullName;
    final year = profile.dateOfBirth?.year;
    if (year != null &&
        sameName
                .where((candidate) => candidate.dateOfBirth?.year == year)
                .length ==
            1) {
      return '${profile.fullName} - $year';
    }
    final shortId = profile.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final suffix = shortId.length <= 6 ? shortId : shortId.substring(0, 6);
    return [
      profile.fullName,
      if (year != null) '$year',
      suffix.isEmpty ? 'hồ sơ' : suffix,
    ].join(' - ');
  }

  Future<void> _addLocal(Future<PickedFileResult?> Function() picker) async {
    final repository = context.read<AppRepository>();
    if (repository is FirebaseRepository) {
      context.showSnackBar('Hãy dùng Google Drive để tải tài liệu lên.');
      return;
    }
    setState(() => _busy = true);
    try {
      final picked = await picker();
      if (picked == null) return;
      final now = DateTime.now();
      await repository.addAttachment(
        Attachment(
          id: const Uuid().v4(),
          profileId: widget.profileId,
          fileName: picked.fileName,
          type: AttachmentType.fromExtension(picked.fileName.split('.').last),
          localPathOrUrl: picked.path,
          sizeBytes: picked.sizeBytes,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } on FileServiceException catch (error) {
      if (mounted) context.showSnackBar(error.message, isError: true);
    } catch (error) {
      if (mounted) context.showSnackBar('$error', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showAddOptions() => showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.add_to_drive_outlined),
            title: const Text('Tải lên Google Drive'),
            subtitle: const Text('Tệp riêng tư trong Drive của bạn'),
            onTap: () {
              Navigator.pop(sheetContext);
              _uploadToDrive();
            },
          ),
          for (final option
              in <(IconData, String, Future<PickedFileResult?> Function())>[
                (
                  Icons.insert_drive_file_outlined,
                  'Chọn file trên thiết bị (Demo)',
                  _files.pickFile,
                ),
                (
                  Icons.image_outlined,
                  'Chọn ảnh từ thư viện (Demo)',
                  _files.pickImage,
                ),
                (
                  Icons.camera_alt_outlined,
                  'Chụp ảnh mới (Demo)',
                  _files.takePhoto,
                ),
              ])
            ListTile(
              leading: Icon(option.$1),
              title: Text(option.$2),
              onTap: () {
                Navigator.pop(sheetContext);
                _addLocal(option.$3);
              },
            ),
        ],
      ),
    ),
  );

  Future<void> _open(Attachment attachment) async {
    final path = attachment.localPathOrUrl;
    if (path == null || path.isEmpty) {
      context.showSnackBar(
        attachment.storageProvider == AttachmentStorageProvider.googleDrive
            ? 'Tệp không còn trên Google Drive.'
            : 'Bản ghi không có đường dẫn file.',
        isError: true,
      );
      return;
    }
    try {
      if (attachment.storageProvider == AttachmentStorageProvider.googleDrive) {
        await browserLinkOpener().open(path);
      } else {
        await _files.openFile(path);
      }
    } catch (error) {
      if (mounted) context.showSnackBar('$error', isError: true);
    }
  }

  Future<void> _copyLink(Attachment attachment) async {
    final link = attachment.localPathOrUrl;
    if (link == null || link.isEmpty) {
      context.showSnackBar('Tệp không còn trên Google Drive.', isError: true);
      return;
    }
    Clipboard.setData(ClipboardData(text: link));
    if (mounted) context.showSnackBar('Đã sao chép liên kết Google Drive.');
  }

  Future<void> _rename(Attachment attachment) async {
    final controller = TextEditingController(text: attachment.fileName);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đổi tên hiển thị'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty && mounted) {
      await runRepositoryAction(
        context,
        () =>
            context.read<AppRepository>().renameAttachment(attachment.id, name),
      );
    }
  }

  Future<void> _remove(Attachment attachment) async {
    final isDrive =
        attachment.storageProvider == AttachmentStorageProvider.googleDrive;
    final confirmed = await confirmDestructiveAction(
      context,
      title: isDrive ? 'Xóa khỏi hồ sơ?' : 'Xóa thông tin file?',
      message: isDrive
          ? 'Chỉ liên kết "${attachment.fileName}" bị xóa. Tệp trên Google Drive vẫn được giữ nguyên.'
          : 'Metadata của file "${attachment.fileName}" sẽ bị xóa.',
    );
    if (!confirmed || !mounted) return;
    await runRepositoryAction(
      context,
      () => context.read<AppRepository>().deleteAttachment(attachment.id),
    );
  }

  Future<void> _trash(Attachment attachment) async {
    final fileId = attachment.externalFileId;
    if (fileId == null || fileId.isEmpty) {
      context.showSnackBar('Tệp không còn trên Google Drive.', isError: true);
      return;
    }
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Đưa tệp vào Thùng rác?',
      message:
          'Tệp "${attachment.fileName}" sẽ được chuyển vào Thùng rác Google Drive và xóa khỏi hồ sơ.',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await _authorize();
      await _drive.trash(fileId);
      if (!mounted) return;
      await context.read<AppRepository>().deleteAttachment(attachment.id);
      if (mounted) context.showSnackBar('Đã chuyển tệp vào Thùng rác.');
    } catch (error) {
      if (mounted) context.showSnackBar('$error', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareLegacy(Attachment attachment) async {
    final path = attachment.localPathOrUrl;
    if (path == null || path.isEmpty) return;
    try {
      await _files.shareFile(path);
    } on FileServiceException catch (error) {
      if (mounted) context.showSnackBar(error.message, isError: true);
    }
  }

  IconData _icon(AttachmentType type) => switch (type) {
    AttachmentType.pdf => Icons.picture_as_pdf_rounded,
    AttachmentType.doc || AttachmentType.docx => Icons.description_rounded,
    AttachmentType.jpg ||
    AttachmentType.jpeg ||
    AttachmentType.png ||
    AttachmentType.webp => Icons.image_rounded,
    AttachmentType.other => Icons.insert_drive_file_rounded,
  };

  String _size(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final attachments = context.watch<AppRepository>().attachmentsOf(
      widget.profileId,
    );
    return SectionCard(
      title: 'Tài liệu / File đính kèm',
      trailing: IconButton(
        tooltip: 'Thêm tài liệu',
        onPressed: _busy ? null : _showAddOptions,
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_progress != null) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 6),
            Text(
              'Đang tải lên ${(_progress! * 100).round()}%',
              style: context.textTheme.bodySmall,
            ),
          ],
          if (attachments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Chưa có file nào',
                style: context.textTheme.bodySmall,
              ),
            )
          else
            ...attachments.map((attachment) {
              final isDrive =
                  attachment.storageProvider ==
                  AttachmentStorageProvider.googleDrive;
              final detail = [
                _size(attachment.sizeBytes),
                if (isDrive) 'Google Drive',
              ].where((value) => value.isNotEmpty).join(' • ');
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isDrive ? Icons.add_to_drive : _icon(attachment.type),
                  color: context.colors.primary,
                ),
                title: Text(
                  attachment.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: detail.isEmpty ? null : Text(detail),
                onTap: () => _open(attachment),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'open') await _open(attachment);
                    if (value == 'copy') await _copyLink(attachment);
                    if (value == 'rename') await _rename(attachment);
                    if (value == 'share') await _shareLegacy(attachment);
                    if (value == 'remove') await _remove(attachment);
                    if (value == 'trash') await _trash(attachment);
                  },
                  itemBuilder: (_) => isDrive
                      ? const [
                          PopupMenuItem(value: 'open', child: Text('Mở tệp')),
                          PopupMenuItem(
                            value: 'copy',
                            child: Text('Sao chép liên kết'),
                          ),
                          PopupMenuItem(
                            value: 'rename',
                            child: Text('Đổi tên hiển thị'),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: Text('Xóa khỏi hồ sơ'),
                          ),
                          PopupMenuItem(
                            value: 'trash',
                            child: Text('Đưa tệp vào Thùng rác'),
                          ),
                        ]
                      : const [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text('Đổi tên'),
                          ),
                          PopupMenuItem(value: 'share', child: Text('Chia sẻ')),
                          PopupMenuItem(value: 'remove', child: Text('Xóa')),
                        ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
