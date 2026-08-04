# Fix Partner lookup data - 2026-08-01

Đã sửa hai lỗi:

1. Combobox Tỉnh/Thành phố chỉ có mục mặc định.
2. Bước chọn loại bất động sản báo không có dữ liệu.

Nguyên nhân chính: endpoint Partner từng trả các item dưới dạng `Id`, `Code`, `Name`, `Category`, `ListingMode` (PascalCase), trong khi Flutter chỉ đọc `id`, `code`, `name`, `category`, `listingMode` (camelCase).

Bản sửa:

- Flutter đọc được cả camelCase và PascalCase.
- Khi API Partner thiếu danh mục, app lấy dự phòng từ `/mobile-api/lookups`.
- Luôn bổ sung các loại nhà, đất và mặt bằng chuẩn giống trang web.
- Việc lọc nhóm Mặt bằng không còn phụ thuộc hoàn toàn vào `category`/`listingMode` do server trả về.
