import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/preview/mobile_preview_frame.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_session.dart';
import 'navigation/root_screen.dart';
import 'navigation/theme_controller.dart';
import 'repositories/app_repository.dart';
import 'services/connectivity_service.dart';

class QlcvApp extends StatelessWidget {
  const QlcvApp({
    super.key,
    required this.session,
    required this.themeController,
    required this.connectivityService,
  });

  final AppSession session;
  final ThemeController themeController;
  final ConnectivityService connectivityService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSession>.value(value: session),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<ConnectivityService>.value(value: connectivityService),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: theme.mode,
            locale: const Locale('vi', 'VN'),
            supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // `builder` chạy ở một điểm NẰM TRÊN Navigator nội bộ của
            // MaterialApp (child chính là Navigator đó). Đây là lý do
            // AppRepository được provide Ở ĐÂY thay vì bên trong MainShell:
            // nếu chỉ provide bên trong nội dung của route "home" (như
            // trước đây), mọi route được push sau đó (ProfileDetailScreen,
            // AddEditProfileScreen...) sẽ nằm ở một OverlayEntry khác — là
            // "anh em" chứ không phải "con cháu" của route home trong cây
            // widget — nên sẽ KHÔNG thấy được Provider đó và ném
            // ProviderNotFoundException. Đặt Provider bên trên Navigator
            // như thế này đảm bảo MỌI route (kể cả các route được push)
            // đều đọc được AppRepository, trên cả Android/iOS lẫn Web.
            //
            // Trên Web, sau đó còn bọc thêm MobilePreviewFrame — chỉ là
            // một container hiển thị, không có màn hình/logic riêng cho
            // web.
            builder: (context, child) {
              final repo = context.watch<AppSession>().repository;
              Widget content = repo == null
                  ? child!
                  : ChangeNotifierProvider<AppRepository>.value(
                      value: repo,
                      child: child!,
                    );
              if (kIsWeb) {
                content = MobilePreviewFrame(child: content);
              }
              return content;
            },
            home: const RootScreen(),
          );
        },
      ),
    );
  }
}
