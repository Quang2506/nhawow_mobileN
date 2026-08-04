# NhaWOW Mobile – VR 360° native

- Android/iOS lấy `vrScenes` và `hotspots` trực tiếp từ Mobile API.
- Dựng ảnh equirectangular bằng `PanoramaViewer`; không mở WebView, Chrome hoặc Safari.
- Hotspot dùng trực tiếp `pitch/yaw`; khi chuyển phòng áp dụng `targetPitch`, `targetYaw`, `targetHfov`.
- Chỉ giữ một `PanoramaViewer` trong suốt tour để giữ texture và tránh tích lũy listener của controller.
- Scene hiện tại được giữ trên màn hình trong lúc scene đích tải và giải mã.
- Chỉ preload tối đa một scene liền kề, chỉ khi Wi‑Fi/Ethernet.
- Ảnh được cache trên ổ đĩa; bản giải mã scene cũ được loại khỏi RAM sau khi texture mới sẵn sàng.
- Preview/thumbnail hiển thị trong lúc dựng texture.
- Cảm biến mặc định tắt; có tự xoay, reset góc nhìn và zoom.

Sau khi nhận source:

```bash
flutter clean
flutter pub get
flutter analyze
flutter run --dart-define=NHAWOW_API_BASE_URL=https://TEN-MIEN/mobile-api
```
