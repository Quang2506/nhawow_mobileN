# Đồng bộ hồ sơ và cấp bậc môi giới – 04-08-2026

## Mobile app

1. Nhãn cấp bậc môi giới ở màn chi tiết đã đổi sang dạng pill bo tròn giống mobile web:
   - nền gradient theo Lv1–Lv6;
   - icon cấp bậc, hiệu ứng ánh sáng quét và nhịp thở;
   - bỏ khung viền chữ nhật cũ;
   - màn chi tiết ẩn số Lv, màn hồ sơ hiển thị số Lv.

2. Màn hồ sơ người đăng được đồng bộ bố cục mobile web:
   - avatar và viền hội viên;
   - hồ sơ công khai, khu vực, mô tả, thẻ dịch vụ;
   - nút nhắn tin, gọi điện, xem toàn bộ tin;
   - thống kê số tin, lượt xem, cấp hồ sơ, khu vực chính;
   - sao chép/chia sẻ hồ sơ;
   - dải thông tin tin cậy;
   - bộ lọc Nhà / Đất & Mặt bằng, Mua / Thuê, từ khóa và sắp xếp.

3. Hồ sơ của chính môi giới có thêm lộ trình cấp bậc NhaWOW:
   - mặc định thu gọn;
   - mở/đóng có hiệu ứng;
   - 6 cấp với mốc số tin và quyền lợi tương ứng;
   - đánh dấu cấp hiện tại và tiến độ tới cấp tiếp theo.

4. Logic liên hệ đã dùng chung luồng đăng nhập của app:
   - khách phải đăng nhập trước khi xem số/gọi điện hoặc nhắn tin;
   - chat trực tiếp với môi giới bằng API chat hiện có;
   - hồ sơ và danh sách tin tải trực tiếp từ Mobile API.

5. Bổ sung bản dịch tiếng Anh và tiếng Trung cho các nội dung mới.

## Web / Mobile API

- Thêm endpoint `GET /mobile-api/agents/{id}`.
- Endpoint trả về thông tin môi giới, cấp bậc, hội viên, tổng tin thật, tổng lượt xem, khu vực chính, quyền sở hữu hồ sơ và danh sách tin đang hiển thị.
- Mobile cần deploy backend mới trước, sau đó mới chạy/build app.

## Kiểm tra build

Môi trường sửa file không có Flutter SDK và MSBuild/.NET Framework nên đã kiểm tra tĩnh cấu trúc Dart/C# nhưng chưa chạy được `flutter analyze` hoặc build MVC. Hãy build trên máy phát triển trước khi đẩy IIS hoặc phát hành app.
