import 'package:flutter/material.dart';

import 'preview_device.dart';

const double _toolbarHeight = 52.0;
const double _framePadding = 24.0;
const Color _outerBackground = Color(0xFF20232A);

/// Khung xem trước dạng điện thoại, DÀNH RIÊNG cho Web Preview.
///
/// Đây KHÔNG phải là một bộ UI riêng cho web — nó chỉ là một CONTAINER bọc
/// ngoài toàn bộ cây widget hiện có của app (Navigator, tất cả các màn
/// hình trong `lib/screens/`), ép nó vào kích thước và tỉ lệ của một điện
/// thoại thật, căn giữa trên nền trình duyệt, để có cảm giác đang xem app
/// trên điện thoại thay vì một trang web desktop.
///
/// Không có screen/widget nào bị nhân bản cho web — toàn bộ UI bên trong
/// khung vẫn là `lib/screens/` và `lib/widgets/` dùng chung với Android/iOS.
class MobilePreviewFrame extends StatefulWidget {
  final Widget child;

  const MobilePreviewFrame({super.key, required this.child});

  @override
  State<MobilePreviewFrame> createState() => _MobilePreviewFrameState();
}

class _MobilePreviewFrameState extends State<MobilePreviewFrame> {
  PreviewDevicePreset _device = PreviewDevicePreset.iphone15;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      // Navigator RIÊNG chỉ để phục vụ dropdown "Preview Device" (DropdownButton
      // cần một Navigator ancestor để hiển thị menu). Navigator thật của app
      // (dùng cho mọi điều hướng giữa các màn hình) nằm bên TRONG
      // `widget.child`, hoàn toàn độc lập — khung Preview không can thiệp
      // vào điều hướng của app.
      child: Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => Material(
            // Chỉ dùng để cung cấp Material ancestor cho toolbar — không
            // liên quan tới Material Theme của app thật bên trong khung.
            color: _outerBackground,
            child: SafeArea(
              child: Column(
                children: [
                  _PreviewToolbar(
                    selected: _device,
                    onChanged: (d) => setState(() => _device = d),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableW = (constraints.maxWidth - _framePadding * 2)
                            .clamp(1.0, double.infinity);
                        final availableH = (constraints.maxHeight - _framePadding * 2)
                            .clamp(1.0, double.infinity);
                        final scale = [
                          1.0,
                          availableW / _device.width,
                          availableH / _device.height,
                        ].reduce((a, b) => a < b ? a : b);

                        final scaledW = _device.width * scale;
                        final scaledH = _device.height * scale;

                        return Center(
                          child: SizedBox(
                            width: scaledW,
                            height: scaledH,
                            child: Transform.scale(
                              scale: scale,
                              alignment: Alignment.topLeft,
                              child: SizedBox(
                                width: _device.width,
                                height: _device.height,
                                child: _PhoneBezel(
                                  child: MediaQuery(
                                    data: MediaQuery.of(context).copyWith(
                                      size: Size(_device.width, _device.height),
                                      devicePixelRatio: 1.0,
                                      padding: EdgeInsets.zero,
                                      viewPadding: EdgeInsets.zero,
                                      viewInsets: EdgeInsets.zero,
                                      textScaler: TextScaler.noScaling,
                                    ),
                                    child: widget.child,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vỏ bo góc kiểu điện thoại bọc quanh nội dung app — chỉ trang trí, không
/// chiếm không gian layout của nội dung bên trong (nội dung vẫn có đúng
/// kích thước logic của thiết bị được chọn).
class _PhoneBezel extends StatelessWidget {
  final Widget child;
  const _PhoneBezel({required this.child});

  @override
  Widget build(BuildContext context) {
    const radius = 32.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFF0B0C0F), width: 8),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 8),
        child: child,
      ),
    );
  }
}

class _PreviewToolbar extends StatelessWidget {
  final PreviewDevicePreset selected;
  final ValueChanged<PreviewDevicePreset> onChanged;

  const _PreviewToolbar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF14161B),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2D35))),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_iphone_rounded, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Web Mobile Preview',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const Text(
            'Preview Device',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<PreviewDevicePreset>(
              value: selected,
              dropdownColor: const Color(0xFF20232A),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
              items: [
                for (final d in PreviewDevicePreset.all)
                  DropdownMenuItem(
                    value: d,
                    child: Text('${d.name}  (${d.width.toInt()}×${d.height.toInt()})'),
                  ),
              ],
              onChanged: (d) {
                if (d != null) onChanged(d);
              },
            ),
          ),
        ],
      ),
    );
  }
}
