# Quản Lý Công Việc (QuanLyCongViecApp)

Ứng dụng Flutter đa nền tảng quản lý hồ sơ/công việc cá nhân theo mô hình
CRM cá nhân: nhóm công việc, hồ sơ, tiến độ theo bước, mốc thời gian, tiền
bạc, cộng tác viên/hoa hồng, tài liệu đính kèm, lịch và thống kê.

**Responsive Web App là nền tảng triển khai CHÍNH thức của ứng dụng** —
người dùng mở thẳng URL Netlify trên trình duyệt (điện thoại, máy tính
bảng, máy tính) để dùng toàn bộ tính năng, **không cần cài đặt gì**. Luồng
hoạt động: `GitHub → Netlify build (Flutter Web) → HTTPS URL → Trình duyệt
→ Firebase (Auth + Firestore)`. Giao diện tự thích ứng theo kích thước màn
hình (điện thoại/tablet/desktop — xem mục **3** và
[docs/ui-structure.md](docs/ui-structure.md)). **Android và iOS vẫn được hỗ
trợ build** (không có thay đổi native nào trong phase này) nhưng không còn
là mục tiêu triển khai ưu tiên duy nhất.

Ứng dụng có **Demo Mode** — chạy được ngay, xem đầy đủ giao diện và dữ liệu
mẫu phong phú **mà không cần cấu hình Firebase**. Khi đăng nhập bằng Google
qua Firebase Auth, Firestore là nguồn dữ liệu duy nhất (single source of
truth) — dùng cùng một tài khoản Google trên điện thoại, máy tính bảng,
laptop đều thấy cùng một dữ liệu, đồng bộ realtime (xem
[docs/firebase-setup.md](docs/firebase-setup.md)).

## Tài liệu liên quan

- [docs/architecture.md](docs/architecture.md) — kiến trúc tổng thể, Demo Mode vs Firebase Mode, kiến trúc responsive
- [docs/data-model.md](docs/data-model.md) — mô tả toàn bộ model dữ liệu
- [docs/firestore-schema.md](docs/firestore-schema.md) — cấu trúc Firestore + Storage
- [docs/firebase-setup.md](docs/firebase-setup.md) — hướng dẫn cấu hình Firebase từ đầu
- [docs/ui-structure.md](docs/ui-structure.md) — cấu trúc màn hình, điều hướng & responsive layout
- [docs/deploy-netlify.md](docs/deploy-netlify.md) — deploy bản Web production lên Netlify để có URL chính thức

## 1. Cài đặt Flutter

Yêu cầu Flutter SDK kênh stable (dự án dùng Dart SDK `^3.13.3`, tương ứng
Flutter 3.35+). Cài đặt theo hướng dẫn chính thức:
https://docs.flutter.dev/get-started/install

Kiểm tra môi trường:

```bash
flutter doctor
```

Cài dependency của dự án:

```bash
flutter pub get
```

## 2. Chạy ứng dụng ở Demo Mode (khuyến nghị khi mới clone dự án)

Không cần bất kỳ cấu hình Firebase nào. Chạy:

```bash
flutter run
```

Ở màn hình Đăng nhập, chọn **"Dùng thử ở Chế độ Demo"**. Ứng dụng sẽ nạp
sẵn:

- 4 nhóm công việc (Đất đai, Hành chính, Hồ sơ cá nhân, Khác)
- 11 hồ sơ với đủ trạng thái: quá hạn, đến hạn hôm nay, sắp đến hạn, không
  có deadline, đang xử lý, đang chờ, hoàn thành, đã hủy
- Nhiều bước xử lý, mốc thời gian, giao dịch tiền, chi phí
- 4 cộng tác viên với hoa hồng và lịch sử trả hoa hồng
- Tài liệu đính kèm mẫu

> Dữ liệu Demo chỉ lưu trong bộ nhớ của phiên chạy hiện tại — thoát app là
> mất, đúng như một bản demo độc lập với backend.

## 3. Web — Responsive Web App (nền tảng triển khai chính)

Bản production (Netlify, `flutter build web --release`) hiển thị **toàn bộ
chiều rộng trình duyệt**, không có khung điện thoại/chrome giả lập nào —
giao diện tự thích ứng theo 3 mức kích thước (xem
[`lib/core/responsive/responsive.dart`](lib/core/responsive/responsive.dart)):

| Kích thước | Điều hướng | Bố cục |
|---|---|---|
| Compact `< 600px` (điện thoại) | `NavigationBar` dưới cùng + FAB | 1 cột, form 1 cột, dialog dạng bottom sheet |
| Medium `600–1024px` (tablet) | `NavigationRail` thu gọn | 2–3 cột, tận dụng không gian rộng hơn |
| Expanded `> 1024px` (desktop) | `NavigationRail` mở rộng (sidebar) | Nội dung giới hạn chiều rộng tối đa + căn giữa, form 2 cột cho các trường ngắn đi cặp, dialog căn giữa |

**Cách chạy khi phát triển:**

```bash
flutter pub get
flutter run -d chrome
```

Trên Windows có thể double-click `scripts/run_preview.bat` để chạy 2 lệnh
trên tự động.

### Chế độ xem trước điện thoại khi phát triển (chỉ dev/debug)

