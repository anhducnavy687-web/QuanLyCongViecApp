import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

/// Quản lý & lưu lại lựa chọn Light/Dark/System của người dùng.
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(AppConstants.prefsKeyThemeMode);
      _mode = _fromString(saved);
      notifyListeners();
    } catch (_) {
      // Giữ mặc định System nếu không đọc được preferences.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefsKeyThemeMode, mode.name);
    } catch (_) {
      // Bỏ qua nếu không lưu được — vẫn áp dụng theme trong phiên hiện tại.
    }
  }

  ThemeMode _fromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
