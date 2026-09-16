import 'package:flutter/material.dart';

/// Kích thước màn hình chuẩn hóa theo chiều rộng — dùng thống nhất cho
/// toàn bộ app thay vì mỗi màn hình tự định nghĩa breakpoint riêng.
///
/// - [compact]: điện thoại (< 600px)
/// - [medium]: tablet / cửa sổ desktop nhỏ (600–1024px)
/// - [expanded]: laptop/desktop (> 1024px)
enum ScreenSize { compact, medium, expanded }

/// Breakpoint tập trung — chỉnh ở đây, không rải magic number trong từng
/// màn hình.
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double medium = 600;
  static const double expanded = 1024;

  static ScreenSize sizeOf(double width) {
    if (width >= expanded) return ScreenSize.expanded;
    if (width >= medium) return ScreenSize.medium;
    return ScreenSize.compact;
  }
}

extension ResponsiveContextX on BuildContext {
  double get _width => MediaQuery.sizeOf(this).width;

  ScreenSize get screenSize => ResponsiveBreakpoints.sizeOf(_width);

  bool get isCompact => screenSize == ScreenSize.compact;
  bool get isMedium => screenSize == ScreenSize.medium;
  bool get isExpanded => screenSize == ScreenSize.expanded;

  /// true cho cả medium lẫn expanded — dùng khi một điều chỉnh áp dụng
  /// chung cho "không phải điện thoại".
  bool get isAtLeastMedium => screenSize != ScreenSize.compact;
}

/// Chọn giá trị theo [ScreenSize] hiện tại — tiện cho responsive value
/// (VD: số cột grid, padding...) mà không cần viết if/else lặp lại.
T responsiveValue<T>(
  BuildContext context, {
  required T compact,
  T? medium,
  T? expanded,
}) {
  switch (context.screenSize) {
    case ScreenSize.compact:
      return compact;
    case ScreenSize.medium:
      return medium ?? compact;
    case ScreenSize.expanded:
      return expanded ?? medium ?? compact;
  }
}

/// Khung trang dùng chung: giới hạn chiều rộng nội dung tối đa trên màn
/// hình rộng (desktop) và tự căn giữa, tránh mỗi màn hình tự viết một bộ
/// padding/maxWidth khác nhau. Trên điện thoại, hành vi giữ nguyên như
/// trước (padding ngang cơ bản, rộng hết màn hình).
///
/// Dùng bọc quanh phần BODY của Scaffold (không bọc AppBar/BottomNav).
class ResponsivePage extends StatelessWidget {
  final Widget child;

  /// Chiều rộng tối đa của nội dung trên màn hình rộng. Mặc định phù hợp
  /// cho danh sách/dashboard (1100). Form nên dùng giá trị nhỏ hơn (VD
  /// 720) qua [maxContentWidth].
  final double maxContentWidth;

  /// Padding ngang CỘNG THÊM ngoài padding nội bộ mà chính [child] đã tự
  /// khai báo (VD: `ListView(padding: ...)`). Mặc định 0 — hầu hết màn
  /// hình trong app đã tự quản lý padding ngang cơ bản của mình; giá trị
  /// khác 0 chỉ nên dùng khi [child] KHÔNG có padding ngang riêng (VD
  /// LoginScreen dùng [maxContentWidth] để giới hạn độ rộng card mà
  /// không cần padding thêm vì đã có Padding lồng bên trong).
  final double horizontalPadding;

  const ResponsivePage({
    super.key,
    required this.child,
    this.maxContentWidth = 1100,
    this.horizontalPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final contentWidth = width > maxContentWidth + horizontalPadding * 2
            ? maxContentWidth
            : width - horizontalPadding * 2;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentWidth.clamp(0, double.infinity),
            child: child,
          ),
        );
      },
    );
  }
}

/// Mở form thêm/sửa theo đúng pattern của từng kích thước màn hình:
/// - Compact (điện thoại): bottom sheet trượt lên từ dưới, chiếm gần hết
///   chiều rộng — thao tác một tay, quen thuộc trên mobile.
/// - Medium/Expanded (tablet/desktop): dialog căn giữa với chiều rộng tối
///   đa cố định — tránh form kéo giãn hết một màn hình desktop rộng.
///
/// Dùng thay cho việc gọi thẳng `showModalBottomSheet` ở những nơi hiện
/// đang mở form thêm/sửa (Nhóm, Cộng tác viên...).
Future<T?> showResponsiveFormSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double dialogMaxWidth = 480,
}) {
  if (context.isCompact) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder: builder,
    );
  }
  return showDialog<T>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogMaxWidth),
        child: builder(context),
      ),
    ),
  );
}
