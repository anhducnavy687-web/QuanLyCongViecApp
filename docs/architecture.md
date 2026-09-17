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

> **Vị trí Provider của `AppRepository`:** được cung cấp trong
> `MaterialApp.builder` ở `lib/app.dart` — nằm NGAY TRÊN Navigator nội bộ
> của `MaterialApp` — chứ không phải bên trong nội dung màn hình "home"
> (`MainShell`). Lý do: mỗi route được `Navigator.push` (VD:
> `ProfileDetailScreen`, `AddEditProfileScreen`) được Flutter dựng thành
> một `OverlayEntry` RIÊNG, là "anh em" chứ không phải "con cháu" trong
> cây widget của route đang hiển thị trước đó. Nếu Provider chỉ bọc nội
> dung của route "home" (như thiết kế ban đầu), mọi route được push sau
> đó sẽ không thấy được Provider này và ném `ProviderNotFoundException`
> ngay khi mở. Đặt Provider bên trên Navigator đảm bảo mọi route ở mọi
> độ sâu điều hướng đều đọc được `AppRepository` — áp dụng cho cả
> Android/iOS lẫn Web.

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

`MaterialApp.builder` trong `lib/app.dart` bọc Navigator bằng
`ChangeNotifierProvider<AppRepository>.value` khi repository đã sẵn sàng.
Provider không nằm trong `MainShell`; mọi route được push đều truy cập
được cùng repository. Các màn hình dùng `context.watch<AppRepository>()`
để đọc dữ liệu và rebuild khi có thay đổi.

## An toàn khi Firebase chưa được cấu hình

`FirebaseAuthService.ensureInitialized()` bọc `Firebase.initializeApp()`
trong `try/catch`. Phase 1.4 đã có Web options. Nếu khởi tạo lỗi mạng hoặc native chưa có cấu hình mặc định, `isAvailable = false`. Khi đó:

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

## Việc cần làm (Task), Trạng thái chờ (Waiting) và Timeline

Ba bổ sung này (Phase 1) đều theo đúng nguyên tắc kiến trúc sẵn có — không
đổi cách UI truy cập dữ liệu, chỉ mở rộng `AppRepository`:

- **`TaskItem`** là subcollection con của từng hồ sơ
  (`profiles/{id}/tasks`), độc lập với `WorkStage` — một hồ sơ có nhiều
  bước xử lý (tiến trình cố định) nhưng có thể có nhiều việc cần làm phát
  sinh (task) không nằm trong bước nào cụ thể.
- **Trạng thái "Đang chờ"** tồn tại ở CẢ `Profile.status` lẫn
  `TaskItem.status`, dùng chung 3 field `waitingReason` /
  `waitingSince` / `expectedResponseDate`. `ProfileAggregate.isWaiting`
  chỉ đọc trạng thái của `Profile`; task đang chờ không tự động làm hồ sơ
  chuyển sang "Đang chờ" — đây là lựa chọn có chủ đích để một hồ sơ có
  thể vừa "Đang xử lý" vừa có một task con đang chờ phản hồi.
- **`TimelineEvent`** là log các sự kiện xảy ra trên một hồ sơ, được các
  thao tác ghi dữ liệu khác tự động tạo qua helper nội bộ `_logEvent()`
  (có mặt riêng trong cả `DemoRepository` và `FirebaseRepository`, giữ
  logic tạo message tiếng Việt nhất quán giữa hai implementation). UI chỉ
  tự tạo `TimelineEvent` trực tiếp cho một trường hợp: ghi chú tự do qua
  `addTimelineNote()`.
- `DashboardScreen` dùng `AppRepository.allOpenTasks` (duyệt thẳng qua
  toàn bộ task chưa hoàn thành/hủy trên mọi hồ sơ) cho mục "Việc hôm nay"
  thay vì duyệt qua `allAggregates` — tránh phải tính lại toàn bộ
  aggregate chỉ để lọc task theo `dueDate`.

## Offline

[`ConnectivityService`](../lib/services/connectivity_service.dart) theo
dõi trạng thái mạng qua `connectivity_plus` và hiển thị `OfflineBanner`
trên Dashboard. Ở Demo Mode, Cài đặt có công tắc giả lập offline để kiểm
tra giao diện này mà không cần tắt mạng thật. `FirebaseRepository` dùng
Firestore snapshot listener (mặc định có cache offline của Firestore SDK)
nên vẫn đọc được dữ liệu đã cache khi mất mạng; các thao tác ghi được
Firestore SDK tự xếp hàng và đồng bộ lại khi có mạng trở lại.

## Kiến trúc responsive (Phase 1.2 — Web là nền tảng triển khai chính)

Từ Phase 1.2, Web (build `flutter build web --release`, deploy qua
GitHub Pages từ Phase 1.3) là nền tảng triển khai CHÍNH của ứng dụng — không còn là bản xem
trước. Toàn bộ màn hình dùng chung 100% `lib/` (models, repositories,
services, screens, widgets) với Android/iOS; không có screen/widget riêng
cho web. Điểm khác biệt duy nhất theo nền tảng là cách các screen tự sắp
xếp bố cục theo kích thước viewport hiện tại.

