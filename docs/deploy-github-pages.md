# Deploy Flutter Web lên GitHub Pages — Phase 1.3

Luồng production: **Push branch → GitHub Actions → Flutter build → GitHub Pages**.

- Branch: `claude/stoic-goldberg-qcky72`.
- Workflow: `.github/workflows/deploy-pages.yml` (Deploy Flutter Web to GitHub Pages).
- Production URL dự kiến: https://anhducnavy687-web.github.io/QuanLyCongViecApp/.
- Người dùng mở URL bằng iPhone Safari, Android Chrome, Windows Chrome/Edge,
  trình duyệt macOS hoặc tablet; không phải cài app.
- Flutter **3.47.4 stable / Dart 3.13.3**, được ghim cho CI và local checks.

## Bật Pages một lần trên GitHub

1. Repository → **Settings → Pages → Build and deployment → Source → GitHub Actions**.
2. Settings → Environments → **github-pages** → Deployment branches and tags:
   cho phép branch `claude/stoic-goldberg-qcky72` nếu đang giới hạn branch.
3. Settings → Actions → General: bảo đảm GitHub Actions và các actions trong
   workflow được cho phép, gồm `subosito/flutter-action`.
4. Push code lên branch trên, rồi vào **Actions → Deploy Flutter Web to GitHub Pages**.
   Chỉ coi deployment thành công khi cả `build` và `deploy` xanh và URL mở được.

Workflow dùng `GITHUB_TOKEN` mặc định: build có `contents: read`; deploy có
`pages: write`, `id-token: write`, environment `github-pages`. Không cần PAT.
SDK do `subosito/flutter-action@v2` cài; không clone Flutter vào repository.
Official Pages actions: configure-pages@v5, upload-pages-artifact@v4,
deploy-pages@v4; checkout@v6. Artifact là `build/web`.

## Chạy thủ công

Actions → **Deploy Flutter Web to GitHub Pages → Run workflow** → chọn
`claude/stoic-goldberg-qcky72` → Run workflow (`workflow_dispatch`).
Workflow có guard, không deploy branch khác.

GitHub yêu cầu workflow có mặt trên default branch để hiển thị nút Run workflow.
Nếu default branch vẫn là `main` và chưa chứa workflow, nút có thể chưa xuất hiện.
Task này không merge/push main hoặc đổi default branch. Khi đó dùng push trigger
hoặc **Re-run all jobs** trên run đã có; chủ repository quyết định riêng cách
đưa workflow lên default branch hoặc đổi default branch nếu muốn bật nút này.

## Local checks và build production

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release --base-href "/QuanLyCongViecApp/" --no-web-resources-cdn
```

CI dùng `flutter pub get --enforce-lockfile` để giữ dependency đã khóa.
CI analyze dùng `--no-fatal-infos` vì có info-level lint từ Phase 1.2;
warning/error vẫn làm job thất bại. Không tắt test hay bỏ qua lỗi build.

`web/index.html` giữ `$FLUTTER_BASE_HREF`. Output `build/web/index.html` phải có
`<base href="/QuanLyCongViecApp/">`. Manifest dùng `start_url: "."`, icons và
bootstrap dùng đường dẫn tương đối. CanvasKit được bundle tại chỗ bằng
`--no-web-resources-cdn`; điều này không loại bỏ mạng/CDN cần cho Firebase.
Kiểm tra output có index.html, flutter_bootstrap.js, main.dart.js, assets,
manifest.json và icons. `build/` đã được gitignore, không commit output.

Local development không đổi: `flutter run -d chrome`.
Release dùng `kIsWeb && !kReleaseMode` để loại MobilePreviewFrame, giữ nguyên
breakpoint compact <600, medium 600–1024, expanded >1024 của Phase 1.2.

## Routing và trình duyệt

App dùng `MaterialApp(home: ...)` và `Navigator.push(MaterialPageRoute(...))`,
không dùng path URL strategy hoặc router tạo URL `/profiles/...`.
Giữ routing hiện tại; không cần 404.html giả lập hay SPA rewrite của Netlify.
URL gốc dưới `/QuanLyCongViecApp/` tải được; fragment/hash không được gửi tới
server. Refresh tải lại app, không khôi phục màn hình chi tiết và dữ liệu Demo
trong RAM. Browser Back cần kiểm tra riêng với lịch sử Navigator hiện tại;
không coi app có deep linking tới từng hồ sơ.

Sau deploy, kiểm tra vào Demo, mở hồ sơ, Back, refresh, các tab và resize ở
390×844, 768×1024, 1440×900; kiểm tra thêm trên Safari/iPhone thật nếu có thiết bị.

## Firebase và Google Sign-In: các bước chưa được thực hiện tự động

Firebase Console → **Authentication → Settings → Authorized domains** → thêm:

```text
anhducnavy687-web.github.io
```

Không thêm `https://` hoặc `/QuanLyCongViecApp/` vào Authorized domains.

