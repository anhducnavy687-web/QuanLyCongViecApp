import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/context_extensions.dart';
import '../../navigation/app_session.dart';
import '../../navigation/theme_controller.dart';
import '../../repositories/demo_repository.dart';
import '../../services/connectivity_service.dart';
import '../collaborators/collaborators_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final themeController = context.watch<ThemeController>();
    final connectivity = context.watch<ConnectivityService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionLabel('Tài khoản'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: context.colors.primaryContainer,
                backgroundImage: session.user?.photoUrl != null
                    ? NetworkImage(session.user!.photoUrl!)
                    : null,
                child: session.user?.photoUrl == null
                    ? const Icon(Icons.person_outline_rounded)
                    : null,
              ),
              title: Text(session.isDemoMode ? 'Chế độ Demo' : (session.user?.displayName ?? 'Người dùng')),
              subtitle: Text(
                session.isDemoMode
                    ? 'Dữ liệu chỉ lưu tạm trên máy, sẽ mất khi thoát app'
                    : (session.user?.email ?? ''),
              ),
              trailing: TextButton(
                onPressed: () => _confirmSignOut(context, session),
                child: Text(session.isDemoMode ? 'Thoát Demo' : 'Đăng xuất'),
              ),
            ),
          ),
          _SectionLabel('Giao diện'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: RadioGroup<ThemeMode>(
              groupValue: themeController.mode,
              onChanged: (v) => themeController.setMode(v!),
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text('Theo hệ thống'),
                    value: ThemeMode.system,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('Sáng'),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('Tối'),
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
          ),
          _SectionLabel('Dữ liệu'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.people_outline_rounded),
                  title: const Text('Quản lý cộng tác viên'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CollaboratorsScreen()),
                  ),
                ),
                SwitchListTile(
                  secondary: Icon(
                    connectivity.isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  ),
                  title: const Text('Trạng thái mạng (giả lập)'),
                  subtitle: Text(connectivity.isOnline ? 'Đang online' : 'Đang offline'),
                  value: connectivity.isOnline,
                  onChanged: session.repository is DemoRepository
                      ? (v) => (session.repository as DemoRepository).setSimulatedOnline(v)
                      : null,
                ),
              ],
            ),
          ),
          _SectionLabel('Giới thiệu'),
          const Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text(AppConstants.appName),
              subtitle: Text('Phiên bản 1.0.0 — Kiến trúc sẵn sàng cho Firebase'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AppSession session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(session.isDemoMode ? 'Thoát chế độ Demo?' : 'Đăng xuất?'),
        content: Text(
          session.isDemoMode
              ? 'Toàn bộ dữ liệu demo hiện tại sẽ mất.'
              : 'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              session.signOut();
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        text,
        style: context.textTheme.labelLarge?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
