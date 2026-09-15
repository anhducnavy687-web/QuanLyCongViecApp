# Cấu trúc màn hình & điều hướng

## Luồng khởi động

```
SplashScreen
   │  AppSession.bootstrap()
   ▼
Đã có phiên Firebase hợp lệ? ──có──▶ MainShell (Firebase Mode)
   │ không
   ▼
Lần trước đang ở Demo Mode? ──có──▶ MainShell (Demo Mode)
   │ không
   ▼
LoginScreen
   ├── "Đăng nhập bằng Google" ──▶ MainShell (Firebase Mode)
   └── "Dùng thử ở Chế độ Demo" ──▶ MainShell (Demo Mode)
```

`RootScreen` (`lib/navigation/root_screen.dart`) là nơi duy nhất quyết
định hiển thị Splash/Login/MainShell dựa trên `AppSession.status`.

## MainShell — 5 tab chính

| Tab | Icon | Màn hình |
|---|---|---|
| Trang chủ | dashboard | `DashboardScreen` |
| Nhóm | folder | `GroupsScreen` → `GroupDetailScreen` |
| Lịch | calendar_month | `CalendarScreen` |
| Thống kê | bar_chart | `StatisticsScreen` |
| Cài đặt | settings | `SettingsScreen` |

Nút nổi **"+ Thêm hồ sơ"** hiện ở tab Trang chủ và Nhóm, mở
`AddEditProfileScreen`.

`Cộng tác viên` là module riêng, truy cập từ Cài đặt →
"Quản lý cộng tác viên" (`CollaboratorsScreen` → `CollaboratorDetailScreen`).

## Cây màn hình chi tiết

```
DashboardScreen
 ├─ StatPill (Quá hạn / Hôm nay / Sắp đến hạn / Trì trệ / Còn phải nhận)
 ├─ Section theo DeadlineCategory (ưu tiên: quá hạn → hôm nay → sắp đến hạn
 │   → trì trệ/không deadline → bình thường) → ProfileCard[]
 ├─ Section "Đã hoàn thành / Đã hủy" (thu gọn)
 └─ (AppBar action) → SearchScreen

ProfileCard ──tap──▶ ProfileDetailScreen
 ├─ Header: workTarget, StatusBadge, phone, group, description, TimelineBar, note
 ├─ StageStepList        (thêm/sửa/xóa bước, đánh dấu hoàn thành, chuyển bước hiện tại)
 ├─ MilestoneSection      (thêm/sửa/xóa mốc, tự phân loại quá hạn/hôm nay/sắp tới)
 ├─ MoneySection          (MoneyBar + breakdown + lịch sử giao dịch + thêm giao dịch)
 ├─ CollaboratorAssignmentSection (gán CTV, trả hoa hồng)
 ├─ AttachmentSection     (thêm/mở/đổi tên/chia sẻ/xóa file)
 └─ (AppBar action) → TrichNgangScreen (Cơ bản/Đầy đủ, Sao chép/Chia sẻ)

GroupsScreen ──tap group──▶ GroupDetailScreen (danh sách ProfileCard trong nhóm)

CalendarScreen
 ├─ Lưới tháng, mỗi ngày có chấm màu theo loại sự kiện
 │   (bắt đầu / deadline / milestone / hoàn thành)
 └─ Chọn ngày → danh sách sự kiện của ngày đó ──tap──▶ ProfileDetailScreen

StatisticsScreen: số liệu hồ sơ theo trạng thái + tổng hợp tài chính + theo nhóm

SearchScreen: ô tìm kiếm (tên/SĐT/đích công việc/mô tả/nhóm) + chip lọc
 (Tất cả/Cần xử lý/Quá hạn/Hôm nay/Sắp đến hạn/Đang xử lý/Đang chờ/
  Không có deadline/Hoàn thành) → ProfileCard[]

SettingsScreen
 ├─ Tài khoản (thông tin phiên, đăng xuất/thoát demo)
 ├─ Giao diện (Light/Dark/System)
 ├─ Dữ liệu (Quản lý cộng tác viên, công tắc giả lập Offline ở Demo Mode)
 └─ Giới thiệu
```

## Widget dùng lại nhiều nơi (`lib/widgets/`)

- `ProfileCard` — card hồ sơ chuẩn (Dashboard, Group Detail, Search)
- `StatusBadge` / `DeadlineChip` — luôn có icon + chữ, không chỉ dựa màu
- `TimelineBar` — dải "bắt đầu → hôm nay → deadline" hoặc "Đã bắt đầu N ngày"
- `MoneyBar` — thanh trực quan "đã nhận / tổng", không hiển thị %
- `StageProgressSummary` — dòng "Đang thực hiện: ..." trên card (thay % )
- `SectionCard` — khung card chuẩn cho các khu vực trong Profile Detail
- `EmptyState`, `OfflineBanner`, `StatPill` — trạng thái & tiện ích chung

## Nguyên tắc thiết kế đã áp dụng

- Không dùng phần trăm cho tiến độ công việc hay tiến độ tiền — luôn hiển
  thị số bước/số tiền cụ thể.
- Hồ sơ không có deadline luôn hiển thị "Đã bắt đầu N ngày" thay vì im
  lặng bỏ qua.
- Màu trạng thái luôn đi kèm icon + chữ (không dùng màu làm dấu hiệu duy
  nhất) — xem `StatusBadge`/`DeadlineChip`.
- Toàn bộ chữ trong UI bằng tiếng Việt; ngày hiển thị dạng `dd/MM/yyyy`.
