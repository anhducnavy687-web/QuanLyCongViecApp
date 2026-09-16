# Deploy bản Web production lên Netlify

Mục tiêu: có một URL dạng `https://<tên-site>.netlify.app` để mở **toàn bộ
ứng dụng** (không phải bản xem trước) trên bất kỳ trình duyệt nào
(điện thoại, máy tính bảng, laptop) — **không cần cài Flutter, Git hay
tải source code** trên thiết bị dùng để xem.

> Từ Phase 1.2, Netlify là **nền tảng triển khai production chính thức**
> của ứng dụng: `GitHub → Netlify build (Flutter Web) → HTTPS URL →
> Trình duyệt → Firebase (Auth + Firestore)`. Android/iOS vẫn được hỗ trợ
> build (xem [README.md](../README.md) mục 5–7) nhưng không còn là kênh
> phân phối bắt buộc duy nhất — người dùng có thể dùng đầy đủ tính năng
> chỉ qua URL, không cần cài app.

## Vì sao không deploy trực tiếp từ Claude Code

Môi trường chạy Claude Code cho phiên này chặn kết nối ra
`api.netlify.com` theo chính sách mạng của tổ chức (giống cách nó chặn
`dl.google.com` khi cần cài Android SDK) — không phải vấn đề thiếu quyền
hay thiếu token, mà do egress proxy từ chối kết nối. Vì vậy việc deploy
cần thực hiện qua giao diện web Netlify.

Repo đã có sẵn [`netlify.toml`](../netlify.toml) ở thư mục gốc, tự cấu
hình để **máy build của Netlify tự tải Flutter SDK và build bản Web
production** — bạn không cần cài gì cả, chỉ cần kết nối repo với Netlify.

## Cách 1 — Kết nối Git với Netlify (khuyến nghị, ~2 phút, không cần CLI)

1. Vào https://app.netlify.com và đăng nhập (có thể đăng nhập bằng tài
   khoản GitHub cho nhanh).
2. Bấm **Add new site → Import an existing project**.
3. Chọn **GitHub**, cấp quyền truy cập nếu được hỏi, rồi chọn repository
   **`anhducnavy687-web/QuanLyCongViecApp`**.
4. Ở bước chọn nhánh (branch to deploy), chọn:
   ```
   claude/stoic-goldberg-qcky72
   ```
5. Netlify sẽ tự đọc `netlify.toml` và điền sẵn:
   - **Build command**: lệnh tự tải Flutter + build (đã có sẵn trong
     `netlify.toml`, không cần gõ lại).
   - **Publish directory**: `build/web`

   Bạn không cần sửa gì — bấm thẳng **Deploy**.
6. Chờ khoảng 3–5 phút (lần build đầu tải Flutter SDK nên hơi lâu, các
   lần sau vẫn tải lại vì máy build Netlify không giữ cache thư mục SDK,
   nhưng vẫn xong trong vài phút).
7. Sau khi build xong, Netlify cấp cho bạn URL dạng:
   ```
   https://<tên-ngẫu-nhiên>.netlify.app
   ```
   Bạn có thể đổi tên site (site name) trong **Site settings → General →
   Site details → Change site name** để có URL dễ nhớ hơn, ví dụ
   `quanlycongviecapp-preview.netlify.app`.

Từ lần này về sau, **mỗi lần bạn (hoặc Claude Code) push lên nhánh
`claude/stoic-goldberg-qcky72`, Netlify sẽ tự động build và deploy lại**
— không cần làm lại các bước trên.

## Cách 2 — Deploy thủ công bằng Netlify CLI (nếu bạn có máy cài sẵn Flutter)

Chỉ cần dùng nếu bạn muốn deploy ngay từ máy cá nhân đã có Flutter, không
cần đợi Netlify tự build:

```bash
flutter build web --release --no-web-resources-cdn
npx netlify-cli deploy --dir=build/web --prod
```

Lệnh `netlify deploy` lần đầu sẽ hỏi đăng nhập (mở trình duyệt) và hỏi
link tới site Netlify đã tạo ở Cách 1 (hoặc tạo site mới ngay trong CLI).

## Sau khi deploy

- **URL public**: trang **Site overview** trên Netlify hiển thị URL
  `https://<tên-site>.netlify.app` — đây là link chính thức để mở app trên
  điện thoại/máy tính bảng/máy tính bất kỳ, không cần cài gì thêm.
- **URL quản lý**: `https://app.netlify.com/sites/<tên-site>/overview` —
  nơi xem lịch sử deploy, log build, đổi tên site, cấu hình domain riêng.
- **Xem lại giao diện**: mở URL public, chọn **"Dùng thử ở Chế độ Demo"**
  — không cần đăng nhập Google hay cấu hình Firebase, dữ liệu mẫu đã có
  sẵn (xem README mục 2). Giao diện tự thích ứng theo kích thước màn hình
  thiết bị đang mở (điện thoại/tablet/desktop).

## Bật đăng nhập Google thật trên domain Netlify (nếu dùng Firebase Mode)

Nếu đã cấu hình Firebase (xem
[docs/firebase-setup.md](firebase-setup.md)) và muốn đăng nhập Google hoạt
động trên URL Netlify (không chỉ Demo Mode):

1. Vào **Firebase Console → Authentication → Settings → Authorized
   domains**.
2. Thêm chính xác tên miền Netlify của bạn (VD
   `quanlycongviecapp.netlify.app`) — không kèm `https://` hay dấu `/`
   cuối.
3. Nếu dùng domain riêng (custom domain) trỏ về Netlify, thêm cả domain đó
   vào danh sách này.

Thiếu bước này, đăng nhập Google trên domain Netlify sẽ báo lỗi
`auth/unauthorized-domain` — Demo Mode không bị ảnh hưởng (không cần bước
này).

## Nếu build trên Netlify thất bại

Netlify hiển thị log build đầy đủ ở tab **Deploys → (bản build bị lỗi) →
Deploy log**. Các lỗi thường gặp:

- **Timeout khi clone Flutter SDK**: thử lại (Deploys → Trigger deploy →
  Clear cache and deploy site) — thường do mạng tạm thời chậm.
- **Lỗi phân giải package**: kiểm tra `pubspec.lock` đã được commit trong
  repo (đã có sẵn) để đảm bảo Netlify build đúng version dependency đã
  test.
