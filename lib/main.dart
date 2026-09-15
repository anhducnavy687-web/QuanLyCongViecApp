import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'navigation/app_session.dart';
import 'navigation/theme_controller.dart';
import 'services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('vi_VN');
  } catch (_) {
    // Không chặn khởi động app nếu không nạp được dữ liệu locale.
  }

  final session = AppSession();
  final themeController = ThemeController();
  final connectivityService = ConnectivityService();

  // Các thao tác này chạy bất đồng bộ; UI hiển thị SplashScreen trong lúc
  // chờ và tự cập nhật khi hoàn tất nhờ ChangeNotifier.
  unawaited(themeController.load());
  unawaited(connectivityService.init());
  unawaited(session.bootstrap());

  runApp(QlcvApp(
    session: session,
    themeController: themeController,
    connectivityService: connectivityService,
  ));
}
