# Cập nhật chỉnh sửa tin và định dạng giá – 2026-08-01

- Nút **Chỉnh sửa** tại màn `PartnerPropertiesPage` tải dữ liệu bài đăng từ Mobile API và mở lại `PropertyFormPage` ở chế độ chỉnh sửa.
- Đồng bộ dữ liệu địa chỉ, giá, diện tích, trường riêng theo loại tin, tiện ích, phòng/hướng và ảnh hiện có.
- Cho phép giữ, đổi ảnh bìa, xóa ảnh cũ và thêm ảnh mới; tổng tối đa 12 ảnh.
- Khi lưu chỉnh sửa, bài đăng chuyển về trạng thái `pendingapproval` giống luồng Partner/EditProperty của web.
- Ô giá tự phân tách hàng nghìn khi nhập và hiển thị giá rút gọn bên dưới, ví dụ `4.000.000` → `4 triệu/tháng`.

Backend cần được triển khai trước khi chạy bản mobile mới vì có thêm hai endpoint:

- `GET /mobile-api/partner/properties/{id}/edit`
- `POST /mobile-api/partner/properties/{id}/update`
