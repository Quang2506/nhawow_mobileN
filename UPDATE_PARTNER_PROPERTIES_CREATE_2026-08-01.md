# Cập nhật PartnerProperties và đăng tin trên mobile — 2026-08-01

## 1. PartnerProperties

- Danh sách được lấy riêng từ API theo tài khoản đối tác đang đăng nhập.
- Bổ sung bộ lọc Tỉnh/Thành phố, Phường/Xã và Trạng thái.
- Phường/Xã tải lại theo Tỉnh/Thành phố.
- Có nút Áp dụng, Đặt lại và kéo xuống để tải lại danh sách.

## 2. Luồng tạo bài đăng

- Bước 1: chọn Bán nhà, Thuê nhà, Đất bán hoặc Mặt bằng.
- Bước 2: chọn loại bất động sản phù hợp với hình thức ở bước 1.
- Nút Quay lại ở bước 2 quay về bước 1; nút đóng/hủy kết thúc luồng.

## 3. Form đăng tin đồng bộ với web Partner/CreateProperty

- Địa chỉ hành chính mới và tùy chọn hiển thị địa chỉ cũ.
- Giá không bắt buộc; diện tích bắt buộc.
- Hướng nhà, thông tin phòng kèm số lượng, tiện ích/nội thất.
- Tiện ích mặt bằng được lọc theo loại mặt bằng.
- Trường riêng cho bán nhà, thuê nhà, đất bán, văn phòng, kho bãi,
  nhà xưởng, mặt bằng kinh doanh, mặt bằng đất và sang nhượng.
- Chọn tối đa 12 ảnh, chọn ảnh bìa và gửi bài ở trạng thái chờ duyệt.

## 4. Sau khi thay code

1. Triển khai backend đi kèm lên IIS trước.
2. Trong project Flutter chạy `flutter pub get` để cập nhật `image_picker`.
3. Build/cài lại ứng dụng.