**Repository hiện chưa cấu hình Firebase Web**: không có firebase_options.dart;
`FirebaseAuthService` gọi `Firebase.initializeApp()` không truyền options,
và web/index.html chưa khai báo Google OAuth client ID. Demo Mode vẫn hoạt động,
nhưng thêm domain đơn thuần chưa đủ để đăng nhập thật. Phase 1.3 giữ code này,
không tự tạo Firebase project hay bịa cấu hình tài khoản.

Để bật Firebase thật, chủ project cần hoàn tất và kiểm thử riêng:

1. Firebase Console → Project settings → Your apps: đăng ký/chọn Web app của
   đúng Firebase project; chạy `flutterfire configure` và chọn Web (giữ các
   native targets đang dùng). Dùng options được sinh ra với
   `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
   trong FirebaseAuthService theo [firebase-setup.md](firebase-setup.md).
2. Authentication → Sign-in method → bật Google; thêm Authorized Domain trên.
3. Với implementation `google_sign_in` hiện tại: cấu hình Web OAuth client ID
   theo google_sign_in_web (meta `google-signin-client_id` trong web/index.html
   hoặc clientId trong code). Với lời gọi `GoogleSignIn.signIn()` hiện tại,
   bật **Google People API** trong Google Cloud Console → APIs & Services →
   Library; plugin dùng API này để lấy thông tin người dùng trên Web.
   Google Cloud Console → APIs & Services →
   Credentials → OAuth 2.0 Client IDs → Web client → Authorized JavaScript
   origins: thêm `https://anhducnavy687-web.github.io` (không thêm subpath).
   Hoàn tất OAuth consent screen/test users nếu project còn ở chế độ testing.
4. Kiểm thử đăng nhập, đăng xuất, Firestore/Storage và UID isolation bằng tài
   khoản thật. Không nới rules để chữa lỗi đăng nhập. Không đưa service account,
   private key hoặc client secret vào Web build/repository. Firebase client
   options/OAuth client ID không phải server-side secret.

Không có thay đổi đối với FirebaseRepository, DemoRepository, Firestore rules,
Storage rules hoặc đường dẫn dữ liệu theo UID trong phase deployment này.

## Ngừng Netlify

`netlify.toml` được loại bỏ, hướng dẫn Netlify cũ chuyển thành thông báo legacy.
Nếu trước đây đã kết nối một Netlify site với GitHub, chủ site cần vào Netlify
để dừng auto-publish/builds hoặc ngắt liên kết Git. Xóa config trong Git không
tự tắt site/build hook đã lưu trong tài khoản Netlify. Không deploy mới lên Netlify.

## Tài liệu chính thức

- [GitHub Pages custom workflows](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)
- [Manual workflows](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow)
- [Flutter setup action](https://github.com/subosito/flutter-action)
- [google_sign_in_web 0.12.4+4](https://pub.dev/packages/google_sign_in_web/versions/0.12.4+4)

## Kết quả kiểm tra local Phase 1.3

- Flutter 3.47.4 / Dart 3.13.3; `flutter pub get` thành công.
- `flutter analyze`: 2 info baseline `use_build_context_synchronously` tại
  attachment_section.dart:62 và :64; không có warning/error mới.
- `flutter test`: 74 tests pass (có cảnh báo hit-test từ responsive test).
- Web release build thành công; base href và các file output đã kiểm tra.
- YAML parse và các trường branch/dispatch/permissions/SDK/artifact/deploy đạt.
- Smoke test Edge headless tại subpath `/QuanLyCongViecApp/`: 390×844,
  768×1024, 1440×900; Demo, hồ sơ, browser Back, tab navigation và refresh
  HTTP 200 đạt; không thấy MobilePreviewFrame, thiếu asset hoặc page error.
- Đây là kiểm tra local trên Edge, chưa phải kiểm thử Safari/iPhone/macOS thật
  hoặc xác nhận URL production đã online.

Local SDK nằm ngoài repository. Trên Windows, đường dẫn SDK có dấu cách có
thể làm native-assets hook của test thất bại; lần kiểm tra này dùng junction
tạm ngoài repository với đường dẫn không có dấu cách. Không sửa dependency
hoặc code để né lỗi môi trường này. CI Ubuntu không dùng đường dẫn đó.
