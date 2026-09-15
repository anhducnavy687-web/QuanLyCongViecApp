import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/app_repository.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/groups/groups_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/profiles/add_edit_profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/statistics/statistics_screen.dart';
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
    final repo = context.watch<AppSession>().repository;
    if (repo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ChangeNotifierProvider<AppRepository>.value(
      value: repo,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: _screens,
        ),
        floatingActionButton: _index == 0 || _index == 1
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddEditProfileScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Thêm hồ sơ'),
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
      ),
    );
  }
}

class _TabInfo {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _TabInfo(this.label, this.icon, this.selectedIcon);
}
