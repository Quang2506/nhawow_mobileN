# Cập nhật giao diện danh sách và trang chi tiết – 27/07/2026

## Các thay đổi trong Flutter

1. Card bất động sản nhận toàn bộ danh sách ảnh từ API và hiển thị đúng bộ đếm `1/n`.
2. Có thể vuốt trực tiếp qua các ảnh ngay trên card.
3. Khi nhấn các mục Bán nhà / Thuê nhà / Đất bán / Mặt bằng hoặc nhấn Trang chủ / Tìm nhà, trang chủ cuộn mượt lên đầu trang.
4. Nhấn ảnh ở trang chi tiết để mở chế độ xem toàn màn hình; hỗ trợ vuốt ảnh và phóng to bằng hai ngón tay.
5. Trang chi tiết được sắp xếp lại theo giao diện web:
   - Thông tin cơ bản
   - Thông tin mô tả
   - Thông tin chi tiết
   - Tiện ích / Nội thất
   - Vị trí trên bản đồ
6. Các card nội dung ở trang chi tiết được kéo rộng toàn màn hình, không còn khoảng trống lớn bên phải.

## Lưu ý triển khai

Bộ đếm ảnh trên danh sách cần API mới trong project `homewow` đi kèm. Hãy cập nhật website/API trước hoặc cùng lúc với bản Flutter này.
