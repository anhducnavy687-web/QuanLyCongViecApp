import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/responsive/responsive.dart';
import '../../navigation/app_session.dart';
import '../../navigation/theme_controller.dart';
import '../../models/restore_preview.dart';
import '../../repositories/demo_repository.dart';
import '../../repositories/app_repository.dart';
import '../../repositories/firebase_repository.dart';
import '../../services/backup_service.dart';
import '../../services/backup_file_picker.dart';
import '../../services/backup_import_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/excel_export_service.dart';
import '../../services/export_snapshot_validator.dart';
import '../../services/file_download_service.dart';
import '../../services/restore_service.dart';
import '../collaborators/collaborators_screen.dart';
import 'restore_preview_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.backupService = const BackupService(),
    this.excelExportService = const ExcelExportService(),
    this.fileDelivery,
    this.backupFilePicker = const DeviceBackupFilePicker(),
    this.backupImportService = const BackupImportService(),
    this.restoreService = const RestoreService(),
  });

  final BackupService backupService;
  final ExcelExportService excelExportService;
  final ExportFileDelivery? fileDelivery;
  final BackupFilePicker backupFilePicker;
  final BackupImportService backupImportService;
  final RestoreService restoreService;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final themeController = context.watch<ThemeController>();
    final connectivity = context.watch<ConnectivityService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ResponsivePage(
        maxContentWidth: 720,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _SectionLabel('Tài khoản'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: context.colors.primaryContainer,
                  backgroundImage: session.user?.photoUrl != null
                      ? NetworkImage(session.user!.photoUrl!)
                      : null,
                  child: session.user?.photoUrl == null
                      ? const Icon(Icons.person_outline_rounded)
                      : null,
                ),
                title: Text(
                  session.isDemoMode
                      ? 'Chế độ Demo'
                      : (session.user?.displayName ?? 'Người dùng'),
                ),
                subtitle: Text(
                  session.isDemoMode
                      ? 'Dữ liệu chỉ lưu tạm trên máy, sẽ mất khi thoát app'
                      : (session.user?.email ?? ''),
                ),
                trailing: TextButton(
                  onPressed: () => _confirmSignOut(context, session),
                  child: Text(session.isDemoMode ? 'Thoát Demo' : 'Đăng xuất'),
                ),
              ),
            ),
            _SectionLabel('Giao diện'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: RadioGroup<ThemeMode>(
                groupValue: themeController.mode,
                onChanged: (v) => themeController.setMode(v!),
                child: const Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text('Theo hệ thống'),
                      value: ThemeMode.system,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Sáng'),
                      value: ThemeMode.light,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Tối'),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              ),
            ),
            _SectionLabel('Dữ liệu'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.people_outline_rounded),
                    title: const Text('Quản lý cộng tác viên'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CollaboratorsScreen(),
                      ),
                    ),
                  ),
                  SwitchListTile(
                    secondary: Icon(
                      connectivity.isOnline
                          ? Icons.wifi_rounded
                          : Icons.wifi_off_rounded,
                    ),
                    title: const Text('Trạng thái mạng (giả lập)'),
                    subtitle: Text(
                      connectivity.isOnline ? 'Đang online' : 'Đang offline',
                    ),
                    value: connectivity.isOnline,
                    onChanged: session.repository is DemoRepository
                        ? (v) => (session.repository as DemoRepository)
                              .setSimulatedOnline(v)
                        : null,
                  ),
                ],
              ),
            ),
            _SectionLabel('Sao lưu & dữ liệu'),
            _DataExportCard(
              session: session,
              repository: session.repository,
              isDemoMode: session.isDemoMode,
              backupService: backupService,
              excelExportService: excelExportService,
              fileDelivery: fileDelivery,
              backupFilePicker: backupFilePicker,
              backupImportService: backupImportService,
              restoreService: restoreService,
            ),
            _SectionLabel('Giới thiệu'),
            const Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text(AppConstants.appName),
                subtitle: Text(
                  'Phiên bản 1.0.0 — Kiến trúc sẵn sàng cho Firebase',
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AppSession session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(session.isDemoMode ? 'Thoát chế độ Demo?' : 'Đăng xuất?'),
        content: Text(
          session.isDemoMode
              ? 'Toàn bộ dữ liệu demo hiện tại sẽ mất.'
              : 'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              session.signOut();
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }
}

class _DataExportCard extends StatefulWidget {
  const _DataExportCard({
    required this.session,
    required this.repository,
    required this.isDemoMode,
    required this.backupService,
    required this.excelExportService,
    this.fileDelivery,
    required this.backupFilePicker,
    required this.backupImportService,
    required this.restoreService,
  });

