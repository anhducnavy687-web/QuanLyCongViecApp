/// Các hằng số dùng chung trong toàn bộ ứng dụng.
class AppConstants {
  AppConstants._();

  static const String appName = 'Quản Lý Công Việc';

  /// Số ngày còn lại để một hồ sơ được xem là "sắp đến hạn".
  static const int upcomingThresholdDays = 3;

  /// Số ngày không có cập nhật bước nào thì coi là "trì trệ".
  static const int stalledThresholdDays = 7;

  /// Các bước công việc mặc định khi tạo hồ sơ mới.
  static const List<String> defaultStageNames = <String>[
    'Nhận hồ sơ',
    'Chuẩn bị',
    'Làm việc với bên liên quan',
    'Hoàn thiện',
    'Bàn giao',
  ];

  /// Các nhóm công việc mặc định (dùng cho lần khởi tạo đầu tiên).
  static const List<String> defaultGroupNames = <String>[
    'Đất đai',
    'Hành chính',
    'Hồ sơ cá nhân',
    'Khác',
  ];

  static const List<String> supportedFileExtensions = <String>[
    'pdf',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  static const String prefsKeyThemeMode = 'settings.themeMode';
  static const String prefsKeyDemoMode = 'settings.demoMode';
  static const String prefsKeySessionUid = 'settings.sessionUid';
}
