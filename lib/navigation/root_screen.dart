import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/login/login_screen.dart';
import '../screens/splash/splash_screen.dart';
import 'app_session.dart';
import 'main_shell.dart';

/// Widget gốc: lắng nghe [AppSession] và hiển thị Splash / Login / Home
/// tương ứng — đúng luồng "Splash -> Kiểm tra session -> Login/Demo -> Home".
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    switch (session.status) {
      case SessionStatus.loading:
        return const SplashScreen();
      case SessionStatus.needsAuth:
        return const LoginScreen();
      case SessionStatus.demo:
      case SessionStatus.authenticated:
        return const MainShell();
    }
  }
}
