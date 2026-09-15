import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/context_extensions.dart';
import '../../navigation/app_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;

  Future<void> _signIn(AppSession session) async {
    setState(() => _busy = true);
    final ok = await session.signInWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok && session.lastError != null) {
      context.showSnackBar(session.lastError!, isError: true);
    }
  }

  Future<void> _enterDemo(AppSession session) async {
    setState(() => _busy = true);
    await session.enterDemoMode();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(Icons.work_outline_rounded, size: 48, color: colors.onPrimaryContainer),
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Quản lý nhóm công việc, hồ sơ, tiến độ, tiền bạc và\ncộng tác viên trong một ứng dụng duy nhất.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: _busy ? null : () => _signIn(session),
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: const Text('Đăng nhập bằng Google'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _enterDemo(session),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Dùng thử ở Chế độ Demo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Chế độ Demo không cần đăng nhập, dữ liệu chỉ lưu tạm '
                'trên máy và sẽ mất khi thoát ứng dụng.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const Spacer(flex: 2),
              if (_busy) const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
