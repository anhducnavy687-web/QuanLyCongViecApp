# Firebase production — Phase 1.4

## Project và hosting

- Firebase project: `quanlycongviecapp-129de`.
- Firebase Web App: `1:957843233910:web:e23b136aff578073d09357`.
- Firestore Standard, database `(default)`.
- Production: https://anhducnavy687-web.github.io/QuanLyCongViecApp/
- Hosting duy nhất: GitHub Pages; không Firebase Hosting hoặc Netlify.

## Khởi tạo Web

`lib/firebase_options.dart` chứa FirebaseOptions của Web App đã đăng ký.
`FirebaseAuthService` truyền options khi khởi tạo Web. Không thêm Firebase JS
SDK thủ công vào HTML, không cần npm firebase. Config là định danh client công
khai, không phải service-account/private key/OAuth client secret.

Native vẫn thử cấu hình mặc định của nền tảng và giữ Google Sign-In hiện có.
Phase này không đăng ký native app, không cung cấp native production config.
Nếu native chưa cấu hình Firebase, Demo vẫn dùng được.

## Google Authentication

Firebase Console → Authentication → Sign-in method: bật Google.
Authorized domains phải có `anhducnavy687-web.github.io` (không protocol/path).
Để kiểm thử local, kiểm tra `localhost` cũng được cho phép; không giả định nó
đã được thêm tự động.

Web gọi `FirebaseAuth.signInWithPopup(GoogleAuthProvider())`, không dùng
`GoogleSignIn.signIn()` hoặc People API. Giữ authDomain của config:
`quanlycongviecapp-129de.firebaseapp.com`. Không đổi authDomain thành domain
GitHub Pages vì Pages không phục vụ Firebase auth helper tại `/__/auth/`.

Popup phải bắt đầu từ nút bấm. Nếu trình duyệt chặn popup, cho phép popup và
bấm lại. Hủy popup, domain chưa được cấp quyền, mạng lỗi được báo bằng tiếng
Việt. Không tự fallback redirect: redirect cross-domain có giới hạn third-party
storage, cần thiết kế/kiểm thử riêng nếu bổ sung sau này.

Firebase khôi phục phiên qua sự kiện auth đầu tiên. Session theo dõi thay đổi
UID, hủy repository/listeners cũ trước khi thay, và bỏ kết quả tải đã lỗi thời.

## Firestore và rules

Dữ liệu giữ nguyên dưới `users/{uid}/...`; UID lấy từ Firebase Authentication.
`firestore.rules` cho chủ UID truy cập các collection đã khai báo, từ chối user
khác, user chưa đăng nhập và mọi đường dẫn ngoài schema. Rules chưa xác thực
schema field; phase này không thay schema/rules để mở quyền rộng hơn.

`firebase.json` chỉ cấu hình Firestore rules. `.firebaserc` trỏ đúng project.
Sau khi có Firebase CLI và đăng nhập tài khoản có quyền:

```powershell
firebase login
firebase deploy --only firestore:rules --project quanlycongviecapp-129de
```

Nếu dùng CLI qua npx: `npx --yes firebase-tools` thay cho `firebase`.
Không chạy deploy tất cả services. Không deploy Storage rules.
Sau deploy, đối chiếu Rules đang publish trong Firebase Console với file repo
(hoặc đọc Firebase Rules API release `cloud.firestore` và đối chiếu nội dung).

Repository chờ snapshot đầu tiên từ server, gồm subcollections của hồ sơ ban
đầu. Cache offline rỗng không được coi là dữ liệu server rỗng. Timeout/lỗi quyền
hiển thị lỗi và cho retry. Listener lỗi sau đăng nhập chặn màn hình dữ liệu cũ
và có nút tải lại/đăng xuất. Snapshot listeners bị hủy khi repository dispose.

Thanh toán cộng tác viên ghi transaction, timeline và tăng paidAmount trong
cùng Firestore transaction. Xóa thanh toán đọc document server trước khi trừ,
tránh trừ hai lần. Chỉnh thông tin phân công không ghi đè paidAmount từ cache.
Firestore transaction cần kết nối mạng; thao tác thất bại cần thử lại.

## Storage deferred

Firebase Storage chưa bật, không nâng Blaze hoặc cấu hình billing trong Phase
1.4. Firebase Mode thông báo chưa hỗ trợ tải tài liệu. Demo giữ hành vi cũ.
Các file/package Storage có sẵn không có nghĩa Storage production đã hoạt động.

## Kiểm thử PC ↔ điện thoại

1. Mở URL production trên PC và trình duyệt điện thoại; đăng nhập cùng Google.
2. Xác nhận cùng UID trong Firebase Authentication và đường dẫn `users/{uid}`.
3. Tạo nhóm/hồ sơ/công việc trên PC, xem trên điện thoại; sửa ngược lại.
4. Reload, đóng/mở lại tab; kiểm tra phiên và dữ liệu vẫn đúng.
5. Hai thiết bị cùng thêm thanh toán CTV; tổng paidAmount phải bằng lịch sử tiền.
6. Xóa một thanh toán, kiểm tra tổng giảm đúng một lần.
7. Đăng xuất rồi đổi tài khoản B: không còn dữ liệu A. Kiểm thử rules từ chối
   đọc/ghi UID khác, không chỉ dựa vào việc UI ẩn dữ liệu.
8. Thử hủy/chặn popup, mất mạng, quyền bị từ chối, retry; Demo vẫn mở được.
9. Kiểm tra 390×844, 768×1024, 1440×900; production không có MobilePreviewFrame.

Tests trong repo dùng SDK mocks/FakeFirestore cho auth, session, listener,
đồng thời và rules document access (inline hai helper được kiểm tra nguyên văn vì fake parser không hỗ trợ function). Chúng không thay thế Google login thật,
Firestore production CRUD, transaction contention server hoặc rules query test.
Không đánh dấu các bước production này thành công chỉ vì unit tests pass.

## Tài liệu chính thức

- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/auth/flutter/federated-auth
- https://firebase.google.com/docs/auth/web/redirect-best-practices
- https://firebase.google.com/docs/firestore/manage-data/transactions