### Breakpoint tập trung (`lib/core/responsive/responsive.dart`)

Toàn bộ app dùng chung một enum `ScreenSize { compact, medium, expanded }`
và class `ResponsiveBreakpoints` (compact `< 600px`, medium `600–1024px`,
expanded `> 1024px`) — không có màn hình nào tự định nghĩa magic number
breakpoint riêng. `BuildContext` có extension `context.screenSize` /
`context.isCompact` / `context.isAtLeastMedium` để đọc nhanh, và hàm
`responsiveValue<T>(context, compact:, medium:, expanded:)` để chọn giá trị
(VD số cột GridView) theo kích thước hiện tại.

- **`ResponsivePage`** — khung dùng chung để giới hạn chiều rộng nội dung
  tối đa trên desktop và căn giữa (mặc định `maxContentWidth: 1100` cho
  danh sách/dashboard, `720` cho form/chi tiết một cột, `420` cho
  `LoginScreen`). **Không** tự thêm padding ngang — mỗi screen tiếp tục tự
  quản lý padding của mình (đã có sẵn từ trước, VD
  `ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, 40))`); `ResponsivePage`
  chỉ bọc quanh phần BODY, không bọc AppBar/BottomNav. Bọc trực tiếp
  `horizontalPadding` khác 0 chỉ dùng cho trường hợp `child` chưa tự có
  padding riêng (VD `LoginScreen`).
- **`showResponsiveFormSheet<T>()`** — thay cho gọi thẳng
  `showModalBottomSheet`: compact → bottom sheet trượt lên (thao tác một
  tay); medium/expanded → `Dialog` căn giữa với `maxWidth` cố định (tránh
  form kéo giãn hết một màn hình desktop rộng).

### Điều hướng thích ứng (`MainShell`)

`MainShell` (`lib/navigation/main_shell.dart`) giữ nguyên MỘT bộ state
(`_index`, `_screens`) và chỉ đổi WIDGET điều hướng theo `context.screenSize`:

- **Compact**: `NavigationBar` dưới cùng + `FloatingActionButton` (giống
  điện thoại truyền thống).
- **Medium**: `NavigationRail` thu gọn (icon + label, không mở rộng).
- **Expanded**: `NavigationRail` mở rộng (`extended: true`, giống sidebar
  desktop), FAB đặt ở `leading` của rail (mẫu Material chính thức).

Không có business logic nào bị nhân đôi giữa các nhánh — chỉ khác widget
tree hiển thị, cùng đọc/ghi một `_index`.

### `MobilePreviewFrame` — chỉ còn dùng cho dev/debug

`lib/core/preview/mobile_preview_frame.dart` (khung mô phỏng điện thoại
trên Chrome, có từ trước Phase 1.2) được GIỮ LẠI nhưng thu hẹp phạm vi:
chỉ bật khi `kIsWeb && !kReleaseMode` (xem `lib/app.dart`). `kReleaseMode`
là cờ Dart biên dịch (compile-time) — `flutter run -d chrome` (dev) có
`kReleaseMode == false` nên khung vẫn hiện để tiện xem nhanh giao diện
điện thoại; `flutter build web --release` (GitHub Pages, production) có
`kReleaseMode == true` nên khung KHÔNG BAO GIỜ xuất hiện — người dùng cuối
luôn thấy app chiếm toàn bộ viewport trình duyệt. Cố tình dùng cờ biên
dịch thay vì kiểm tra theo domain/URL để không có logic "đoán môi trường"
nào có thể sai lệch.

**Plugin không hỗ trợ Web** (`open_filex`, `path_provider`, và việc dùng
`dart:io File` trực tiếp trong `FileService`): thay vì loại bỏ khỏi
Android/iOS hoặc để app crash trên web, `FileService` kiểm tra `kIsWeb`
và trả về `FileServiceException` với thông báo tiếng Việt thân thiện
trước khi chạm tới các API không tồn tại trên web. Hành vi trên
Android/iOS không đổi. Riêng chia sẻ văn bản (`Share.share`, dùng cho
Trích ngang) không phụ thuộc `dart:io` nên vẫn hoạt động bình thường trên
web.

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

## Tìm kiếm không dấu (Phase 1.1)

`core/utils/vietnamese_utils.dart` cung cấp `VietnameseUtils.removeDiacritics()`
— bảng tra cứu ký tự có dấu → không dấu (đơn giản, không phụ thuộc thư
viện ngoài). `SearchScreen._matchesQuery` bỏ dấu CẢ hai phía (dữ liệu và
từ khóa tìm kiếm) trước khi so sánh `contains`, nên gõ "nguyen van a" vẫn
khớp "Nguyễn Văn A" mà không cần thay đổi cách lưu trữ dữ liệu (vẫn giữ
nguyên dấu để hiển thị).

## Kiểm tra responsive bằng widget test (Phase 1.1, mở rộng ở Phase 1.2)

