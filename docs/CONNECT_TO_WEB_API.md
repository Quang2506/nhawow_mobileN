# Kết nối NhaWOW Flutter với website ASP.NET MVC

## Chạy website trước

Mở solution web bằng Visual Studio và chạy project `Homenow`.

Kiểm tra:

```text
https://localhost:44323/mobile-api/health
```

Nếu port IIS Express thay đổi, dùng port mới trong lệnh Flutter.

## Chạy Flutter trên Chrome

```powershell
$flutter = "C:\Flutter\flutter_windows_3.44.6-stable\flutter\bin\flutter.bat"
Set-Location D:\Code\nhawow_mobile

& $flutter run -d chrome `
  --dart-define=NHAWOW_API_BASE_URL=https://localhost:44323/mobile-api
```

VS Code đã có `.vscode/launch.json`, nên cũng có thể chọn cấu hình:

```text
NhaWOW Web + ASP.NET API
```

rồi nhấn `F5`.

## Dữ liệu được tải

Khi ứng dụng khởi động, `AppStore` tải 4 nhóm:

- Bán nhà (`sale` + `house`)
- Thuê nhà (`rent` + `house`)
- Đất bán (`land_sale` + `land`)
- Mặt bằng (`premises` + `land`)

Khi mở chi tiết, ứng dụng gọi `/mobile-api/properties/{id}` để lấy:

- mô tả;
- tiện ích;
- thông tin chủ tin;
- vị trí;
- toàn bộ danh sách ảnh thumbnail public.

## Khi API chưa chạy

Ứng dụng hiển thị banner lỗi và tạm dùng dữ liệu mẫu để bạn vẫn kiểm tra giao diện. Nhấn `Thử lại` sau khi website đã chạy.

## Chạy trên Android sau này

Android không thể dùng `localhost` của máy tính. Hãy thay bằng IP LAN hoặc domain HTTPS:

```powershell
& $flutter run -d <android-device-id> `
  --dart-define=NHAWOW_API_BASE_URL=https://api.nhawow.vn/mobile-api
```

Project đã thêm quyền `android.permission.INTERNET` vào manifest chính.

## Không dùng package bên ngoài

HTTP client được viết bằng thư viện chuẩn:

- Flutter Web: `dart:html`
- Android/iOS: `dart:io`

Vì vậy project không cần tải package `http` hoặc `dio` từ `pub.dev`, phù hợp với mạng công ty hiện tại.
