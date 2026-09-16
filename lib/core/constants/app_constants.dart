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

  /// Lý do "Đang chờ" thường gặp — hiển thị dưới dạng chip chọn nhanh trong
  /// form hồ sơ/việc cần làm. Chọn "Khác" thì người dùng tự gõ lý do; đây chỉ
  /// là gợi ý điền nhanh, KHÔNG phải enum — field `waitingReason` vẫn là
  /// String tự do để không phá dữ liệu cũ.
  static const List<String> waitingReasonPresets = <String>[
    'Chờ khách hàng',
    'Chờ bên liên quan',
    'Chờ hồ sơ/tài liệu',
    'Chờ phản hồi',
    'Chờ thanh toán',
    'Chờ phê duyệt',
    'Khác',
  ];

  /// Ngưỡng ngày để chia nhóm hiển thị "Sắp tới" trên Dashboard.
  static const int upcomingNearBucketDays = 3;
  static const int upcomingFarBucketDays = 7;

  static const String prefsKeyThemeMode = 'settings.themeMode';
  static const String prefsKeyDemoMode = 'settings.demoMode';
  static const String prefsKeySessionUid = 'settings.sessionUid';
}