Không có trình duyệt/thiết bị để chụp ảnh màn hình trực quan trong môi
trường CI/sandbox, nên `test/responsive_test.dart` dùng
`tester.view.physicalSize` + `devicePixelRatio = 1.0` để giả lập kích
thước màn hình, sau đó duyệt qua các màn hình chính (Dashboard, Nhóm,
Lịch, Thống kê, Cài đặt, Hồ sơ 360° đủ 7 tab, AddEditTaskScreen) và khẳng
định không có `FlutterError` (bao gồm `RenderFlex overflow`) phát sinh
trong quá trình dựng UI. Cách này phát hiện được overflow thật (không phải
giả lập).

Từ Phase 1.2, bộ kích thước được mở rộng để phủ cả tablet/desktop (Web là
nền tảng chính):

- **Điện thoại**: 320×568, 360×800, 375×812, 390×844, 412×915, 430×932
- **Tablet**: 768×1024, 820×1180
- **Desktop**: 1280×720, 1366×768, 1440×900, 1920×1080

Cộng thêm một test **đổi cỡ màn hình liên tục** (1440→800→430→390→1440
trên CÙNG một cây widget, không dựng lại từ đầu ở mỗi kích thước) để xác
nhận: không crash, route đang mở (`ProfileDetailScreen`) không bị mất hay
nhân đôi khi `MainShell` chuyển đổi qua lại giữa `NavigationBar` và
`NavigationRail`, và vẫn pop về được Dashboard bình thường sau khi đổi cỡ
nhiều lần.

Bộ test mở rộng ở Phase 1.2 đã lộ ra 2 lỗi thật, cả hai đều đã sửa:

- `ResponsivePage` mặc định có `horizontalPadding: 16`, cộng dồn với
  padding ngang mà chính mỗi `ListView`/`Column` đã tự khai báo sẵn
  (double-padding) — đủ để `StatisticsScreen`'s `_StatCard` (grid 2 cột,
  `childAspectRatio` cố định) tràn theo chiều dọc ở màn hình hẹp. Sửa bằng
  cách đổi mặc định `horizontalPadding` của `ResponsivePage` về `0` (mỗi
  screen tiếp tục tự chịu trách nhiệm padding của mình, đúng thiết kế ban
  đầu).
- `_MonthHeader` trong `CalendarScreen` dùng `Row(mainAxisAlignment:
  spaceBetween)` với hai `IconButton` cố định và một `Text` không giới
  hạn chiều rộng — tràn ở 360×800 khi không gian bị thu hẹp. Sửa theo đúng
  pattern đã dùng ở Phase 1.1 cho lỗi tương tự: bọc `Text` trong `Expanded`
  kèm `overflow: TextOverflow.ellipsis`.

Phase 1.1 trước đó cũng đã phát hiện các `Row` tính tổng tiền dùng
`MainAxisAlignment.spaceBetween` không có `Expanded` (dễ tràn khi nhãn dài
gặp màn hình hẹp) tại `statistics_screen.dart`, `money_section.dart`,
`collaborator_detail_screen.dart`, và một `Row` badge/ưu tiên/hạn trong
`task_list_section.dart` (đã đổi sang `Wrap` để tự xuống dòng thay vì
tràn).

## Deployment (Phase 1.3)

`Push claude/stoic-goldberg-qcky72 → GitHub Actions → Flutter Web release → GitHub Pages`.
Workflow `.github/workflows/deploy-pages.yml` dùng Flutter 3.47.4, build với
`--base-href "/QuanLyCongViecApp/" --no-web-resources-cdn`, upload `build/web`
và deploy vào environment `github-pages`. Không commit build output.

Production URL dự kiến: https://anhducnavy687-web.github.io/QuanLyCongViecApp/.
Routing vẫn dùng `Navigator`/`MaterialPageRoute`, không bật path URL strategy,
không có đường dẫn con để yêu cầu SPA rewrite. Refresh tải lại app ở URL gốc;
không có cam kết khôi phục route chi tiết hoặc dữ liệu Demo trong bộ nhớ.
Firebase, UID isolation, rules và responsive architecture không thay đổi.
Firebase Web còn thiếu cấu hình project; xem [hướng dẫn triển khai](deploy-github-pages.md).

## Phase 1.4: phiên Firebase Web thật

Web đã có `firebase_options.dart` và dùng Firebase Auth popup Google. Native
vẫn dùng cấu hình mặc định nếu có; thiếu cấu hình native không chặn Demo.
AppSession sở hữu/dispose repositories. Khi đổi phiên, MaterialApp thay key để
loại bỏ Navigator/routes cũ; kết quả tải của generation cũ không được gắn lại.
Repository chờ snapshots server ban đầu và xử lý onError; lỗi sau đăng nhập
hiển thị màn hình retry/đăng xuất thay vì tiếp tục hiện dữ liệu cũ.

Thanh toán dùng Firestore transaction để ghi lịch sử tiền, timeline và tăng
paidAmount nguyên tử. Sửa phân công bỏ paidAmount khỏi payload cập nhật.
Storage vẫn deferred; xem firebase-setup.md để biết phạm vi production.
