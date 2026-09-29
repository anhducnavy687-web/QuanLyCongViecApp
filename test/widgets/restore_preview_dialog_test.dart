import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/models/restore_preview.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';
import 'package:quanlycongviecapp/screens/settings/restore_preview_dialog.dart';
import 'package:quanlycongviecapp/services/backup_file_picker.dart';
import 'package:quanlycongviecapp/services/backup_import_service.dart';
import 'package:quanlycongviecapp/services/backup_service.dart';

void main() {
  late DemoRepository demo;
  late RestorePreview preview;

  setUpAll(() async {
    demo = DemoRepository();
    await demo.init();
    final backup = const BackupService().createJsonBackup(
      await demo.createExportSnapshot(),
    );
    preview = const BackupImportService().inspect(
      PickedBackupFile(
        name: backup.fileName,
        size: backup.bytes.length,
        bytes: backup.bytes,
      ),
    );
  });
  tearDownAll(() => demo.dispose());

  Future<void> pumpDialog(
    WidgetTester tester, {
    required bool firebase,
    Future<void> Function()? onRestore,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestorePreviewDialog(
            preview: preview,
            isFirebaseMode: firebase,
            onRestore: onRestore,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Demo shows explanation and no real restore button', (
    tester,
  ) async {
    await pumpDialog(tester, firebase: false);
    expect(
      find.text('Khôi phục dữ liệu chỉ khả dụng khi bạn đăng nhập tài khoản.'),
      findsOneWidget,
    );
    expect(find.text('KHÔI PHỤC DỮ LIỆU'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Firebase preview shows destructive confirmation and cancel writes zero',
    (tester) async {
      var calls = 0;
      await pumpDialog(tester, firebase: true, onRestore: () async => calls++);
      await tester.tap(find.text('KHÔI PHỤC DỮ LIỆU'));
      await tester.pumpAndSettle();
      expect(find.text('Khôi phục dữ liệu?'), findsOneWidget);
      expect(find.textContaining('Toàn bộ dữ liệu hiện tại'), findsOneWidget);
      expect(
        find.text('Số hồ sơ: ${preview.recordCounts['profiles']}'),
        findsOneWidget,
      );
      await tester.tap(find.text('HỦY'));
      await tester.pumpAndSettle();
      expect(calls, 0);
    },
  );

  testWidgets('double submit invokes one restore and shows progress', (
    tester,
  ) async {
    final blocker = Completer<void>();
    var calls = 0;
    await pumpDialog(
      tester,
      firebase: true,
      onRestore: () {
        calls++;
        return blocker.future;
      },
      size: const Size(768, 1024),
    );
    await tester.tap(find.text('KHÔI PHỤC DỮ LIỆU'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('KHÔI PHỤC'));
    await tester.pump();
    expect(find.text('Đang khôi phục và xác minh dữ liệu…'), findsOneWidget);
    expect(calls, 1);
    expect(find.text('KHÔI PHỤC DỮ LIỆU'), findsOneWidget);
    blocker.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('restore failure remains open and allows retry', (tester) async {
    var calls = 0;
    await pumpDialog(
      tester,
      firebase: true,
      onRestore: () async {
        calls++;
        throw Exception('Lỗi thử nghiệm');
      },
      size: const Size(1440, 900),
    );
    await tester.tap(find.text('KHÔI PHỤC DỮ LIỆU'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('KHÔI PHỤC'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lỗi thử nghiệm'), findsOneWidget);
    expect(find.text('Xem trước bản sao lưu'), findsOneWidget);
    expect(calls, 1);
  });
}
