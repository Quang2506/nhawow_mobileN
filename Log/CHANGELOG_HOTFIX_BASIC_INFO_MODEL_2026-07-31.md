# Hotfix basicInfoItems — 2026-07-31

- Bổ sung `BasicInfoItemModel` và trường `PropertyModel.basicInfoItems`.
- Đọc `basicInfoItems` từ JSON API.
- Giữ trường này trong `PropertyModel.copyWith`.
- Xóa hàm `_hasText` không còn sử dụng để bỏ cảnh báo analyzer.

Thay hai file:
- `lib/models/models.dart`
- `lib/features/property_detail_page.dart`
