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

Future<AppSession> pumpSettings(
  WidgetTester tester, {
  required ExportFileDelivery delivery,
  BackupService backupService = const BackupService(),
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
}
