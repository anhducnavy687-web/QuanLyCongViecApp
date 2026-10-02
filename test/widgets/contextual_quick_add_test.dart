import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/app.dart';
import 'package:quanlycongviecapp/navigation/app_session.dart';
import 'package:quanlycongviecapp/navigation/theme_controller.dart';
import 'package:quanlycongviecapp/services/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpDemo(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final session = AppSession();
  await session.enterDemoMode();
  await tester.pumpWidget(
    QlcvApp(
      session: session,
      themeController: ThemeController(),
      connectivityService: ConnectivityService(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> openQuickAdd(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Thêm nhanh'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('top-level destinations expose contextual FAB only', (
    tester,
  ) async {
    await pumpDemo(tester);
    expect(find.byTooltip('Thêm nhanh'), findsOneWidget);

    await tester.tap(find.text('Nhóm').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Thêm nhóm'), findsOneWidget);
    expect(find.byTooltip('Thêm nhanh'), findsNothing);
    await tester.tap(find.byTooltip('Thêm nhóm'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm nhóm công việc'), findsOneWidget);
    expect(find.text('THÊM NHANH'), findsNothing);
    Navigator.of(tester.element(find.text('Thêm nhóm công việc'))).pop();
    await tester.pumpAndSettle();

    for (final label in ['Lịch', 'Thống kê', 'Cài đặt']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);
    }
  });

  testWidgets('Home Quick Add presents three actions in priority order', (
    tester,
  ) async {
    await pumpDemo(tester);
    await openQuickAdd(tester);
    expect(find.text('THÊM NHANH'), findsOneWidget);
    expect(find.text('Thêm công việc'), findsOneWidget);
    expect(find.text('Thêm giao dịch'), findsOneWidget);
    expect(find.text('Thêm hồ sơ'), findsOneWidget);
    final taskY = tester.getTopLeft(find.text('Thêm công việc')).dy;
    final transactionY = tester.getTopLeft(find.text('Thêm giao dịch')).dy;
    final profileY = tester.getTopLeft(find.text('Thêm hồ sơ')).dy;
    expect(taskY, lessThan(transactionY));
    expect(transactionY, lessThan(profileY));
  });

  testWidgets('Quick Add task selects a profile before opening task form', (
    tester,
  ) async {
    await pumpDemo(tester);
    await openQuickAdd(tester);
    await tester.tap(find.text('Thêm công việc'));
    await tester.pumpAndSettle();
    expect(find.text('Tìm hồ sơ...'), findsOneWidget);
    await tester.tap(find.text('Nguyễn Văn Minh'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm việc cần làm'), findsOneWidget);
  });

  testWidgets('Quick Add transaction opens existing transaction dialog', (
    tester,
  ) async {
    await pumpDemo(tester);
    await openQuickAdd(tester);
    await tester.tap(find.text('Thêm giao dịch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nguyễn Văn Minh'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm giao dịch'), findsOneWidget);
    expect(find.text('Số tiền (đ)'), findsOneWidget);
  });

  testWidgets('Quick Add profile opens the existing profile form', (
    tester,
  ) async {
    await pumpDemo(tester);
    await openQuickAdd(tester);
    await tester.tap(find.text('Thêm hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm hồ sơ'), findsOneWidget);
  });
}
