# Sửa VR vẫn chuyển sang web

## Nguyên nhân

Project đang chạy bằng cấu hình VS Code `deviceId: chrome`, nên đây là Flutter Web. File `lib/features/vr_page.dart` trước đó chọn `vr_page_web.dart` khi `dart.library.html = true`. Màn web cũ chỉ có nút **Mở VR 360°** và dùng `url_launcher` mở `/Property/Vr/{id}`, vì vậy đóng VR sẽ quay về trang Detail của website.

## Đã sửa

- Android, iOS và Flutter Web đều dùng trực tiếp `PanoramaViewer`.
- Không còn gọi `/Property/Vr/{id}` khi bấm VR.
- Không còn nút trung gian **Mở VR 360°**.
- Flutter Web lấy `vrScenes` và `hotspots` trực tiếp từ `/mobile-api/properties/{id}/vr` giống Android/iOS.
- Ẩn nút cảm biến trên Web vì package không hỗ trợ sensor trên Web.
- Chỉ bật chế độ immersive của hệ điều hành trên Android/iOS.
- Tách rõ cấu hình chạy Web và cấu hình chạy Android/iOS trong `.vscode/launch.json`.

## Chạy lại

```bash
flutter clean
flutter pub get
flutter run -d chrome --dart-define=NHAWOW_API_BASE_URL=https://localhost:44323/mobile-api
```

Khi test APK/điện thoại thật, không dùng `localhost`; dùng domain IIS hoặc IP LAN mà điện thoại truy cập được.

## Dấu hiệu bản mới đã chạy

Sau khi bấm **Xem VR 360°**, app phải đi thẳng tới panorama. Không còn màn nền đen có nút **Mở VR 360°**. Khi bấm X/Quay lại, app trở về trang Detail Flutter, không trở về trang Detail của website.
