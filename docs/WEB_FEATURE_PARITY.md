# NhaWOW – đối chiếu chức năng Web và Mobile

Admin được loại khỏi phạm vi ứng dụng Mobile theo yêu cầu.

## 1. Chức năng công khai

| Chức năng Web | Controller Web | Trạng thái Mobile |
|---|---|---|
| Trang chủ, nhóm Nhà / Đất & Mặt bằng, Mua / Thuê | `HomeController` | Đã có UI và đọc dữ liệu API |
| Danh sách, bộ lọc, sắp xếp, phân trang | `PropertyController`, `PropertyLookupController` | Đã có UI; API list/lookups đã kết nối, cần bổ sung phân trang server đầy đủ |
| Chi tiết bất động sản, gallery, tiện ích, chủ tin | `PropertyController.Detail` | Đã đọc API thật; ảnh và icon tiện ích đã đồng bộ |
| Hồ sơ môi giới/chủ nhà | `AgentController` | Có UI; dữ liệu hiện lấy từ property detail, chưa có API hồ sơ riêng |
| VR 360° | `PropertyVrController`, `VrAnalyticsController` | Có khung UI; chưa lấy scene/hotspot thật và chưa gửi analytics |
| Ngôn ngữ Việt/Anh/Trung | `LanguageController`, resources | UI mới chủ yếu tiếng Việt; chưa triển khai i18n đầy đủ |
| Hướng dẫn đăng tin | `PageController.PostingGuide` | Đã thêm trang Mobile dùng đúng bộ ảnh Guide |
| Điều khoản, quyền riêng tư | `PageController` | Menu đã có; chưa tạo nội dung/API riêng |

## 2. Tài khoản và xác thực

Web có các luồng:

- Captcha đăng nhập.
- Đăng nhập Ajax.
- Đăng ký người dùng/môi giới và upload avatar.
- Xác thực email OTP, gửi lại OTP.
- Quên mật khẩu bằng OTP.
- Xem/sửa hồ sơ, đổi mật khẩu, đăng xuất.
- Kiểm tra quyền đăng tin.

Controller: `AccountController`.

Trạng thái Mobile: hiện mới có giao diện và trạng thái mô phỏng. Cần API token/JWT hoặc cookie API an toàn trước khi kết nối thật.

## 3. Yêu thích

Web có:

- Bật/tắt yêu thích.
- Danh sách yêu thích.
- Badge và popup tóm tắt.

Controller: `FavoriteController`, `PropertyFavoriteController`.

Trạng thái Mobile: UI và toggle cục bộ đã có; chưa ghi PostgreSQL.

## 4. Chat

Web có:

- Bắt đầu chat với môi giới.
- Danh sách cuộc hội thoại.
- Lịch sử tin nhắn.
- Ghim, đánh dấu, xóa nhiều hội thoại.
- Gửi ảnh.
- Thu hồi tin nhắn.
- Thả tim tin nhắn nhận được.
- Đếm tin chưa đọc.
- SignalR realtime.

Controller: `ChatController`, `ChatHub`.

Trạng thái Mobile: UI hộp thư và hội thoại đã có nhưng đang dùng dữ liệu mô phỏng; chưa có API/SignalR thật.

## 5. Thông báo

Web có popup, tóm tắt, mở thông báo và đánh dấu tất cả đã đọc qua `NotificationController`.

Trạng thái Mobile: UI đã có, dữ liệu mô phỏng.

## 6. Quản lý tin của môi giới

Web có:

- Danh sách và lọc tin.
- Tạo/sửa tin.
- Upload ảnh bìa/gallery.
- Xóa ảnh gallery.
- Đóng/mở lại/xóa tin.
- Chọn tỉnh, phường, loại bất động sản, tiện ích.

Controller: `PartnerController`.

Trạng thái Mobile: UI danh sách và form đã có, thao tác chỉ cập nhật bộ nhớ. Chưa upload ảnh và chưa ghi PostgreSQL.

## 7. Chủ nhà yêu cầu hỗ trợ

Web có form gửi lead qua `LandlordController`.

Trạng thái Mobile: đã có form và ảnh giới thiệu đúng từ Web, chưa gửi API thật.

## 8. Hội viên và tính năng tin

Web có mua gói, checkout và mua tính năng cho tin qua `MembershipController`.

Trạng thái Mobile: UI mô phỏng, chưa thanh toán thật.

## 9. Ví và nạp tiền

Web có:

- Số dư.
- Tạo giao dịch nạp tiền.
- QR tải xuống.
- Theo dõi trạng thái.
- PayOS, SePay, Casso webhook/IPN.
- Hủy giao dịch và xác nhận dev.

Controller: `WalletController`.

Trạng thái Mobile: UI ví và lịch sử mô phỏng; chưa gọi API thật.

## Thứ tự triển khai API tiếp theo

1. Xác thực và lưu token an toàn.
2. Yêu thích thật.
3. Chat + SignalR.
4. Thông báo.
5. Partner CRUD + upload ảnh.
6. Landlord request.
7. Agent profile.
8. VR scene/hotspot/analytics.
9. Membership và Wallet.
10. i18n và các trang pháp lý.

Không nên kết nối Flutter trực tiếp PostgreSQL. Toàn bộ nghiệp vụ và quyền truy cập phải đi qua ASP.NET API để dùng lại validation, quyền người dùng và transaction của Web.
