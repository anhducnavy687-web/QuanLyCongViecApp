// Widget smoke test: khởi động app ở Demo Mode và kiểm tra Dashboard hiển
// thị đúng, không crash dù chưa cấu hình Firebase. Test thứ hai điều hướng
// vào một route được push (ProfileDetailScreen) để đảm bảo AppRepository
// luôn đọc được từ MỌI route — không riêng route "home" — vì Provider
// được đặt trong MaterialApp.builder (nằm trên Navigator), không phải bên
// trong nội dung của một route cụ thể.

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
    expect(find.textContaining('Làm căn cước công dân gắn chip'), findsWidgets);
  });

  testWidgets('Mở được ProfileDetailScreen từ Dashboard mà không lỗi Provider', (tester) async {
    await _bootDemoApp(tester);

    expect(find.byType(ProfileCard), findsWidgets);
    await tester.tap(find.byType(ProfileCard).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Không có exception nào được flutter_test ghi nhận trong quá trình
    // điều hướng (đặc biệt là ProviderNotFoundException<AppRepository>).
    expect(tester.takeException(), isNull);
    // Trang chi tiết phải mở ra được, có nút "Trích ngang".
    expect(find.byTooltip('Trích ngang'), findsOneWidget);
  });
}
