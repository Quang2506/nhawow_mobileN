# VR 360° hiển thị trực tiếp trong Flutter

## Thay đổi

- Bỏ luồng tự động mở Chrome/Safari từ `VrPage`.
- Nhúng route `/Property/Vr/{id}` vào `WebViewWidget` toàn màn hình.
- Giữ nguyên toàn bộ logic Pannellum của web: scene mặc định, hotspot chuyển phòng,
  yaw, pitch, hfov, đa ngôn ngữ và scene bar.
- Thêm cầu nối JavaScript để Flutter nhận trạng thái tải, scene hiện tại và lỗi VR.
- Chặn chuyển sang trang Detail của web; nút quay lại luôn trở về Detail của app.
- Ẩn nút đóng và nhãn Pannellum của web trong WebView để không bị trùng giao diện.
- Tối ưu scene bar trên điện thoại thành cuộn ngang một dòng.
- Tự prefetch scene equirectangular kế tiếp sau khi scene hiện tại tải xong;
  tự bỏ qua khi bật tiết kiệm dữ liệu hoặc mạng 2G.
- Giữ cache WebView, không xóa cache khi mở/đóng để lần xem sau nhanh hơn.
- Có progress, timeout 35 giây, thông báo lỗi và nút tải lại.
- Flutter Web vẫn có màn dự phòng vì `webview_flutter` chỉ dành cho app native.

## File thay đổi

- `pubspec.yaml`
- `lib/features/vr_page.dart`
- `lib/features/vr/vr_page_mobile.dart`
- `lib/features/vr/vr_page_web.dart`

## Sau khi nhận project

```bash
flutter clean
flutter pub get
flutter analyze
flutter run
```

Khi test trên điện thoại thật, `https://localhost:44323` không trỏ tới máy tính.
Hãy dùng domain IIS thật hoặc IP LAN/HTTPS mà điện thoại truy cập được.
