# Đồng bộ hiển thị địa chỉ Web → Mobile

## Logic lấy từ Web

Web lưu địa chỉ hiển thị công khai trong `properties.address_line` và Mobile API trả về trường `address`:

- Không chọn hiển thị địa chỉ cũ: hiển thị địa chỉ mới.
- Có chọn hiển thị địa chỉ cũ: `Địa chỉ cũ (Phường/Xã mới, Tỉnh/Thành phố mới mới)`.
- Bản đồ vẫn dùng `new_address_line`, không dùng địa chỉ cũ.

Ví dụ hiển thị:

`Xóm Lộc, Mỹ Lộc, Nam Định (Mỹ Lộc, Ninh Bình mới)`

## Thay đổi trong Flutter

- Card bất động sản dùng `property.displayAddress` thay vì tự ghép `ward, city`.
- Địa chỉ trên card được phép hiển thị tối đa 2 dòng.
- Trang chi tiết và phần vị trí dùng cùng một địa chỉ công khai.
- Tìm kiếm nội bộ cũng tìm theo địa chỉ công khai.
- Có fallback ghép `ward, city` nếu API cũ chưa trả trường `address`.
- Hỗ trợ đọc cả `address`, `addressLine` và `address_line` từ JSON.

## File đã sửa

- `lib/models/models.dart`
- `lib/core/widgets.dart`
- `lib/features/property_detail_page.dart`
- `lib/app/app_store.dart`
