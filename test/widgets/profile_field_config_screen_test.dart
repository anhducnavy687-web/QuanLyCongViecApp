import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/repositories/app_repository.dart';
import 'package:quanlycongviecapp/repositories/demo_repository.dart';
import 'package:quanlycongviecapp/screens/groups/add_edit_group_sheet.dart';
import 'package:quanlycongviecapp/screens/groups/profile_field_config_screen.dart';

void main() {
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets(
    'group form shows real summary and opens dedicated config route',
    (tester) async {
      final repo = DemoRepository();
      await repo.init();
      await tester.pumpWidget(
        ChangeNotifierProvider<AppRepository>.value(
          value: repo,
          child: const MaterialApp(home: Scaffold(body: AddEditGroupSheet())),
        ),
      );
      expect(
        find.text('16 trường đang sử dụng · 11 trường bắt buộc'),
        findsOneWidget,
      );
      expect(find.byType(ExpansionTile), findsNothing);
      await tester.tap(find.text('Cấu hình trường thông tin'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileFieldConfigScreen), findsOneWidget);
      expect(find.text('Cấu hình trường hồ sơ'), findsOneWidget);
      repo.dispose();
    },
  );

  testWidgets('active list omits phone and add sheet offers it', (
    tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileFieldConfigScreen(
          initialConfigs: ProfileFieldCatalog.defaultConfigs(),
          initialCustomDefinitions: const [],
        ),
      ),
    );
    expect(find.text('Số điện thoại'), findsNothing);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Thêm trường'));
    await tester.pumpAndSettle();
    expect(find.text('TRƯỜNG CÓ SẴN'), findsOneWidget);
    expect(find.text('Số điện thoại'), findsOneWidget);
    expect(find.text('Mục tiêu/Nội dung công việc'), findsOneWidget);
  });

  testWidgets(
    'fullName is locked and aspirations are pinned without drag handles',
    (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileFieldConfigScreen(
            initialConfigs: ProfileFieldCatalog.defaultConfigs(),
            initialCustomDefinitions: const [],
          ),
        ),
      );
      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(
        find.text('Nguyện vọng luôn được hiển thị ở cuối biểu mẫu.'),
        findsOneWidget,
      );
      expect(find.text('Nguyện vọng 1'), findsOneWidget);
      expect(find.text('Nguyện vọng 2'), findsOneWidget);
      expect(find.text('Nguyện vọng 3'), findsOneWidget);
    },
  );

  for (final size in const [
    Size(390, 844),
    Size(430, 932),
    Size(768, 1024),
    Size(1440, 900),
  ]) {
    testWidgets(
      'config screen has no overflow at ${size.width}x${size.height}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileFieldConfigScreen(
              initialConfigs: ProfileFieldCatalog.defaultConfigs(),
              initialCustomDefinitions: const [],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
