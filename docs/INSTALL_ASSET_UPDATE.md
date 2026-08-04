# Cài bản đồng bộ Assets

## Mobile

Giải nén project và chép đè vào project hiện tại hoặc dùng trực tiếp toàn bộ thư mục.

Sau đó chạy:

```powershell
$flutter = "C:\Flutter\flutter_windows_3.44.6-stable\flutter\bin\flutter.bat"
Set-Location D:\Code\NhawowMobile\nhawow_mobile
& $flutter clean
& $flutter pub get --offline
& $flutter analyze
& $flutter run -d chrome --dart-define=NHAWOW_API_BASE_URL=https://localhost:44323/mobile-api
```

## Web

Chép file trong gói patch Web vào:

```text
Homenow\Helpers\ExternalMediaStorage.cs
```

Bản patch ưu tiên ảnh thật nằm trong `Homenow/Assets` trước, sau đó mới fallback sang `D:\img` và `/media`.

Khởi động lại website rồi kiểm tra trực tiếp một URL:

```text
https://localhost:44323/Assets/Cities/logo.png
https://localhost:44323/Assets/properties/14/gallery/561f0428b2cf483caddf99a9452f45ef.png
```

Nếu URL thứ hai không tồn tại trên máy thực tế thì cần kiểm tra đúng tên file trong thư mục property tương ứng; Mobile sẽ hiện ảnh thay thế thay vì làm vỡ giao diện.
