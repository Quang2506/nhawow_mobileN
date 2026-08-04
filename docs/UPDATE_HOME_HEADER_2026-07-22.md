# Cập nhật giao diện đầu trang chủ Mobile

Ngày cập nhật: 22/07/2026

## Nội dung đã sửa

- Loại bỏ thanh header nền trắng nằm tách riêng phía trên banner.
- Đưa logo NhaWOW, thông báo và tin nhắn lên trực tiếp trên ảnh banner.
- Thêm lời chào theo thời gian trong ngày.
- Khi chưa đăng nhập hiển thị `Khách` và nút `Đăng nhập ngay`.
- Khi đã đăng nhập hiển thị tên ngắn và ảnh đại diện tài khoản.
- Thêm ô tìm kiếm lớn trên banner.
- Thêm khối 4 chức năng nhanh: `Bán nhà`, `Thuê nhà`, `Đất bán`, `Mặt bằng`.
- Bốn chức năng nhanh mở trang tìm kiếm với đúng loại tin tương ứng.
- Giữ lại bộ chọn `Nhà / Đất & Mặt bằng` và `Mua / Thuê` bên dưới.
- Giao diện tự điều chỉnh cho mobile, tablet và màn hình web rộng.

## File chính đã thay đổi

```text
lib/features/home_page.dart
lib/core/app_assets.dart
assets/web_assets/Cities/home_hero_modern.png
```

## Lưu ý về thư mục ảnh

Gói project được tải lên không chứa thư mục `assets/web_assets` mặc dù `pubspec.yaml` đang khai báo thư mục này. Bản cập nhật đã bổ sung đầy đủ các đường dẫn ảnh cần thiết để project không bị lỗi thiếu asset khi chạy.

Khi có bộ Assets gốc của website, có thể chép đè lại ba thư mục sau để dùng hình ảnh chính thức:

```text
assets/web_assets/Amenities
assets/web_assets/Cities
assets/web_assets/Guide
```

Giữ lại file sau để tiếp tục dùng banner mới:

```text
assets/web_assets/Cities/home_hero_modern.png
```

## Chạy lại project

```powershell
flutter clean
flutter pub get
flutter run -d chrome --dart-define=NHAWOW_API_BASE_URL=https://localhost:44323/mobile-api
```
