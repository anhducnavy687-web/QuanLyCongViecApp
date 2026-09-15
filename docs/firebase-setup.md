# Hướng dẫn cấu hình Firebase

Ứng dụng chạy tốt ở **Demo Mode** mà không cần bước nào dưới đây. Chỉ làm
theo hướng dẫn này khi muốn bật đăng nhập Google thật và đồng bộ dữ liệu
nhiều thiết bị qua Firebase.

## 1. Tạo Firebase project

1. Vào https://console.firebase.google.com
2. **Add project** → đặt tên (VD: `quanlycongviecapp`) → hoàn tất wizard.

## 2. Cài FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Đảm bảo `$HOME/.pub-cache/bin` nằm trong `PATH`.

## 3. Đăng nhập Firebase CLI

Cần cài Firebase CLI trước (nếu chưa có):

```bash
npm install -g firebase-tools
firebase login
```

## 4. Chạy FlutterFire configure

Tại thư mục gốc dự án:

```bash
flutterfire configure
```

- Chọn Firebase project vừa tạo.
- Chọn nền tảng cần cấu hình (Android, iOS).
- Lệnh này tự sinh:
  - `lib/firebase_options.dart`
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`

`lib/firebase_options.dart` **không được commit kèm secret thật lên repo
công khai** nếu dự án là mã nguồn mở — cân nhắc thêm vào `.gitignore` nếu
cần, tuỳ chính sách bảo mật của bạn (các key trong file này là định danh
client, không phải secret server, nhưng vẫn nên hạn chế commit tùy ngữ
cảnh dự án).

> Dự án này gọi `Firebase.initializeApp()` **không** truyền `options`
> tường minh trong `FirebaseAuthService.ensureInitialized()`. Sau khi chạy
> `flutterfire configure`, hãy sửa lời gọi đó thành
> `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
> (import `firebase_options.dart`) để đảm bảo đúng project trên mọi nền
> tảng.

## 5. Bật Google Sign-In

Trong Firebase Console → **Authentication** → **Sign-in method** → bật
**Google** → lưu.

### Android

- Thêm SHA-1 (và SHA-256 nếu dùng App Check/Play Integrity) của keystore
  debug/release vào **Project settings → Your apps → Android app**:
  ```bash
  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
  ```
- Tải lại `google-services.json` mới nhất sau khi thêm SHA nếu cần.

### iOS

- Đảm bảo `GoogleService-Info.plist` đã được thêm vào target Runner qua
  Xcode (kéo thả file vào project, tick "Copy items if needed").
- Thêm URL scheme (`REVERSED_CLIENT_ID` trong file plist) vào
  `ios/Runner/Info.plist` dưới `CFBundleURLTypes` (FlutterFire CLI thường
  tự làm bước này).

## 6. Tạo Cloud Firestore

Firebase Console → **Firestore Database** → **Create database** → chọn
**Production mode** (rules mặc định từ chối tất cả — an toàn hơn) → chọn
region gần người dùng.

## 7. Tạo Firebase Storage

Firebase Console → **Storage** → **Get started** → chọn cùng region với
Firestore nếu có thể.

## 8 & 9. Cấu hình Android / iOS (đã làm ở bước 4)

`flutterfire configure` đã cấu hình cả 2 nền tảng. Kiểm tra thêm:

- Android: `android/app/build.gradle.kts` (hoặc `.gradle`) đã áp dụng
  plugin `com.google.gms.google-services` (FlutterFire CLI tự thêm).
- iOS: build thử một lần trên Xcode để chắc chắn plist được nhúng đúng
  target.

## 10. Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

Sử dụng file [`firestore.rules`](../firestore.rules) có sẵn ở gốc repo —
đã tuân thủ nguyên tắc mỗi người dùng chỉ truy cập được dữ liệu của chính
mình, không có `allow read, write: if true`.

## 11. Deploy Storage Rules

```bash
firebase deploy --only storage:rules
```

Sử dụng file [`storage.rules`](../storage.rules) có sẵn ở gốc repo.

> Nếu đây là lần đầu dùng `firebase deploy` trong thư mục này, chạy
> `firebase init` trước để tạo `firebase.json` liên kết `firestore.rules`
> và `storage.rules` với project, hoặc dùng cờ
> `--project <project-id>` khi deploy nếu chưa có `.firebaserc`.

## Kiểm tra sau khi cấu hình

1. Chạy `flutter run`.
2. Ở Login, nhấn **Đăng nhập bằng Google** — nếu mọi thứ đúng, popup chọn
   tài khoản Google hiện ra và sau khi đăng nhập, app chuyển sang Home với
   dữ liệu rỗng (project Firestore mới chưa có dữ liệu).
3. Thử tạo một Nhóm công việc và một Hồ sơ — kiểm tra trong Firebase
   Console → Firestore Database xem document đã xuất hiện đúng đường dẫn
   `users/{uid}/groups/...` và `users/{uid}/profiles/...` chưa.
