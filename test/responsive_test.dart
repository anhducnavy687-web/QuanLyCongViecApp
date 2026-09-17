// Kiểm tra các màn hình chính không bị RenderFlex overflow / lỗi layout ở
// đủ các nhóm kích thước theo spec Phase 1.2 — điện thoại, tablet, desktop
// — vì từ Phase 1.2 Web là nền tảng triển khai chính (không chỉ xem trước
// trên điện thoại), nên bộ test responsive phải phủ cả tablet/desktop.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quanlycongviecapp/app.dart';
import 'package:quanlycongviecapp/navigation/app_session.dart';
import 'package:quanlycongviecapp/navigation/theme_controller.dart';
import 'package:quanlycongviecapp/screens/profiles/profile_detail_screen.dart';
import 'package:quanlycongviecapp/screens/tasks/add_edit_task_screen.dart';
import 'package:quanlycongviecapp/services/connectivity_service.dart';
import 'package:quanlycongviecapp/widgets/profile_card.dart';

const _phoneSizes = <String, Size>{
  '320x568': Size(320, 568),
  '360x800': Size(360, 800),
  '375x812': Size(375, 812),
  '390x844': Size(390, 844),
  '412x915': Size(412, 915),
  '430x932': Size(430, 932),
};

const _tabletSizes = <String, Size>{
  '768x1024': Size(768, 1024),
  '820x1180': Size(820, 1180),
};

const _desktopSizes = <String, Size>{
  '1280x720': Size(1280, 720),
  '1366x768': Size(1366, 768),
  '1440x900': Size(1440, 900),
  '1920x1080': Size(1920, 1080),
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

Future<void> _runLayoutCheck(WidgetTester tester, String sizeLabel) async {
  SharedPreferences.setMockInitialValues({});
  final session = AppSession();
  await session.enterDemoMode();
  await tester.pumpWidget(QlcvApp(
    session: session,
    themeController: ThemeController(),
    connectivityService: ConnectivityService(),
  ));
  await tester.pump();
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'Dashboard ($sizeLabel)');

  // Nhóm / Lịch / Thống kê / Cài đặt — chuyển qua từng tab điều hướng
  // (NavigationBar ở compact, NavigationRail/sidebar ở medium/expanded —
  // cùng nhãn text nên cùng một cách tìm/chạm cho mọi kích thước).
  for (final label in ['Nhóm', 'Lịch', 'Thống kê', 'Cài đặt', 'Trang chủ']) {
    await tester.tap(find.text(label).last);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '$label ($sizeLabel)');
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
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'ProfileDetail mở ($sizeLabel)');

  // TabBar cuộn ngang (isScrollable: true) nên ở màn hình hẹp, các tab
  // sau không nằm sẵn trong khung nhìn — cần ensureVisible trước khi
  // chạm, tương tự cách xử lý cuộn dọc ở trên.
  for (final tabLabel in _tabTitles) {
    final tabFinder = find.text(tabLabel).last;
    await tester.ensureVisible(tabFinder);
    await tester.pump();
    await tester.tap(tabFinder);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'ProfileDetail tab "$tabLabel" ($sizeLabel)');

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
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'AddEditTaskScreen ($sizeLabel)');
      expect(find.byType(AddEditTaskScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(AddEditTaskScreen))).pop();
      await tester.pump();
      await tester.pumpAndSettle();
    }
  }
}

void main() {
  for (final entry in {..._phoneSizes, ..._tabletSizes, ..._desktopSizes}.entries) {
    testWidgets('Không lỗi layout ở ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _runLayoutCheck(tester, entry.key);
    });
  }

  testWidgets(
    'Đổi cỡ màn hình liên tục (1440→800→430→390→1440) không crash, không mất Navigator, không lỗi layout',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
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
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Dashboard ban đầu (1440x900)');

      // Mở một hồ sơ TRƯỚC khi resize để có state điều hướng (route đã
      // push) cần kiểm tra không bị mất qua các lần đổi cỡ màn hình.
      final overdueText = find.textContaining('Làm căn cước công dân gắn chip');
      await _scrollUntilFullyVisible(tester, overdueText);
      final overdueCard = find.ancestor(of: overdueText, matching: find.byType(ProfileCard));
      await tester.tap(overdueCard);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileDetailScreen), findsOneWidget, reason: 'Route ProfileDetail chưa mở trước khi resize');

      const sequence = [Size(1440, 900), Size(800, 1000), Size(430, 932), Size(390, 844), Size(1440, 900)];
      for (final size in sequence) {
        tester.view.physicalSize = size;
        await tester.pump();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Đổi cỡ sang $size');
        // Không nhân đôi route: vẫn đúng MỘT ProfileDetailScreen sau mỗi
        // lần đổi cỡ (không bị build lại thành route mới / không mất
        // route cũ) — đây cũng gián tiếp xác nhận Provider phía trên
        // Navigator vẫn còn nguyên (nếu ProviderNotFoundException xảy ra
        // trong lúc build lại theo kích thước mới, exception đã bị bắt ở
        // dòng expect(takeException) ngay phía trên).
        expect(find.byType(ProfileDetailScreen), findsOneWidget, reason: 'Mất/nhân đôi route sau khi đổi cỡ sang $size');
      }

      // Vẫn có thể pop về Dashboard bình thường — Navigator không bị mất.
      Navigator.of(tester.element(find.byType(ProfileDetailScreen))).pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Pop về Dashboard sau khi đổi cỡ nhiều lần');
      expect(find.byType(ProfileDetailScreen), findsNothing);
    },
  );
}
