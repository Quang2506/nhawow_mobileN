# NhaWOW – VR 360° native cho Flutter

Ngày cập nhật: 30/07/2026

## Kết quả

Trên Android và iOS, nút **Xem VR 360°** không còn mở WebView, Chrome, Safari hoặc URL `/Property/Vr/{id}`. Ứng dụng lấy JSON scene/hotspot từ Mobile API rồi dựng panorama trực tiếp bằng Flutter.

## Luồng mới

1. Flutter gọi `GET /mobile-api/properties/{propertyId}/vr?lang=vi-VN`.
2. API trả scene mặc định, URL panorama, góc nhìn và toàn bộ hotspot.
3. Flutter chọn `isDefault`, tải ảnh bằng `CachedNetworkImageProvider`, rồi dựng bằng `PanoramaViewer`.
4. `pitch` của Pannellum được dùng làm `latitude`; `yaw` dùng làm `longitude`.
5. Bấm hotspot sẽ hướng góc nhìn về cửa, tải scene đích, rồi áp dụng `targetPitch`, `targetYaw`, `targetHfov`.
6. Thanh phòng phía dưới cho phép đổi scene thủ công.

## Tối ưu đã áp dụng

- Chỉ giữ scene hiện tại và tối đa một scene lân cận trong RAM.
- Chỉ preload một scene khi đang dùng Wi‑Fi/Ethernet; không preload nền trên mạng di động.
- Giữ scene cũ trong lúc tải/giải mã scene mới.
- Sau khi texture mới dựng xong, giải phóng bản giải mã của scene cũ; file cache trên ổ đĩa vẫn được giữ.
- Dùng ảnh preview/thumbnail trong lúc dựng texture.
- Cảm biến xoay mặc định tắt; người dùng chủ động bật.
- Giữ một `PanoramaViewer` duy nhất trong suốt tour; không tạo lại viewer khi đổi scene/cảm biến, tránh tích lũy listener của controller và giữ texture ổn định.
- Không dùng hiệu ứng chồng hai panorama, tránh tăng gấp đôi GPU texture.
- Mesh giảm còn `24 x 48` để mượt hơn trên thiết bị trung bình/yếu.
- Có nút tự xoay, đặt lại góc nhìn, phóng to và thu nhỏ.
- API Detail chỉ kiểm tra `Any` để biết có VR; scene/hotspot chỉ được tải khi người dùng thật sự mở VR.
- Endpoint VR chỉ tải bản dịch đúng ngôn ngữ và không truy vấn PostgreSQL thêm lần nữa để lấy scene mặc định.

## File Web thay đổi

- `Homenow/Controllers/MobileApiController.cs`
- `Homenow/App_Start/RouteConfig.cs`

API VR trả mỗi scene gồm:

```json
{
  "sceneKey": "phong-khach",
  "title": "Phòng khách",
  "panoramaUrl": "https://.../panorama.jpg",
  "mobilePanoramaUrl": "https://.../panorama.jpg",
  "previewUrl": "https://.../preview.jpg",
  "isDefault": true,
  "hfov": 110,
  "pitch": 0,
  "yaw": 0,
  "hotspots": [
    {
      "pitch": -5.5,
      "yaw": 92.3,
      "text": "Đi tới phòng ngủ",
      "targetSceneKey": "phong-ngu",
      "targetSceneExists": true,
      "targetPitch": 0,
      "targetYaw": 180,
      "targetHfov": 110
    }
  ]
}
```

## File Flutter thay đổi

- `pubspec.yaml`
- `lib/models/models.dart`
- `lib/data/remote/nhawow_api_service.dart`
- `lib/features/vr_page.dart`
- `lib/features/vr/vr_page_mobile.dart`

Các package mới:

```yaml
panorama_viewer: ^2.0.7
cached_network_image: ^3.4.1
connectivity_plus: ^7.3.1
```

`webview_flutter` đã được bỏ khỏi `pubspec.yaml`. `url_launcher` vẫn được giữ vì các chức năng khác và màn dự phòng Flutter Web còn sử dụng.

## Cách chạy

### Web

1. Rebuild Solution.
2. Publish website/API lên IIS.
3. Recycle Application Pool.
4. Kiểm tra:

```text
https://TEN-MIEN/mobile-api/properties/145/vr?lang=vi-VN
```

Kết quả phải có `success: true`, `data.scenes` và `hotspots`.

### Flutter

Do dependency đã thay đổi và các file plugin được tạo lại theo máy phát triển, bắt buộc chạy:

```bash
flutter clean
flutter pub get
flutter analyze
flutter run --dart-define=NHAWOW_API_BASE_URL=https://TEN-MIEN/mobile-api
```

Không dùng `localhost` khi chạy trên điện thoại thật. Điện thoại phải truy cập được domain IIS hoặc IP LAN của máy chủ. Với bản phát hành nên dùng HTTPS.

## Kiểm tra chức năng

- Mở căn có VR và bấm **Xem VR 360°**.
- Không xuất hiện Chrome/Safari/WebView hay thanh địa chỉ website.
- Scene mặc định hiển thị trong màn Flutter toàn màn hình.
- Kéo, chụm zoom, bật/tắt cảm biến hoạt động.
- Bấm hotspot chuyển đúng phòng và đúng góc đích.
- Thanh phòng phía dưới đổi scene được.
- Sau khi sửa hotspot/scene trên Admin, đóng và mở lại màn VR để lấy JSON mới.

## Lưu ý ảnh

Luồng upload Web hiện đã tạo ảnh panorama equirectangular tối đa khoảng 4096 px chiều ngang. Đây là URL `PanoramaUrl` mà Mobile API trả cho Flutter. Không trả bộ tile multires của web cho app native.

## Phạm vi kiểm tra

Đã kiểm tra cấu trúc C#/Dart, cân bằng ngoặc, YAML và tính toàn vẹn gói ZIP. Môi trường đóng gói không có Visual Studio Build Tools và Flutter SDK nên chưa thể chạy `Rebuild Solution`, `flutter analyze` hoặc build APK/IPA thực tế.
