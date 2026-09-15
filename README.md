# Quản Lý Công Việc (QuanLyCongViecApp)

Ứng dụng Flutter đa nền tảng (Android + iOS) quản lý hồ sơ/công việc cá
nhân theo mô hình CRM cá nhân: nhóm công việc, hồ sơ, tiến độ theo bước,
mốc thời gian, tiền bạc, cộng tác viên/hoa hồng, tài liệu đính kèm, lịch và
thống kê.

Ứng dụng có **Demo Mode** — chạy được ngay, xem đầy đủ giao diện và dữ liệu
mẫu phong phú **mà không cần cấu hình Firebase**. Kiến trúc đã sẵn sàng để
bật đồng bộ nhiều thiết bị qua Firebase khi cần (xem
[docs/firebase-setup.md](docs/firebase-setup.md)).

## Tài liệu liên quan

- [docs/architecture.md](docs/architecture.md) — kiến trúc tổng thể, Demo Mode vs Firebase Mode
- [docs/data-model.md](docs/data-model.md) — mô tả toàn bộ model dữ liệu
- [docs/firestore-schema.md](docs/firestore-schema.md) — cấu trúc Firestore + Storage
- [docs/firebase-setup.md](docs/firebase-setup.md) — hướng dẫn cấu hình Firebase từ đầu
- [docs/ui-structure.md](docs/ui-structure.md) — cấu trúc màn hình & điều hướng

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

## 3. Cấu hình Firebase (tùy chọn, để đồng bộ nhiều thiết bị)

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

## 4. Chạy trên Android

```bash
flutter run -d <android-device-or-emulator-id>
```

Liệt kê thiết bị: `flutter devices`.

## 5. Chuẩn bị iOS

Trên máy macOS có Xcode:

```bash
cd ios
pod install
cd ..
flutter run -d <ios-device-or-simulator-id>
```

Nếu đã chạy `flutterfire configure`, đảm bảo `GoogleService-Info.plist`
được thêm vào target Runner trong Xcode.

## 6. Build APK

```bash
# Bản debug (nhanh, dùng để kiểm tra)
flutter build apk --debug

# Bản release (đã tối ưu, cần ký ứng dụng cho production)
flutter build apk --release
```

File APK nằm tại `build/app/outputs/flutter-apk/`.

## 7. Kiểm tra chất lượng code

```bash
flutter analyze
flutter test
```

## Cấu trúc thư mục chính

```
lib/
├── main.dart               # Điểm khởi động, khởi tạo locale/session
├── app.dart                 # MaterialApp, theme, Provider gốc
├── core/                    # constants, theme, utils, extensions dùng chung
├── models/                  # Toàn bộ model dữ liệu (thuần Dart, có JSON)
├── repositories/            # AppRepository (interface) + DemoRepository + FirebaseRepository
├── services/                 # AuthService, FileService, ConnectivityService...
├── screens/                  # Màn hình theo module (home, groups, profiles, calendar...)
├── widgets/                   # Widget dùng lại nhiều nơi (ProfileCard, MoneyBar...)
└── navigation/                # AppSession (điều phối phiên), RootScreen, MainShell
```

Xem chi tiết kiến trúc tại [docs/architecture.md](docs/architecture.md).
