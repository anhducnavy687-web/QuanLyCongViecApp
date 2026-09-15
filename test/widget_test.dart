// Widget smoke test: khởi động app ở Demo Mode và kiểm tra Dashboard hiển
// thị đúng, không crash dù chưa cấu hình Firebase.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quanlycongviecapp/core/theme/app_theme.dart';
import 'package:quanlycongviecapp/navigation/app_session.dart';
import 'package:quanlycongviecapp/navigation/main_shell.dart';
import 'package:quanlycongviecapp/navigation/theme_controller.dart';
import 'package:quanlycongviecapp/services/connectivity_service.dart';

void main() {
  testWidgets('Demo Mode boots and shows Dashboard with seeded data', (tester) async {
    // SharedPreferences dùng platform channel thật theo mặc định; trong môi
    // trường test headless cần nạp giá trị mock để tránh await bị treo mãi.
    SharedPreferences.setMockInitialValues({});

    final session = AppSession();
    await session.enterDemoMode();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSession>.value(value: session),
          ChangeNotifierProvider<ThemeController>.value(value: ThemeController()),
          ChangeNotifierProvider<ConnectivityService>.value(value: ConnectivityService()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const MainShell(),
        ),
      ),
    );
    // Material 3 dùng hiệu ứng ripple (InkSparkle) chạy animation liên tục
    // khi có tương tác gần đây, nên tránh pumpAndSettle() (có thể không
    // bao giờ "settle") — bơm một số khung hình cố định là đủ để build xong.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // "Trang chủ" xuất hiện cả ở AppBar lẫn nhãn tab điều hướng dưới cùng.
    expect(find.text('Trang chủ'), findsWidgets);
    // Danh sách hồ sơ dùng ListView ảo hóa (chỉ dựng widget trong vùng nhìn
    // thấy), nên kiểm tra hồ sơ QUÁ HẠN — luôn nằm ở mục đầu tiên trên cùng
    // của Dashboard theo đúng thứ tự ưu tiên, chắc chắn nằm trong viewport
    // ban đầu của bài test.
    expect(find.text('Quá hạn'), findsWidgets);
    expect(find.textContaining('Làm căn cước công dân gắn chip'), findsWidgets);
  });
}
