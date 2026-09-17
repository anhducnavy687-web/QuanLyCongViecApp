# Cấu trúc Firestore & Storage

## Firestore

```
users/{uid}
users/{uid}/groups/{groupId}
users/{uid}/collaborators/{collaboratorId}
users/{uid}/profiles/{profileId}
users/{uid}/profiles/{profileId}/stages/{stageId}
users/{uid}/profiles/{profileId}/milestones/{milestoneId}
users/{uid}/profiles/{profileId}/transactions/{transactionId}
users/{uid}/profiles/{profileId}/attachments/{attachmentId}
users/{uid}/profiles/{profileId}/collaboratorAssignments/{assignmentId}
users/{uid}/profiles/{profileId}/tasks/{taskId}
users/{uid}/profiles/{profileId}/timelineEvents/{eventId}
```

Đúng theo đề xuất trong spec, không điều chỉnh. Lý do giữ nguyên:

- `groups` và `collaborators` là top-level subcollection của `users/{uid}`
  vì chúng độc lập với từng hồ sơ cụ thể (một cộng tác viên có thể tham
  gia nhiều hồ sơ).
- `stages`, `milestones`, `transactions`, `attachments`,
  `collaboratorAssignments`, `tasks`, `timelineEvents` nằm dưới từng
  `profiles/{profileId}` vì chúng luôn thuộc về đúng một hồ sơ, giúp việc
  xóa hồ sơ (xóa toàn bộ subcollection con) và rule bảo mật đơn giản,
  đồng nhất.

Mỗi document được serialize bằng đúng `toJson()` của model tương ứng
(xem `lib/models/`) — field name trong Firestore trùng với field name
trong Dart để tránh một tầng mapping thừa.

## Đồng bộ dữ liệu (FirebaseRepository)

`lib/repositories/firebase_repository.dart`:

1. Khi `init()` được gọi, mở snapshot listener cho `groups`, `collaborators`
   và `profiles` ở cấp `users/{uid}`.
2. Với mỗi `profileId` xuất hiện trong danh sách `profiles`, tự động mở
   thêm 7 snapshot listener cho các subcollection con của hồ sơ đó
   (`stages`, `milestones`, `transactions`, `attachments`,
   `collaboratorAssignments`, `tasks`, `timelineEvents`).
3. Khi một hồ sơ bị xóa khỏi danh sách, các listener con tương ứng được
   hủy (`cancel()`) để tránh rò rỉ bộ nhớ.
4. Mỗi lần snapshot cập nhật, cache trong bộ nhớ được ghi đè và
   `notifyListeners()` được gọi — UI tự động vẽ lại.

Việc ghi dữ liệu (`addProfile`, `updateStage`, `payCommission`...) gọi
thẳng `set()`/`update()`/`delete()` trên Firestore; kết quả sẽ quay lại
qua snapshot listener ở bước trên (không cập nhật cache cục bộ hai lần).

## Firebase Storage (deferred, chưa bật trong Phase 1.4)

```
users/{uid}/profiles/{profileId}/attachments/{attachmentId}-{fileName}
```

Đây là đường dẫn dự kiến của code Storage có sẵn, không phải tính năng
production đã hoạt động. Phase 1.4 không bật Storage/Blaze, không deploy Storage
rules. Firebase Mode thông báo chưa hỗ trợ upload. Demo giữ hành vi hiện có.
## Quy tắc bảo mật

Xem file đầy đủ tại [`firestore.rules`](../firestore.rules) và
[`storage.rules`](../storage.rules) ở thư mục gốc repo. Nguyên tắc:

```
allow read, write: if request.auth != null && request.auth.uid == uid;
```

áp dụng cho mọi document dưới `users/{uid}/**` và mọi object dưới
`users/{uid}/**` trên Storage — người dùng A không bao giờ đọc/ghi được dữ
liệu của người dùng B. Mọi đường dẫn khác bị từ chối mặc định
(`allow read, write: if false`). **Không có bất kỳ rule `if true` nào.**

## Index

Với quy mô dữ liệu cá nhân (hàng chục–hàng trăm hồ sơ), các truy vấn hiện
tại (`collection(...).snapshots()` không có `where`/`orderBy` phức tạp)
không cần composite index tùy chỉnh. Nếu sau này thêm truy vấn lọc/sắp xếp
phức tạp trên subcollection lớn, cân nhắc bật Firestore composite index
qua Firebase Console khi gặp lỗi gợi ý index trong log.

## Độ tin cậy Phase 1.4

Repository chờ phản hồi server ban đầu, có onError và hủy listeners khi đổi UID.
Thanh toán CTV dùng Firestore transaction: ghi giao dịch, timeline, tăng tổng
paidAmount cùng một lần commit. Xóa đọc giao dịch server để tránh trừ lặp; sửa
thông tin phân công không ghi đè paidAmount từ bản cache cũ.
