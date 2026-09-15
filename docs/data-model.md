# Mô hình dữ liệu (Data Model)

Toàn bộ model nằm tại `lib/models/`. Mỗi model là một class Dart thuần,
bất biến (immutable, `copyWith`), có `toJson()`/`fromJson()` để phục vụ cả
Demo Mode (không dùng, chỉ giữ trong bộ nhớ) lẫn Firestore.

## WorkGroup — Nhóm công việc

| Field | Kiểu | Ghi chú |
|---|---|---|
| id | String | |
| name | String | VD: "Đất đai" |
| description | String | |
| createdAt / updatedAt | DateTime | |

## Profile — Hồ sơ

| Field | Kiểu | Ghi chú |
|---|---|---|
| id | String | |
| groupId | String | FK tới WorkGroup |
| fullName | String | Bắt buộc |
| phone | String | |
| workTarget | String | Đích công việc — bắt buộc |
| description | String | |
| startDate | DateTime | |
| deadline | DateTime? | null nếu không có hạn |
| hasDeadline | bool | |
| status | ProfileStatus | `new / inProgress / waiting / completed / cancelled` |
| totalAmount | num | Tổng tiền thỏa thuận |
| note | String | |
| createdAt / updatedAt | DateTime | `updatedAt` cũng dùng để phát hiện "trì trệ" |
| completedAt | DateTime? | |

## WorkStage — Bước xử lý

| Field | Kiểu | Ghi chú |
|---|---|---|
| id, profileId | String | |
| name | String | |
| order | int | Thứ tự hiển thị |
| status | StageStatus | `pending / inProgress / completed / skipped` |
| startDate, completedAt, deadline | DateTime? | |
| note | String | |

5 bước mặc định khi tạo hồ sơ mới (`AppConstants.defaultStageNames`):
Nhận hồ sơ → Chuẩn bị → Làm việc với bên liên quan → Hoàn thiện → Bàn giao.
Người dùng có thể thêm/sửa/xóa bước tùy ý.

## Milestone — Mốc thời gian

| Field | Kiểu | Ghi chú |
|---|---|---|
| id, profileId | String | |
| title | String | |
| dueDate | DateTime | |
| status | MilestoneStatus | `pending / completed` |
| completedAt | DateTime? | |
| note | String | |

`Milestone.timing()` tự phân loại quá hạn/hôm nay/sắp tới/hoàn thành/bình
thường dựa trên `dueDate` và ngưỡng cảnh báo (mặc định 3 ngày).

## MoneyTransaction — Giao dịch tiền

| Field | Kiểu | Ghi chú |
|---|---|---|
| id, profileId | String | |
| type | TransactionType | `RECEIVED / EXPENSE / COLLABORATOR_PAYMENT` |
| amount | num | |
| date | DateTime | Ngày giao dịch (người dùng chọn) |
| note | String | |
| createdAt | DateTime | Thời điểm tạo bản ghi |
| collaboratorAssignmentId | String? | Chỉ có khi type = COLLABORATOR_PAYMENT |

**Đây là nguồn sự thật duy nhất cho mọi số liệu tài chính.** Xem
`ProfileAggregate.finance` — không có nơi nào khác lưu "đã nhận"/"chi phí"
dưới dạng số độc lập.

## Collaborator — Cộng tác viên

| Field | Kiểu | Ghi chú |
|---|---|---|
| id | String | |
| name, phone, note | String | |
| active | bool | Ngừng hợp tác vẫn giữ lịch sử |
| createdAt / updatedAt | DateTime | |

## CollaboratorAssignment — Gán CTV vào hồ sơ

| Field | Kiểu | Ghi chú |
|---|---|---|
| id, profileId, collaboratorId | String | |
| role | String | VD: "Đo đạc, xác minh ranh giới" |
| commissionAmount | num | Hoa hồng thỏa thuận |
| paidAmount | num | **Cache**, xem ghi chú bên dưới |
| note | String | |
| createdAt / updatedAt | DateTime | |

> **Ghi chú kiến trúc:** `paidAmount` là giá trị cache được
> `AppRepository.payCommission()` cập nhật lại mỗi khi có một
> `MoneyTransaction` loại `COLLABORATOR_PAYMENT` mới gắn với assignment
> này. Nguồn sự thật thực sự vẫn là lịch sử transaction (đáp ứng đúng yêu
> cầu "không chỉ lưu paidAmount tổng, phải hỗ trợ lịch sử trả hoa hồng
> bằng transaction"), cache chỉ để UI đọc nhanh mà không cần cộng dồn lại
> toàn bộ transaction mỗi lần render danh sách cộng tác viên.

## Attachment — File đính kèm

| Field | Kiểu | Ghi chú |
|---|---|---|
| id, profileId | String | |
| fileName | String | |
| type | AttachmentType | pdf/doc/docx/jpg/jpeg/png/webp/other |
| localPathOrUrl | String | Đường dẫn cục bộ (Demo) hoặc download URL (Storage) |
| storagePath | String? | Chỉ có ở Firebase Mode |
| sizeBytes | int | |
| createdAt / updatedAt | DateTime | |

## ProfileAggregate — View model tổng hợp

`lib/models/profile_aggregate.dart` không phải là dữ liệu lưu trữ, mà là
một "view model" gói `Profile` cùng toàn bộ dữ liệu liên quan (stages,
milestones, transactions, assignments, attachments) và cung cấp các getter
tính toán:

- `finance` → `ProfileFinance` (totalAmount, received, expense,
  commissionTotal, commissionPaid, remainingToReceive, commissionRemaining)
- `currentStage`, `nextStage`, `completedStages`, `upcomingStages`
- `deadlineCategory` → `DeadlineCategory` (overdue/dueToday/upcoming/
  stalled/normal/completed) — dùng để sắp xếp ưu tiên trên Dashboard
- `overdueMilestoneCount`

Toàn bộ UI (Dashboard, Group Detail, Search, Profile Detail...) đều dùng
chung `ProfileAggregate` để đảm bảo logic nhất quán ở một chỗ duy nhất.
