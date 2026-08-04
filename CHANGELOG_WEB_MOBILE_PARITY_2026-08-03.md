# Đồng bộ Web / Mobile ngày 03-08-2026

## Nội dung đã sửa

1. **Tin nhắn dùng chung dữ liệu website**
   - Mobile gọi các API `/mobile-api/chat/*` mới trên backend.
   - Hội thoại, tin nhắn, số chưa đọc, ghim và đánh dấu được lưu trong cùng các bảng chat của website.
   - Tin nhắn gửi từ mobile được phát sang tab web đang mở qua SignalR.
   - Màn hội thoại mobile tự đồng bộ lại mỗi 5 giây và hiển thị được ảnh đã gửi từ website.

2. **Đăng ký tài khoản trên Flutter Web**
   - Sửa transport web để đọc nội dung JSON của HTTP 409 thay vì đổi nhầm thành lỗi kết nối/CORS.
   - Lỗi email hoặc số điện thoại đã tồn tại được hiển thị ngay dưới đúng ô nhập.
   - Nút đăng ký được khóa trong lúc gửi để tránh gửi lặp.

3. **Trang chi tiết**
   - Bỏ nút Chia sẻ ở thanh liên hệ phía dưới.
   - Icon chia sẻ trên đầu đổi sang cùng kiểu icon và thực hiện sao chép liên kết tin đăng.
   - Bảng môi giới hiển thị avatar, tên, cấp `Môi giới Lv...`, thời gian cập nhật, nút gọi điện và nhắn tin giống bố cục web.

4. **Bản đồ**
   - Mobile không tự geocode lại địa chỉ.
   - Dùng trực tiếp `mapRenderMode`, tọa độ, bounds, polygon, embed URL và action URL do `PublicMapResolver` của web trả về.
   - Đồng bộ các chế độ point / rect / polygon / iframe; vùng ranh giới có viền đỏ nét đứt như web.

## Thứ tự triển khai

1. Deploy project web/backend trước vì mobile cần `MobileChatController` và dữ liệu owner/map mới.
2. Sau đó chạy lại Flutter và build mobile/web.
3. Nếu chức năng ghim/đánh dấu chat báo chưa sẵn sàng, chạy script:
   `Homenow/Database/Scripts/ChatInboxActions_PostgreSQL.sql`.

## Kiểm tra đăng ký

HTTP 409 không phải lỗi CORS. Đây là phản hồi hợp lệ khi email hoặc số điện thoại đã thuộc một tài khoản đang hoạt động. Bản sửa mới sẽ hiển thị đúng thông báo này. Hãy dùng email/số điện thoại mới khi kiểm tra luồng tạo tài khoản mới.

## Lưu ý kiểm tra build

Môi trường sửa file không có Flutter SDK và MSBuild/.NET Framework nên đã kiểm tra tĩnh cấu trúc Dart/C# nhưng chưa chạy được `flutter analyze` hoặc build MVC. Hãy chạy build trên máy phát triển trước khi đưa lên IIS/App Store.
