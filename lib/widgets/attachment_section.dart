import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/extensions/context_extensions.dart';
import '../models/models.dart';
import '../repositories/app_repository.dart';
import '../repositories/firebase_repository.dart';
import '../services/file_service.dart';
import '../services/storage_upload_service.dart';
import 'section_card.dart';

/// Khu vực Tài liệu/File đính kèm trong trang chi tiết hồ sơ.
class AttachmentSection extends StatefulWidget {
  final String profileId;
  const AttachmentSection({super.key, required this.profileId});

  @override
  State<AttachmentSection> createState() => _AttachmentSectionState();
}

class _AttachmentSectionState extends State<AttachmentSection> {
  final _fileService = FileService();
  final _uploadService = StorageUploadService();
  bool _busy = false;

  Future<void> _addFrom(Future<PickedFileResult?> Function() picker) async {
    if (context.read<AppRepository>() is FirebaseRepository) {
      context.showSnackBar(
        'Tải tài liệu lên đám mây chưa được hỗ trợ trong phiên bản này.',
      );
      return;
    }
    setState(() => _busy = true);
    final repo = context.read<AppRepository>();
    try {
      final picked = await picker();
      if (picked == null) return;
      final id = const Uuid().v4();
      String pathOrUrl = picked.path;
      String? storagePath;
      if (repo is FirebaseRepository) {
        final uid = repo.uid;
        storagePath =
            'users/$uid/profiles/${widget.profileId}/attachments/$id-${picked.fileName}';
        pathOrUrl = await _uploadService.uploadAttachment(
          uid: uid,
          profileId: widget.profileId,
          attachmentId: id,
          file: File(picked.path),
          fileName: picked.fileName,
        );
      }
      final ext = picked.fileName.contains('.')
          ? picked.fileName.split('.').last
          : '';
      await repo.addAttachment(
        Attachment(
          id: id,
          profileId: widget.profileId,
          fileName: picked.fileName,
          type: AttachmentType.fromExtension(ext),
          localPathOrUrl: pathOrUrl,
          storagePath: storagePath,
          sizeBytes: picked.sizeBytes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } on FileServiceException catch (e) {
      if (mounted) context.showSnackBar(e.message, isError: true);
    } catch (e) {
      if (mounted) context.showSnackBar('Đã xảy ra lỗi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: const Text('Chọn file (PDF, DOC, DOCX...)'),
              onTap: () {
                Navigator.pop(ctx);
                _addFrom(_fileService.pickFile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                _addFrom(_fileService.pickImage);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(ctx);
                _addFrom(_fileService.takePhoto);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(Attachment att) async {
    final ctrl = TextEditingController(text: att.fileName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi tên file'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && mounted) {
      await context.read<AppRepository>().renameAttachment(att.id, newName);
    }
  }

  IconData _iconFor(AttachmentType type) {
    switch (type) {
      case AttachmentType.pdf:
        return Icons.picture_as_pdf_rounded;
      case AttachmentType.doc:
      case AttachmentType.docx:
        return Icons.description_rounded;
      case AttachmentType.jpg:
      case AttachmentType.jpeg:
      case AttachmentType.png:
      case AttachmentType.webp:
        return Icons.image_rounded;
      case AttachmentType.other:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final attachments = repo.attachmentsOf(widget.profileId);

    return SectionCard(
      title: 'Tài liệu / File đính kèm',
      trailing: IconButton(
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded),
        onPressed: _busy ? null : _showAddOptions,
      ),
      child: attachments.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Chưa có file nào',
                style: context.textTheme.bodySmall,
              ),
            )
          : Column(
              children: attachments
                  .map(
                    (att) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _iconFor(att.type),
                        color: context.colors.primary,
                      ),
                      title: Text(
                        att.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_formatSize(att.sizeBytes)),
                      onTap: () async {
                        try {
                          await _fileService.openFile(att.localPathOrUrl);
                        } on FileServiceException catch (e) {
                          if (context.mounted) {
                            context.showSnackBar(e.message, isError: true);
                          }
                        }
                      },
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          switch (value) {
                            case 'rename':
                              await _rename(att);
                              break;
                            case 'share':
                              try {
                                await _fileService.shareFile(
                                  att.localPathOrUrl,
                                );
                              } on FileServiceException catch (e) {
                                if (context.mounted) {
                                  context.showSnackBar(
                                    e.message,
                                    isError: true,
                                  );
                                }
                              }
                              break;
                            case 'delete':
                              await repo.deleteAttachment(att.id);
                              break;
                          }
                        },
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text('Đổi tên'),
                          ),
                          PopupMenuItem(value: 'share', child: Text('Chia sẻ')),
                          PopupMenuItem(value: 'delete', child: Text('Xóa')),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
