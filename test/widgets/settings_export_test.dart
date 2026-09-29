import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/navigation/app_session.dart';
import 'package:quanlycongviecapp/navigation/theme_controller.dart';
import 'package:quanlycongviecapp/screens/settings/settings_screen.dart';
import 'package:quanlycongviecapp/services/backup_service.dart';
import 'package:quanlycongviecapp/services/backup_file_picker.dart';
import 'package:quanlycongviecapp/services/connectivity_service.dart';
import 'package:quanlycongviecapp/services/export_file_delivery.dart';
import 'package:quanlycongviecapp/services/export_snapshot_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingDelivery implements ExportFileDelivery {
  final Completer<void>? blocker;
  int calls = 0;
  String? fileName;
  String? mimeType;

  RecordingDelivery({this.blocker});

  @override
  Future<void> deliver({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    calls++;
    this.fileName = fileName;
    this.mimeType = mimeType;
    await blocker?.future;
  }
}

class FailingBackupService extends BackupService {
  const FailingBackupService();

  @override
  GeneratedExportFile createJsonBackup(ExportSnapshot snapshot) {
    throw const ExportValidationException('Dữ liệu backup không hợp lệ.');
  }
}

class RecordingBackupPicker implements BackupFilePicker {
  RecordingBackupPicker({this.blocker});
  final Completer<PickedBackupFile?>? blocker;
  PickedBackupFile? result;
  int calls = 0;
  @override
  Future<PickedBackupFile?> pickJson() async {
    calls++;
    return blocker == null ? result : blocker!.future;
  }
}

Future<AppSession> pumpSettings(
  WidgetTester tester, {
  required ExportFileDelivery delivery,
  BackupService backupService = const BackupService(),
  BackupFilePicker backupFilePicker = const DeviceBackupFilePicker(),
}) async {
  SharedPreferences.setMockInitialValues({});
  final session = AppSession();
  await session.enterDemoMode();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
      ],
      child: MaterialApp(
        home: SettingsScreen(
          fileDelivery: delivery,
          backupService: backupService,
          backupFilePicker: backupFilePicker,
        ),
      ),
    ),
  );
  await tester.pump();
  return session;
}

void main() {
  testWidgets('JSON and XLSX actions deliver correct names and MIME types', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final delivery = RecordingDelivery();
    final session = await pumpSettings(tester, delivery: delivery);
    await tester.scrollUntilVisible(
      find.text('Sao lưu dữ liệu'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sao lưu dữ liệu'), findsOneWidget);
    expect(find.text('Xuất Excel'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Sao lưu dữ liệu'));
    await tester.tap(find.text('Sao lưu dữ liệu'));
    await tester.pumpAndSettle();
    expect(delivery.calls, 1);
    expect(delivery.fileName, matches(RegExp(r'.*\.json$')));
    expect(delivery.mimeType, 'application/json;charset=utf-8');

    await tester.tap(find.text('Xuất Excel'));
    await tester.pumpAndSettle();
    expect(delivery.calls, 2);
    expect(delivery.fileName, matches(RegExp(r'.*\.xlsx$')));
    expect(
      delivery.mimeType,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    session.dispose();
  });

  testWidgets('double click is blocked while export delivery is pending', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final blocker = Completer<void>();
    final delivery = RecordingDelivery(blocker: blocker);
    final session = await pumpSettings(tester, delivery: delivery);
    await tester.scrollUntilVisible(
      find.text('Sao lưu dữ liệu'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sao lưu dữ liệu'));
    await tester.tap(find.text('Sao lưu dữ liệu'));
    for (var i = 0; i < 5 && delivery.calls == 0; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(delivery.calls, 1);
    blocker.complete();
    await tester.pumpAndSettle();
    session.dispose();
  });

  testWidgets('validation failure produces no download', (tester) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final delivery = RecordingDelivery();
    final session = await pumpSettings(
      tester,
      delivery: delivery,
      backupService: const FailingBackupService(),
    );
    await tester.scrollUntilVisible(
      find.text('Sao lưu dữ liệu'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sao lưu dữ liệu'));
    await tester.pumpAndSettle();
    expect(delivery.calls, 0);
    expect(find.text('Dữ liệu backup không hợp lệ.'), findsOneWidget);
    session.dispose();
  });

  testWidgets('valid JSON preview is responsive and performs zero writes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final picker = RecordingBackupPicker();
    final delivery = RecordingDelivery();
    final session = await pumpSettings(
      tester,
      delivery: delivery,
      backupFilePicker: picker,
    );
    final repo = session.repository!;
    final backup = (await tester.runAsync(
      () async => const BackupService().createJsonBackup(
        await repo.createExportSnapshot(),
      ),
    ))!;
    picker.result = PickedBackupFile(
      name: backup.fileName,
      size: backup.bytes.length,
      bytes: backup.bytes,
    );
    final before = repo.revision;
    await tester.scrollUntilVisible(
      find.text('Kiểm tra bản sao lưu'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Kiểm tra bản sao lưu'), findsOneWidget);
    await tester.ensureVisible(find.text('Kiểm tra bản sao lưu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kiểm tra bản sao lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Xem trước bản sao lưu'), findsOneWidget);
    expect(
      find.text('File hợp lệ và có thể dùng để khôi phục.'),
      findsOneWidget,
    );
    expect(find.textContaining('metadata'), findsWidgets);
    expect(find.text('Khôi phục'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(repo.revision, before);
    expect(repo.writesInFlight, 0);
    expect(delivery.calls, 0);
    session.dispose();
  });

  testWidgets('invalid file shows readable error and zero writes', (
    tester,
  ) async {
    final picker = RecordingBackupPicker();
    picker.result = PickedBackupFile(
      name: 'bad.json',
      size: 1,
      bytes: Uint8List.fromList([123]),
    );
    final delivery = RecordingDelivery();
    final session = await pumpSettings(
      tester,
      delivery: delivery,
      backupFilePicker: picker,
    );
    final repo = session.repository!;
    final before = repo.revision;
    await tester.scrollUntilVisible(
      find.text('Kiểm tra bản sao lưu'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Kiểm tra bản sao lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Không thể sử dụng bản sao lưu này.'), findsOneWidget);
    expect(find.textContaining('JSON không hợp lệ'), findsOneWidget);
    expect(repo.revision, before);
    expect(delivery.calls, 0);
    session.dispose();
  });

  testWidgets('cancel and double click never write', (tester) async {
    final blocker = Completer<PickedBackupFile?>();
    final picker = RecordingBackupPicker(blocker: blocker);
    final session = await pumpSettings(
      tester,
      delivery: RecordingDelivery(),
      backupFilePicker: picker,
    );
    final repo = session.repository!;
    final before = repo.revision;
    await tester.scrollUntilVisible(
      find.text('Kiểm tra bản sao lưu'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Kiểm tra bản sao lưu'));
    await tester.pump();
    await tester.tap(find.text('Kiểm tra bản sao lưu'));
    expect(picker.calls, 1);
    blocker.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('Xem trước bản sao lưu'), findsNothing);
    expect(repo.revision, before);
    expect(repo.writesInFlight, 0);
    session.dispose();
  });
}
