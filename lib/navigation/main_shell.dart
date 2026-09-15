import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/app_repository.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/groups/groups_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/profiles/add_edit_profile_screen.dart';
import '../screens/profiles/profile_detail_screen.dart';
import '../screens/profiles/profile_picker_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/statistics/statistics_screen.dart';
import '../screens/tasks/add_edit_task_screen.dart';
import 'app_session.dart';

/// Khung điều hướng chính: 5 tab (Trang chủ, Nhóm, Lịch, Thống kê, Cài đặt)
/// + nút nổi "+ Thêm hồ sơ".
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    _TabInfo('Trang chủ', Icons.dashboard_outlined, Icons.dashboard_rounded),
    _TabInfo('Nhóm', Icons.folder_outlined, Icons.folder_rounded),
    _TabInfo('Lịch', Icons.calendar_month_outlined, Icons.calendar_month_rounded),
    _TabInfo('Thống kê', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
    _TabInfo('Cài đặt', Icons.settings_outlined, Icons.settings_rounded),
  ];

  final _screens = const [
    DashboardScreen(),
    GroupsScreen(),
    CalendarScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // AppRepository được provide ở lib/app.dart (trong MaterialApp.builder,
    // NẰM TRÊN Navigator) để mọi route được push từ bất kỳ đâu — kể cả từ
    // ngoài MainShell — đều đọc được, không riêng gì nội dung trong
    // IndexedStack bên dưới. Ở đây chỉ cần đảm bảo dữ liệu đã sẵn sàng.
    final repo = context.watch<AppSession>().repository;
    if (repo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      floatingActionButton: _index == 0 || _index == 1
          ? FloatingActionButton(
              onPressed: () => _showQuickActions(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }

  Future<void> _showQuickActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Tạo mới', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_rounded),
              title: const Text('Hồ sơ mới'),
              onTap: () => Navigator.pop(ctx, 'profile'),
            ),
            ListTile(
              leading: const Icon(Icons.checklist_rounded),
              title: const Text('Việc cần làm mới'),
              onTap: () => Navigator.pop(ctx, 'task'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money_rounded),
              title: const Text('Giao dịch mới'),
              onTap: () => Navigator.pop(ctx, 'transaction'),
            ),
            ListTile(
              leading: const Icon(Icons.sticky_note_2_rounded),
              title: const Text('Ghi chú mới'),
              onTap: () => Navigator.pop(ctx, 'note'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case 'profile':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditProfileScreen()),
        );
        break;
      case 'task':
        final repo = context.read<AppRepository>();
        if (repo.profiles.isEmpty) {
          _showNeedProfileMessage(context);
          return;
        }
        final profileId = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => const ProfilePickerScreen()),
        );
        if (profileId != null && context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddEditTaskScreen(profileId: profileId)),
          );
        }
        break;
      case 'transaction':
        {
          final repo = context.read<AppRepository>();
          if (repo.profiles.isEmpty) {
            _showNeedProfileMessage(context);
            return;
          }
          final profileId = await Navigator.of(context).push<String>(
            MaterialPageRoute(builder: (_) => const ProfilePickerScreen()),
          );
          if (profileId != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfileDetailScreen(profileId: profileId, initialTabIndex: 4),
              ),
            );
          }
          break;
        }
      case 'note':
        {
          final repo = context.read<AppRepository>();
          if (repo.profiles.isEmpty) {
            _showNeedProfileMessage(context);
            return;
          }
          final profileId = await Navigator.of(context).push<String>(
            MaterialPageRoute(builder: (_) => const ProfilePickerScreen()),
          );
          if (profileId != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfileDetailScreen(profileId: profileId, initialTabIndex: 0),
              ),
            );
          }
          break;
        }
    }
  }

  void _showNeedProfileMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hãy tạo hồ sơ trước khi thêm mục này.')),
    );
  }
}

class _TabInfo {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _TabInfo(this.label, this.icon, this.selectedIcon);
}
