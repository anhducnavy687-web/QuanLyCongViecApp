import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/restore_preview.dart';

class RestorePreviewDialog extends StatefulWidget {
  const RestorePreviewDialog({
    super.key,
    required this.preview,
    required this.isFirebaseMode,
    this.onRestore,
  });
  final RestorePreview preview;
  final bool isFirebaseMode;
  final Future<void> Function()? onRestore;

  @override
  State<RestorePreviewDialog> createState() => _RestorePreviewDialogState();
}

class _RestorePreviewDialogState extends State<RestorePreviewDialog> {
  bool _restoring = false;
  String? _error;

  RestorePreview get preview => widget.preview;

  Future<void> _restore() async {
    if (_restoring || widget.onRestore == null) return;
    final counts = preview.recordCounts;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục dữ liệu?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Toàn bộ dữ liệu hiện tại trong tài khoản sẽ bị thay thế bằng dữ liệu trong bản sao lưu này.',
            ),
            const SizedBox(height: 12),
            _Row(
              'Ngày tạo backup',
              DateFormat('dd/MM/yyyy HH:mm')
                  .format(preview.exportedAt.toLocal()),
            ),
            _Row('Số hồ sơ', '${counts['profiles'] ?? 0}'),
            _Row('Số công việc', '${counts['tasks'] ?? 0}'),
            _Row('Số giao dịch', '${counts['transactions'] ?? 0}'),
            _Row('Số cộng tác viên', '${counts['collaborators'] ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('HỦY'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('KHÔI PHỤC'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _restoring = true;
      _error = null;
    });
    try {
      await widget.onRestore!();
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _restoring = false;
        _error = error.toString();
      });
    }
  }

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
              if (!widget.isFirebaseMode) ...[
                const SizedBox(height: 12),
                const Text(
                  'Khôi phục dữ liệu chỉ khả dụng khi bạn đăng nhập tài khoản.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
              if (_restoring) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                const Text('Đang khôi phục và xác minh dữ liệu…'),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _restoring ? null : () => Navigator.pop(context, false),
          child: const Text('Đóng'),
        ),
        if (widget.isFirebaseMode && preview.isValid)
          FilledButton(
            onPressed: _restoring ? null : _restore,
            child: const Text('KHÔI PHỤC DỮ LIỆU'),
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
