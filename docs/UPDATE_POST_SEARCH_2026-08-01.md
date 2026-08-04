# Cập nhật Đăng tin / Tìm nhà - 2026-08-01

## Luồng điều hướng mới

- Chọn **Đăng tin** ở thanh điều hướng dưới sẽ mở trang `LandlordRequestPage` ngay trong `MainShell`.
- Trang này mô phỏng nội dung và bố cục của web `/Landlord/Request`: giới thiệu lợi ích, đăng tin miễn phí, dịch vụ VR 360 và biểu mẫu đăng ký dịch vụ.
- Nút **Đăng tin miễn phí** trên trang mới vẫn đi qua `AuthGate.ensurePostingPermission`, sau đó mở màn quản lý/tạo tin của đối tác.
- Chọn nút giữa **Tìm nhà** sẽ mở `SearchPage` và đánh dấu nút giữa là trạng thái đang chọn.

## Logic tìm kiếm

- Bộ lọc gồm từ khóa, hình thức, tỉnh/thành, phường/xã, loại bất động sản và khoảng giá nhanh.
- Kết quả đang hiển thị được lọc ngay từ dữ liệu đã tải để phản hồi nhanh.
- Khi nhấn **Tìm kiếm**, ứng dụng gọi Mobile API để lấy tối đa 50 kết quả phù hợp, tránh bị giới hạn bởi số tin đã tải ở trang chủ.
- Nếu API tạm thời lỗi, ứng dụng giữ kết quả dự phòng từ dữ liệu hiện có và hiển thị thông báo lỗi.

## API biểu mẫu chủ nhà

Mobile app gọi:

`POST /mobile-api/landlord/request?lang=vi-VN`

JSON body:

```json
{
  "guestName": "Nguyễn Văn A",
  "guestPhone": "0987654321",
  "propertyAddress": "Địa chỉ bất động sản",
  "customerNotes": "Nhu cầu hoặc ghi chú"
}
```

Backend kiểm tra trường bắt buộc, chuẩn hóa số điện thoại Việt Nam, chặn yêu cầu đang chờ xử lý trùng số điện thoại và lưu vào bảng `leads` với loại `landlord_request`.

## Tệp thay đổi chính

### Flutter

- `lib/features/main_shell.dart`
- `lib/features/landlord_request_page.dart`
- `lib/features/search_page.dart`
- `lib/app/app_store.dart`
- `lib/data/remote/nhawow_api_service.dart`
- `lib/l10n/app_localizations.dart`

### ASP.NET MVC

- `Homenow/Controllers/MobileApiController.cs`
- `Homenow/App_Start/RouteConfig.cs`

## Tài nguyên ảnh

Gói mobile người dùng gửi không chứa thư mục `assets/web_assets`. Bản sửa đã bổ sung đủ 44 tệp ảnh được `AppAssets` tham chiếu để dự án có thể đóng gói. Các ảnh Landlord/VR chính được tách từ ảnh mẫu người dùng gửi; nhóm icon tiện ích và ảnh hướng dẫn là ảnh dự phòng, có thể thay bằng bộ ảnh gốc mà không cần sửa code.
