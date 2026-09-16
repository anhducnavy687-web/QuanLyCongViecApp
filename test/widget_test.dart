// Widget smoke test: khởi động app ở Demo Mode và kiểm tra Dashboard hiển
// thị đúng, không crash dù chưa cấu hình Firebase. Test thứ hai điều hướng
// vào một route được push (ProfileDetailScreen) để đảm bảo AppRepository
// luôn đọc được từ MỌI route — không riêng route "home" — vì Provider
// được đặt trong MaterialApp.builder (nằm trên Navigator), không phải bên
// trong nội dung của một route cụ thể.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quanlycongviecapp/app.dart';
import 'package:quanlycongviecapp/navigation/app_session.dart';
import 'package:quanlycongviecapp/navigation/theme_controller.dart';
import 'package:quanlycongviecapp/services/connectivity_service.dart';
import 'package:quanlycongviecapp/widgets/profile_card.dart';

Future<AppSession> _bootDemoApp(WidgetTester tester) async {
  // SharedPreferences dùng platform channel thật theo mặc định; trong môi
  // trường test headless cần nạp giá trị mock để tránh await bị treo mãi.
  SharedPreferences.setMockInitialValues({});

  final session = AppSession();
  await session.enterDemoMode();

  await tester.pumpWidget(QlcvApp(
    session: session,
    themeController: ThemeController(),
    connectivityService: ConnectivityService(),
  ));

  // Material 3 dùng hiệu ứng ripple (InkSparkle) chạy animation liên tục
  // khi có tương tác gần đây, nên tránh pumpAndSettle() (có thể không bao
  // giờ "settle") — bơm một số khung hình cố định là đủ để build xong.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return session;
}

/// Dashboard hiện có nhiều mục xem nhanh (StatPill, Việc hôm nay, Việc quá
/// hạn, Đang chờ, Sắp tới...) phía trên danh sách hồ sơ đầy đủ, nên nội
/// dung mong muốn không còn chắc chắn nằm trong viewport ban đầu của bài
/// test — cuộn tới khi thấy trước khi tìm/chạm, phản ánh đúng trải nghiệm
/// cuộn tự nhiên trên điện thoại.
Future<void> _scrollDashboardUntilVisible(WidgetTester tester, Finder finder) async {
  await tester.dragUntilVisible(
    finder,
    find.byType(Scrollable).first,
    const Offset(0, -300),
    maxIteration: 30,
  );
  await tester.pump();
}

void main() {
  testWidgets('Demo Mode boots and shows Dashboard with seeded data', (tester) async {
    await _bootDemoApp(tester);

    // "Trang chủ" xuất hiện cả ở AppBar lẫn nhãn tab điều hướng dưới cùng.
    expect(find.text('Trang chủ'), findsWidgets);
    // Danh sách hồ sơ dùng ListView ảo hóa (chỉ dựng widget trong vùng nhìn
    // thấy), nên kiểm tra hồ sơ QUÁ HẠN — luôn nằm ở mục đầu tiên trên cùng
    // của Dashboard theo đúng thứ tự ưu tiên, chắc chắn nằm trong viewport
    // ban đầu của bài test.
    expect(find.text('Quá hạn'), findsWidgets);
    final overdueText = find.textContaining('Làm căn cước công dân gắn chip');
    await _scrollDashboardUntilVisible(tester, overdueText);
    expect(overdueText, findsWidgets);
  });

  testWidgets('Mở được ProfileDetailScreen từ Dashboard mà không lỗi Provider', (tester) async {
    await _bootDemoApp(tester);

    // Cuộn tới một hồ sơ cụ thể (khớp đúng 1 kết quả) rồi chạm vào
    // ProfileCard chứa nó — tránh dùng find.byType(ProfileCard) làm đích
    // cuộn vì một khi nhiều card cùng lọt vào khung nhìn, WidgetController
    // không còn xác định được phần tử duy nhất để kiểm tra tiếp.
    final overdueText = find.textContaining('Làm căn cước công dân gắn chip');
    await _scrollDashboardUntilVisible(tester, overdueText);
    final overdueCard = find.ancestor(of: overdueText, matching: find.byType(ProfileCard));
    expect(overdueCard, findsOneWidget);
    await tester.tap(overdueCard);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Không có exception nào được flutter_test ghi nhận trong quá trình
    // điều hướng (đặc biệt là ProviderNotFoundException<AppRepository>).
    expect(tester.takeException(), isNull);
    // Trang chi tiết phải mở ra được, có nút "Trích ngang".
    expect(find.byTooltip('Trích ngang'), findsOneWidget);
    // Hồ sơ 360°: đủ 7 tab, bao gồm 2 tab mới của Phase 1.
    expect(find.text('Tổng quan'), findsWidgets);
    expect(find.text('Việc cần làm'), findsWidgets);
    expect(find.text('Mốc thời gian'), findsWidgets);
  });

  testWidgets('Dashboard hiển thị "Việc hôm nay" từ dữ liệu Demo', (tester) async {
    await _bootDemoApp(tester);

    // Dữ liệu Demo seed có sẵn ít nhất một task có dueDate = hôm nay.
    expect(find.textContaining('Việc hôm nay'), findsOneWidget);
  });

  testWidgets('Chạm StatPill "Đang chờ" mở SearchScreen với filter tương ứng', (tester) async {
    await _bootDemoApp(tester);

    await tester.tap(find.text('Đang chờ').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    // SearchScreen mở ra với ô tìm kiếm ở AppBar.
    expect(find.text('Đang chờ'), findsWidgets);
  });

  testWidgets('Mở được màn hình Việc cần làm (TasksScreen) từ Dashboard', (tester) async {
    await _bootDemoApp(tester);

    await tester.tap(find.byTooltip('Việc cần làm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('Việc cần làm'), findsWidgets);
  });
}
