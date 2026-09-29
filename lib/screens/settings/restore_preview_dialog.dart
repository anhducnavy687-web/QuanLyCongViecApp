import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/restore_preview.dart';

class RestorePreviewDialog extends StatelessWidget {
  const RestorePreviewDialog({super.key, required this.preview});
  final RestorePreview preview;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.decimalPattern('vi');
    return AlertDialog(
      title: const Text('Xem trước bản sao lưu'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Heading('Thông tin file'),
              _Row('Tên file', preview.fileName),
              _Row('Dung lượng', '${money.format(preview.fileSize)} bytes'),
              _Row('Schema version', '${preview.schemaVersion}'),
              _Row(
                'Ngày tạo',
                DateFormat('dd/MM/yyyy HH:mm')
                    .format(preview.exportedAt.toLocal()),
              ),
              _Row('App version', preview.appVersion),
              _Row('Nguồn', preview.sourceMode),
              const _Heading('Dữ liệu'),
              for (final entry in preview.recordCounts.entries)
                _Row(entry.key, '${entry.value}'),
              _Row(
                'Phân công đã lưu trữ',
                '${preview.archivedAssignmentCount}',
              ),
              _Row(
                'CTV không hoạt động',
                '${preview.inactiveCollaboratorCount}',
              ),
              const _Heading('Tài chính'),
              _Row(
                'Tổng tiền nhận',
                '${money.format(preview.totalReceived)} đ',
              ),
              _Row('Tổng chi phí', '${money.format(preview.totalExpense)} đ'),
              _Row(
                'Tổng đã trả CTV',
                '${money.format(preview.totalCollaboratorPayment)} đ',
              ),
              if (preview.warnings.isNotEmpty) ...[
                const _Heading('Cảnh báo'),
                for (final warning in preview.warnings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $warning'),
                  ),
              ],
              const SizedBox(height: 12),
              const Text(
                'File hợp lệ và có thể dùng để khôi phục.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('Bản xem trước này không thay đổi dữ liệu hiện tại.'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class InvalidBackupDialog extends StatelessWidget {
  const InvalidBackupDialog({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Không thể sử dụng bản sao lưu này.'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lỗi kiểm tra file',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(message),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
    ],
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text('$label: $value'),
  );
}