Khi chạy bằng `flutter run -d chrome` (debug/dev, `kReleaseMode == false`),
`MobilePreviewFrame` (`lib/core/preview/mobile_preview_frame.dart`) vẫn
được bật để tiện xem/kiểm tra giao diện điện thoại nhanh trên Chrome mà
không cần máy thật/emulator — Chrome hiển thị một khung điện thoại dọc, bo
góc, căn giữa (mặc định **iPhone 15, 390×844**), có dropdown **"Preview
Device"** để đổi kích thước (Small Android, Android 6.5", iPhone 15,
iPhone Pro Max).

**Bản build production (Netlify, `flutter build web --release`) KHÔNG BAO
GIỜ hiển thị khung này** — gate là `kIsWeb && !kReleaseMode` trong
`lib/app.dart`, một cờ biên dịch (compile-time), không phải kiểm tra theo
tên miền — nên người dùng cuối luôn thấy app chiếm toàn bộ viewport trình
duyệt, responsive theo bảng ở trên.

Bên trong (dù có khung Preview hay không), chọn **"Dùng thử ở Chế độ
Demo"** để dùng ngay không cần đăng nhập Google, không cần Firestore.

**Giới hạn trên Web** (không ảnh hưởng tới Android/iOS):

- Các thao tác file thật (chọn file, chụp ảnh, mở file, chia sẻ file nhị
  phân) dùng `dart:io`/`open_filex`/`path_provider` — các package này
  **không hỗ trợ Web**, nên trên trình duyệt các thao tác này hiển thị
  thông báo lỗi thân thiện thay vì thao tác thật (không crash). Riêng chức
  năng **Trích ngang → Sao chép/Chia sẻ văn bản** vẫn hoạt động bình
  thường trên web.
- Đăng nhập Google thật cần cấu hình `flutterfire configure` cho target
  web (xem [docs/firebase-setup.md](docs/firebase-setup.md)) và thêm tên
  miền Netlify vào **Authorized domains** của Firebase Authentication;
  Demo Mode không cần bước này.

### Có URL online để mở trên mọi thiết bị (không cần cài gì)

Muốn có một link `https://....netlify.app` chính thức để mở app trên bất
kỳ điện thoại/máy tính bảng/laptop nào mà **không cần cài Flutter/Git**
trên thiết bị đó? Xem hướng dẫn kết nối repo này với Netlify (~2 phút, qua
giao diện web, Netlify tự build):
**[docs/deploy-netlify.md](docs/deploy-netlify.md)**.

## 4. Cấu hình Firebase (tùy chọn, để đồng bộ nhiều thiết bị)

Xem hướng dẫn chi tiết từng bước tại
**[docs/firebase-setup.md](docs/firebase-setup.md)**. Tóm tắt:

1. Tạo Firebase project tại https://console.firebase.google.com
2. Cài FlutterFire CLI: `dart pub global activate flutterfire_cli`
3. `firebase login`
4. `flutterfire configure` (sinh ra `lib/firebase_options.dart` và các file
   cấu hình native cho Android/iOS)
5. Bật Google Sign-In trong Firebase Authentication
6. Tạo Cloud Firestore (chế độ Production)
7. Tạo Firebase Storage
8. Deploy `firestore.rules` và `storage.rules` có sẵn trong repo:
   ```bash
   firebase deploy --only firestore:rules,storage:rules
   ```

Nếu Firebase **chưa** được cấu hình, ứng dụng vẫn chạy bình thường ở Demo
Mode — nút "Đăng nhập bằng Google" sẽ báo lỗi tiếng Việt thân thiện thay vì
làm crash ứng dụng.

## 5. Chạy trên Android

```bash
flutter run -d <android-device-or-emulator-id>
```

Liệt kê thiết bị: `flutter devices`.

## 6. Chuẩn bị iOS

Trên máy macOS có Xcode:

```bash
cd ios
pod install
cd ..
flutter run -d <ios-device-or-simulator-id>
```

Nếu đã chạy `flutterfire configure`, đảm bảo `GoogleService-Info.plist`
được thêm vào target Runner trong Xcode.

## 7. Build APK

```bash
# Bản debug (nhanh, dùng để kiểm tra)
flutter build apk --debug

# Bản release (đã tối ưu, cần ký ứng dụng cho production)
flutter build apk --release
```

File APK nằm tại `build/app/outputs/flutter-apk/`.

## 8. Kiểm tra chất lượng code

```bash
flutter analyze
flutter test
```

## Cấu trúc thư mục chính

```
lib/
├── main.dart               # Điểm khởi động, khởi tạo locale/session
├── app.dart                 # MaterialApp, theme, Provider gốc
├── core/                    # constants, theme, utils, extensions, preview (Web) dùng chung
├── models/                  # Toàn bộ model dữ liệu (thuần Dart, có JSON)
├── repositories/            # AppRepository (interface) + DemoRepository + FirebaseRepository
├── services/                 # AuthService, FileService, ConnectivityService...
├── screens/                  # Màn hình theo module (home, groups, profiles, calendar...)
├── widgets/                   # Widget dùng lại nhiều nơi (ProfileCard, MoneyBar...)
└── navigation/                # AppSession (điều phối phiên), RootScreen, MainShell
```

Xem chi tiết kiến trúc tại [docs/architecture.md](docs/architecture.md).

## Roadmap (chưa triển khai)

Ứng dụng hiện **chưa có** chức năng backup/export dữ liệu. Dự kiến bổ sung
ở các phase sau:

- Xuất dữ liệu ra Excel
- Sao lưu (backup) toàn bộ dữ liệu ra JSON
- Nhập lại (import/restore) từ file backup
- Sao lưu định kỳ tự động

Phase 1.2 (Responsive Web App) không thay đổi phạm vi này.
