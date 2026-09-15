/// Các preset kích thước thiết bị dùng cho Web Mobile Preview
/// (`lib/core/preview/mobile_preview_frame.dart`). CHỈ dùng khi chạy trên
/// Web — không ảnh hưởng gì tới build Android/iOS thật.
///
/// Kích thước là logical pixel (giống giá trị Flutter dùng cho MediaQuery),
/// không cần mô phỏng chính xác từng pixel của thiết bị thật.
class PreviewDevicePreset {
  final String name;
  final double width;
  final double height;

  const PreviewDevicePreset({
    required this.name,
    required this.width,
    required this.height,
  });

  static const smallAndroid = PreviewDevicePreset(
    name: 'Small Android',
    width: 360,
    height: 800,
  );

  static const android65 = PreviewDevicePreset(
    name: 'Android 6.5"',
    width: 412,
    height: 915,
  );

  static const iphone15 = PreviewDevicePreset(
    name: 'iPhone 15',
    width: 390,
    height: 844,
  );

  static const iphoneProMax = PreviewDevicePreset(
    name: 'iPhone Pro Max',
    width: 430,
    height: 932,
  );

  static const List<PreviewDevicePreset> all = [
    smallAndroid,
    android65,
    iphone15,
    iphoneProMax,
  ];
}
