// Kiểm tra các màn hình chính không bị RenderFlex overflow / lỗi layout ở
// 4 kích thước màn hình điện thoại bắt buộc theo spec Phase 1.1:
// 360x800, 390x844, 412x915, 430x932.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quanlycongviecapp/app.dart';
import 'package:quanlycongviecapp/navigation/app_session.dart';
import 'package:quanlycongviecapp/navigation/theme_controller.dart';
import 'package:quanlycongviecapp/screens/tasks/add_edit_task_screen.dart';
import 'package:quanlycongviecapp/services/connectivity_service.dart';
import 'package:quanlycongviecapp/widgets/profile_card.dart';

const _sizes = <String, Size>{
  '360x800': Size(360, 800),
  '390x844': Size(390, 844),
  '412x915': Size(412, 915),
  '430x932': Size(430, 932),
};

const _tabTitles = ['Tổng quan', 'Bước xử lý', 'Việc cần làm', 'Mốc thời gian', 'Tiền', 'Cộng tác viên', 'Tài liệu'];

/// Cuộn tới khi [finder] tồn tại VÀ nằm gọn trong khung nhìn hiện tại —
/// tự viết thay vì dùng `dragUntilVisible` vì helper đó chỉ kiểm tra widget
/// có tồn tại trong cây (kể cả khi chỉ được dựng trước nhờ cacheExtent của
/// ListView, chưa thực sự cuộn tới), dẫn tới tap trượt ra ngoài màn hình ở
/// những khung hình cao vừa phải (VD 412x915) khi Dashboard có nhiều mục
/// xem nhanh phía trên.
Future<void> _scrollUntilFullyVisible(WidgetTester tester, Finder finder, {int maxIterations = 50}) async {
  final scrollable = find.byType(Scrollable).first;
  // Bước 1: cuộn thô tới khi widget được DỰNG trong cây (ListView ảo hóa
  // chỉ dựng phần tử trong/gần khung nhìn).
  for (var i = 0; i < maxIterations && finder.evaluate().isEmpty; i++) {
    await tester.drag(scrollable, const Offset(0, -250));
    await tester.pump();
  }
  expect(finder.evaluate(), isNotEmpty, reason: 'Không tìm thấy widget sau $maxIterations lần cuộn');
  // Bước 2: dùng ensureVisible để định vị chính xác (đáng tin cậy hơn cuộn
  // thủ công vì tính toán đúng offset cần thiết thay vì đoán từng bước).
  await tester.ensureVisible(finder);
  await tester.pump();
}

void main() {
  for (final entry in _sizes.entries) {
    testWidgets('Không lỗi layout ở ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final session = AppSession();
      await session.enterDemoMode();
      await tester.pumpWidget(QlcvApp(
        session: session,
        themeController: ThemeController(),
        connectivityService: ConnectivityService(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'Dashboard (${entry.key})');

      // Nhóm / Lịch / Thống kê / Cài đặt — chuyển qua từng tab dưới cùng.
      for (final label in ['Nhóm', 'Lịch', 'Thống kê', 'Cài đặt', 'Trang chủ']) {
        await tester.tap(find.text(label).last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: '$label (${entry.key})');
      }

      // Hồ sơ 360°: mở một hồ sơ rồi lướt qua đủ 7 tab. Cuộn tới một hồ sơ
      // CỤ THỂ (khớp đúng 1 kết quả) thay vì find.byType(ProfileCard) —
      // một khi nhiều card cùng lọt vào khung nhìn, WidgetController không
      // còn xác định được phần tử duy nhất để hoàn tất dragUntilVisible.
      final overdueText = find.textContaining('Làm căn cước công dân gắn chip');
      await _scrollUntilFullyVisible(tester, overdueText);
      final overdueCard = find.ancestor(of: overdueText, matching: find.byType(ProfileCard));
      await tester.tap(overdueCard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'ProfileDetail mở (${entry.key})');

      // TabBar cuộn ngang (isScrollable: true) nên ở màn hình hẹp, các tab
      // sau không nằm sẵn trong khung nhìn — cần ensureVisible trước khi
      // chạm, tương tự cách xử lý cuộn dọc ở trên.
      for (final tabLabel in _tabTitles) {
        final tabFinder = find.text(tabLabel).last;
        await tester.ensureVisible(tabFinder);
        await tester.pump();
        await tester.tap(tabFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: 'ProfileDetail tab "$tabLabel" (${entry.key})');

        // Mở AddEditTaskScreen bằng Navigator.push trực tiếp thay vì mô
        // phỏng chạm vào nút "+" — nút đó nằm trong SectionCard lồng sâu
        // trong Scrollable + TabBarView, khiến việc tính toạ độ chạm của
        // WidgetController không ổn định giữa các khung hình; mục tiêu ở
        // đây là kiểm tra AddEditTaskScreen không vỡ layout ở từng kích
        // thước, không phải kiểm tra lại thao tác điều hướng (đã có test
        // riêng trong widget_test.dart).
        if (tabLabel == 'Việc cần làm') {
          final navContext = tester.element(find.byType(Scaffold).first);
          Navigator.of(navContext).push(
            MaterialPageRoute(builder: (_) => AddEditTaskScreen(profileId: session.repository!.profiles.first.id)),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: 'AddEditTaskScreen (${entry.key})');
          expect(find.byType(AddEditTaskScreen), findsOneWidget);
          Navigator.of(tester.element(find.byType(AddEditTaskScreen))).pop();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
    });
  }
}
