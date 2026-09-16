# Netlify — tài liệu legacy

Từ Phase 1.3, Netlify không còn là production hosting. Không dùng hướng dẫn
Netlify cũ để triển khai mới. Cấu hình `netlify.toml` đã được loại bỏ.

Xem [Deploy GitHub Pages](deploy-github-pages.md):
`Push claude/stoic-goldberg-qcky72 → GitHub Actions → Flutter Web release → GitHub Pages`.

Production URL dự kiến: https://anhducnavy687-web.github.io/QuanLyCongViecApp/.

Nếu đã có Netlify site liên kết GitHub, chủ tài khoản cần dừng auto-publish/builds
hoặc ngắt liên kết Git trong Netlify. Thay đổi repository không tự tắt site cũ.
