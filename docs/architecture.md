# Kiến trúc ứng dụng

## Nguyên tắc cốt lõi: UI không phụ thuộc backend cụ thể

Toàn bộ màn hình chỉ giao tiếp với dữ liệu thông qua interface
[`AppRepository`](../lib/repositories/app_repository.dart) (`ChangeNotifier`).
Có hai cài đặt:

- **`DemoRepository`** — lưu dữ liệu trong bộ nhớ (`List` trong Dart), nạp
  sẵn bộ dữ liệu mẫu phong phú từ `demo_seed_data.dart`. Không cần mạng,
  không cần đăng nhập.
- **`FirebaseRepository`** — đọc/ghi Cloud Firestore thật, dùng snapshot
  listener để cập nhật cache trong bộ nhớ rồi gọi `notifyListeners()`,
  hành xử giống hệt `DemoRepository` dưới góc nhìn của UI.

Nhờ vậy, **chuyển từ Demo Mode sang Firebase Mode không cần sửa bất kỳ màn
hình nào** — chỉ cần [`AppSession`](../lib/navigation/app_session.dart)
(nơi duy nhất quyết định dùng repository nào) trả về implementation khác.

```
UI (screens/, widgets/)
   │  chỉ biết tới AppRepository
   ▼
AppRepository (interface, ChangeNotifier)
   │
   ├── DemoRepository      (bộ nhớ trong, Demo Mode)
   └── FirebaseRepository  (Cloud Firestore, đăng nhập Google)
```

## Vòng đời phiên làm việc (Splash → Login/Demo → Home)

[`AppSession`](../lib/navigation/app_session.dart) là bộ điều phối trung
tâm:

1. `bootstrap()` được gọi khi app khởi động: cố gắng khởi tạo Firebase
   (`FirebaseAuthService.ensureInitialized`), thử khôi phục phiên đăng
   nhập cũ; nếu không có, kiểm tra xem lần trước người dùng có đang ở Demo
   Mode hay không (lưu trong `SharedPreferences`).
2. Trong lúc `bootstrap()` chạy bất đồng bộ, `RootScreen` hiển thị
   `SplashScreen`.
3. Nếu chưa có phiên nào, chuyển sang `LoginScreen` — người dùng chọn
   **Đăng nhập bằng Google** hoặc **Dùng thử ở Chế độ Demo**.
4. Sau khi có `AppRepository` sẵn sàng (`SessionStatus.demo` hoặc
   `SessionStatus.authenticated`), `RootScreen` hiển thị `MainShell` (5 tab
   điều hướng chính).

`MainShell` bọc toàn bộ cây widget con trong
`ChangeNotifierProvider<AppRepository>.value(value: session.repository!)`
— mọi màn hình con dùng `context.watch<AppRepository>()` để đọc dữ liệu và
tự động rebuild khi có thay đổi (thêm/sửa/xóa hồ sơ, giao dịch...).

## An toàn khi Firebase chưa được cấu hình

`FirebaseAuthService.ensureInitialized()` bọc `Firebase.initializeApp()`
trong `try/catch`. Nếu dự án chưa chạy `flutterfire configure` (thiếu
`firebase_options.dart`, thiếu `google-services.json`...), lệnh này sẽ ném
lỗi, bị bắt lại, và `isAvailable = false`. Khi đó:

- App vẫn khởi động bình thường, không crash.
- Nút "Đăng nhập bằng Google" gọi `signInWithGoogle()` sẽ ném
  `AuthException` với thông điệp tiếng Việt thân thiện, được `LoginScreen`
  hiển thị qua `SnackBar`.
- Người dùng luôn có thể vào **Chế độ Demo** để dùng ứng dụng ngay.

## Tính toán số liệu tài chính — luôn từ transaction

`ProfileAggregate.finance` (xem `lib/models/profile_aggregate.dart`) tính
"Đã nhận", "Chi phí", "Hoa hồng đã trả" bằng cách duyệt qua toàn bộ
`MoneyTransaction` của hồ sơ — KHÔNG dùng một con số tổng lưu sẵn nào khác.
Điều này đảm bảo số liệu luôn nhất quán với lịch sử giao dịch thực tế
(spec §11).

`CollaboratorAssignment.paidAmount` là một giá trị **cache** được
repository cập nhật lại mỗi khi có giao dịch `COLLABORATOR_PAYMENT` mới
(xem `payCommission()` trong cả `DemoRepository` và `FirebaseRepository`).
Nguồn sự thật vẫn là lịch sử transaction; cache chỉ giúp hiển thị nhanh mà
không phải quét lại toàn bộ transaction ở mọi nơi trong UI. Đây là điều
chỉnh kiến trúc có chủ đích so với việc chỉ lưu một con số — vẫn tuân thủ
yêu cầu "phải hỗ trợ lịch sử trả hoa hồng bằng transaction" (spec §16).

## Ưu tiên trên Dashboard

`ProfileAggregate.deadlineCategory` phân loại mỗi hồ sơ theo đúng thứ tự
ưu tiên trong spec: `overdue > dueToday > upcoming > stalled > normal >
completed`. `DashboardScreen` nhóm hồ sơ theo category này và hiển thị
theo thứ tự đó — hồ sơ **không có deadline** cũng rơi vào nhóm `stalled`
("Trì trệ / Không có deadline") để không bị bỏ quên.

## Offline

[`ConnectivityService`](../lib/services/connectivity_service.dart) theo
dõi trạng thái mạng qua `connectivity_plus` và hiển thị `OfflineBanner`
trên Dashboard. Ở Demo Mode, Cài đặt có công tắc giả lập offline để kiểm
tra giao diện này mà không cần tắt mạng thật. `FirebaseRepository` dùng
Firestore snapshot listener (mặc định có cache offline của Firestore SDK)
nên vẫn đọc được dữ liệu đã cache khi mất mạng; các thao tác ghi được
Firestore SDK tự xếp hàng và đồng bộ lại khi có mạng trở lại.

## Kiến trúc File/Tài liệu

- Metadata của file (`Attachment`) luôn nằm trong Firestore/bộ nhớ Demo.
- File thực tế: Demo Mode lưu trong thư mục tài liệu của app
  (`path_provider`); Firebase Mode tải lên Firebase Storage theo path
  `users/{uid}/profiles/{profileId}/attachments/{attachmentId}-{fileName}`
  qua [`StorageUploadService`](../lib/services/storage_upload_service.dart).
- [`FileService`](../lib/services/file_service.dart) trừu tượng hóa toàn
  bộ pick/open/share file để UI không phụ thuộc trực tiếp vào
  `file_picker`/`image_picker`/`open_filex`/`share_plus`.

## State management

Dự án dùng `provider` (bọc `ChangeNotifier`) thay vì các giải pháp phức
tạp hơn (Bloc/Riverpod) vì:

- `AppRepository`, `AppSession`, `ThemeController`, `ConnectivityService`
  đều là luồng dữ liệu "một nguồn sự thật, nhiều nơi lắng nghe" — rất hợp
  với `ChangeNotifier`.
- Dễ thay thế sau này nếu cần, vì toàn bộ business logic nằm trong
  `models/` và `repositories/`, không nằm trong widget.
