# Account deletion - 2026-09-23

- Thay chức năng "Vô hiệu hóa tài khoản" bằng "Xóa tài khoản".
- Khi xác nhận, server đặt lịch xóa vĩnh viễn sau 1 giờ.
- Trong 1 giờ có thể hủy yêu cầu.
- Hết thời gian chờ, app gọi API finalize và xóa phiên đăng nhập.
- Backend worker vẫn xóa tài khoản khi app đã đóng.
- Khi xóa: tài khoản, tin đăng, ảnh, VR và dữ liệu liên quan bị xóa vĩnh viễn; không thể khôi phục bằng Admin.

API mới:
- POST /mobile-api/auth/delete-account
- POST /mobile-api/auth/cancel-account-deletion
- POST /mobile-api/auth/finalize-account-deletion
