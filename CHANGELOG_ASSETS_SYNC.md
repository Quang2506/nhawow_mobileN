# Thay đổi đồng bộ ảnh Web → Mobile

- Dùng nguồn ảnh chuẩn `Homenow/Assets` và URL `/Assets/...`.
- Thêm `MediaUrlResolver` hỗ trợ URL cũ `/media`, `/img`, `/Content/VR` và đường dẫn ổ D.
- Tập trung toàn bộ ảnh mạng qua `AppNetworkImage`, dùng HTML element trên Flutter Web để tránh lỗi CORS ảnh.
- Thay `NetworkImage` trong avatar bằng `AppAvatar` có fallback chữ cái.
- Đóng gói logo, banner, 20 icon tiện ích và toàn bộ ảnh hướng dẫn vào app.
- Trang chủ dùng đúng banner Ninh Bình từ Web.
- Trang yêu cầu chủ nhà dùng đúng banner Web.
- Chi tiết bất động sản hiển thị icon tiện ích tương ứng.
- Thêm trang Hướng dẫn đăng tin đồng bộ 7 bước của Web.
- Thêm `.vscode/settings.json` để VS Code nhận Flutter SDK trên máy hiện tại.
- Thêm unit test cho quy tắc đổi URL ảnh.
- Thêm tài liệu đối chiếu toàn bộ chức năng Web và trạng thái Mobile.
