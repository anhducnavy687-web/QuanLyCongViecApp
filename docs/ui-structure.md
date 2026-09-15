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

Nút nổi **"+"** hiện ở tab Trang chủ và Nhóm, mở bottom sheet **Quick
Action** với 4 lựa chọn: "Hồ sơ mới" (`AddEditProfileScreen`), "Việc cần
làm mới", "Giao dịch mới", "Ghi chú mới" — 3 lựa chọn sau đều mở
`ProfilePickerScreen` để chọn hồ sơ trước (nếu chưa có hồ sơ nào, hiện
thông báo yêu cầu tạo hồ sơ trước), sau đó điều hướng tới màn hình tương
ứng (`AddEditTaskScreen`, hoặc `ProfileDetailScreen` mở sẵn đúng tab).

`Cộng tác viên` là module riêng, truy cập từ Cài đặt →
"Quản lý cộng tác viên" (`CollaboratorsScreen` → `CollaboratorDetailScreen`).

## Cây màn hình chi tiết

```
DashboardScreen
 ├─ Header (lời chào theo giờ + thứ/ngày hiện tại)
 ├─ StatPill (Quá hạn / Hôm nay / Sắp đến hạn / Đang chờ / Không có hạn)
 │   — mỗi StatPill chạm vào để drill-down sang SearchScreen với filter
 │   tương ứng đã chọn sẵn (initialFilter)
 ├─ "Việc hôm nay" — task có dueDate = hôm nay trên MỌI hồ sơ, sắp theo
 │   độ ưu tiên, có checkbox hoàn thành nhanh ngay tại Dashboard
 ├─ Section theo DeadlineCategory (ưu tiên: quá hạn → hôm nay → sắp đến hạn
 │   → trì trệ/không deadline → bình thường) → ProfileCard[]
 │   — chạm vào tiêu đề section cũng drill-down sang SearchScreen
 ├─ Section "Đã hoàn thành / Đã hủy" (thu gọn)
 └─ (AppBar action) → TasksScreen, SearchScreen

ProfileCard ──tap──▶ ProfileDetailScreen ("Hồ sơ 360°" — 7 tab)
 ├─ (AppBar action) → TrichNgangScreen (Cơ bản/Đầy đủ, Sao chép/Chia sẻ)
 │   — luôn nằm ở AppBar, không thuộc tab nào, mở được từ bất kỳ tab nào
 ├─ Tab "Tổng quan": workTarget, StatusBadge, phone, group, description,
 │   TimelineBar, note + ProfileTimelineSection (lịch sử sự kiện hồ sơ)
 ├─ Tab "Bước xử lý": StageStepList (thêm/sửa/xóa bước, đánh dấu hoàn
 │   thành, chuyển bước hiện tại)
 ├─ Tab "Việc cần làm": TaskListSection (thêm/sửa/xóa/hoàn thành task,
 │   mở AddEditTaskScreen — có trạng thái "Đang chờ" với lý do/ngày chờ/
 │   ngày dự kiến phản hồi giống Profile)
 ├─ Tab "Mốc thời gian": MilestoneSection (thêm/sửa/xóa mốc, tự phân loại
 │   quá hạn/hôm nay/sắp tới)
 ├─ Tab "Tiền": MoneySection (MoneyBar + breakdown + lịch sử giao dịch +
 │   thêm giao dịch)
 ├─ Tab "Cộng tác viên": CollaboratorAssignmentSection (gán CTV, trả hoa
 │   hồng)
 └─ Tab "Tài liệu": AttachmentSection (thêm/mở/đổi tên/chia sẻ/xóa file)

GroupsScreen ──tap group──▶ GroupDetailScreen (danh sách ProfileCard trong nhóm)

CalendarScreen
 ├─ Lưới tháng, mỗi ngày có chấm màu theo loại sự kiện
 │   (bắt đầu / deadline / milestone / hoàn thành)
 └─ Chọn ngày → danh sách sự kiện của ngày đó ──tap──▶ ProfileDetailScreen

StatisticsScreen: số liệu hồ sơ theo trạng thái + tổng hợp tài chính + theo nhóm

TasksScreen: toàn bộ việc cần làm trên mọi hồ sơ, chip lọc (Tất cả/Quá
 hạn/Hôm nay/Đang chờ/Đang làm/Hoàn thành), mỗi dòng hiện tên hồ sơ chủ,
 checkbox hoàn thành nhanh, chạm vào mở ProfileDetailScreen

ProfilePickerScreen: tìm & chọn nhanh một hồ sơ, trả `profileId` qua
 Navigator.pop — dùng khi Quick Action cần chọn hồ sơ trước khi tạo
 task/giao dịch/ghi chú

SearchScreen: ô tìm kiếm (tên/SĐT/đích công việc/mô tả/nhóm/trạng thái/
 tên và trạng thái việc cần làm) + chip lọc (Tất cả/Cần xử lý/Quá hạn/
 Hôm nay/Sắp đến hạn/Đang xử lý/Đang chờ/Không có deadline/Hoàn thành)
 → ProfileCard[] — cũng là đích drill-down từ Dashboard qua `initialFilter`

SettingsScreen
 ├─ Tài khoản (thông tin phiên, đăng xuất/thoát demo)
 ├─ Giao diện (Light/Dark/System)
 ├─ Dữ liệu (Quản lý cộng tác viên, công tắc giả lập Offline ở Demo Mode)
 └─ Giới thiệu
```

## Widget dùng lại nhiều nơi (`lib/widgets/`)

- `ProfileCard` — card hồ sơ chuẩn (Dashboard, Group Detail, Search)
- `StatusBadge` / `DeadlineChip` — luôn có icon + chữ, không chỉ dựa màu
- `TaskStatusBadge` / `TaskPriorityChip` — tương tự nhưng cho `TaskItem`
- `TimelineBar` — dải "bắt đầu → hôm nay → deadline" hoặc "Đã bắt đầu N ngày"
- `MoneyBar` — thanh trực quan "đã nhận / tổng", không hiển thị %
- `StageProgressSummary` — dòng "Đang thực hiện: ..." trên card (thay % )
- `SectionCard` — khung card chuẩn cho các khu vực trong Profile Detail
- `TaskListSection` / `ProfileTimelineSection` — dùng trong các tab của
  Profile 360°, cùng dựng trên `SectionCard`
- `EmptyState`, `OfflineBanner`, `StatPill` — trạng thái & tiện ích chung
  (`StatPill` hỗ trợ `onTap` để drill-down từ Dashboard)

## Nguyên tắc thiết kế đã áp dụng

- Không dùng phần trăm cho tiến độ công việc hay tiến độ tiền — luôn hiển
  thị số bước/số tiền cụ thể.
- Hồ sơ không có deadline luôn hiển thị "Đã bắt đầu N ngày" thay vì im
  lặng bỏ qua.
- Màu trạng thái luôn đi kèm icon + chữ (không dùng màu làm dấu hiệu duy
  nhất) — xem `StatusBadge`/`DeadlineChip`.
- Toàn bộ chữ trong UI bằng tiếng Việt; ngày hiển thị dạng `dd/MM/yyyy`.
