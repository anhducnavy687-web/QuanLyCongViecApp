import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_session.dart';
import 'navigation/root_screen.dart';
import 'navigation/theme_controller.dart';
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
            home: const RootScreen(),
          );
        },
      ),
    );
  }
}