  final AppSession session;
  final AppRepository? repository;
  final bool isDemoMode;
  final BackupService backupService;
  final ExcelExportService excelExportService;
  final ExportFileDelivery? fileDelivery;
  final BackupFilePicker backupFilePicker;
  final BackupImportService backupImportService;
  final RestoreService restoreService;

  @override
  State<_DataExportCard> createState() => _DataExportCardState();
}

class _DataExportCardState extends State<_DataExportCard> {
  bool _busy = false;

  Future<void> _inspectBackup() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await widget.backupFilePicker.pickJson();
      if (file == null || !mounted) return;
      final preview = widget.backupImportService.inspect(file);
      if (!mounted) return;
      setState(() => _busy = false);
      final restored = await showDialog<bool>(
        context: context,
        builder: (_) => RestorePreviewDialog(
          preview: preview,
          isFirebaseMode: !widget.isDemoMode,
          onRestore: widget.isDemoMode ? null : () => _restoreBackup(preview),
        ),
      );
      if (restored == true && mounted) {
        context.showSnackBar('Khôi phục dữ liệu thành công.');
      }
    } catch (error) {
      if (!mounted) return;
      final message = error is BackupImportException
          ? error.message
          : 'Không thể đọc hoặc kiểm tra file đã chọn.';
      setState(() => _busy = false);
      await showDialog<void>(
        context: context,
        builder: (_) => InvalidBackupDialog(message: message),
      );
      assert(() {
        debugPrint('Backup inspection failed: ${error.runtimeType}');
        return true;
      }());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup(RestorePreview preview) async {
    final repository = widget.session.repository;
    final uid = widget.session.user?.uid;
    if (repository is! FirebaseRepository ||
        uid == null ||
        uid != repository.uid) {
      throw const RestoreException(
        'Khôi phục dữ liệu chỉ khả dụng khi bạn đăng nhập tài khoản.',
      );
    }
    await widget.restoreService.restore(
      repository: repository,
      preview: preview,
      currentUid: () => widget.session.authService.currentUser?.uid,
    );
    final reloaded = await widget.session.reloadAfterRestore(uid);
    if (reloaded == null) {
      throw const RestoreException(
        'Dữ liệu đã được gửi lên máy chủ nhưng ứng dụng chưa thể xác minh hoàn tất. Hãy tải lại ứng dụng và kiểm tra dữ liệu.',
      );
    }
    try {
      widget.restoreService.verify(reloaded, preview);
    } on RestoreException {
      throw const RestoreException(
        'Dữ liệu đã được gửi lên máy chủ nhưng ứng dụng chưa thể xác minh hoàn tất. Hãy tải lại ứng dụng và kiểm tra dữ liệu.',
      );
    }
  }

  Future<void> _export({required bool excel}) async {
    if (_busy || widget.repository == null) return;
    setState(() => _busy = true);
    try {
      final snapshot = await widget.repository!.createExportSnapshot();
      final file = excel
          ? widget.excelExportService.createWorkbook(snapshot)
          : widget.backupService.createJsonBackup(snapshot);
      final delivery = widget.fileDelivery ?? createFileDownloadService();
      await delivery.deliver(
        bytes: file.bytes,
        fileName: file.fileName,
        mimeType: file.mimeType,
      );
      if (!mounted) return;
      context.showSnackBar(
        excel
            ? 'Đã gửi yêu cầu tải file Excel cho trình duyệt.'
            : 'Đã gửi yêu cầu tải file sao lưu cho trình duyệt.',
      );
    } catch (error) {
      if (!mounted) return;
      final message = switch (error) {
        RepositoryException() => error.message,
        ExportValidationException() => error.message,
        _ => 'Không thể tạo file. Vui lòng thử lại.',
      };
      context.showSnackBar(message, isError: true);
      assert(() {
        debugPrint('Export failed: ${error.runtimeType}');
        return true;
      }());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Sao lưu dữ liệu'),
            subtitle: const Text(
              'Tạo bản JSON có thể dùng để khôi phục dữ liệu sau này',
            ),
            trailing: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            onTap: _busy ? null : () => _export(excel: false),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.table_view_outlined),
            title: const Text('Xuất Excel'),
            subtitle: const Text('Tạo bảng dữ liệu để xem, lưu trữ và in'),
            trailing: const Icon(Icons.download_rounded),
            onTap: _busy ? null : () => _export(excel: true),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('Kiểm tra bản sao lưu'),
            subtitle: const Text(
              'Chọn file JSON để kiểm tra trước khi khôi phục',
            ),
            trailing: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right_rounded),
            onTap: _busy ? null : _inspectBackup,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              '${widget.isDemoMode ? 'Đây là dữ liệu Demo hiện tại. ' : ''}'
              'File sao lưu có thể chứa thông tin cá nhân, ghi chú và dữ liệu tài chính. '
              'Hãy lưu file ở nơi an toàn.',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        text,
        style: context.textTheme.labelLarge?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
