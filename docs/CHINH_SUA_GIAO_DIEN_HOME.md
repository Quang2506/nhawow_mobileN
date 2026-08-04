# Cách chỉnh giao diện trang chủ NhaWOW bằng Flutter Inspector

## 1. Mở đúng project

Trong VS Code, chọn **File > Open Folder** và mở thư mục có file `pubspec.yaml`.

File giao diện đầu trang chủ nằm tại:

```text
lib/features/home_page.dart
```

## 2. Chạy ứng dụng ở chế độ Debug

Nhấn `F5`, hoặc mở Terminal và chạy:

```powershell
flutter run
```

Không chạy bản Release khi đang chỉnh giao diện, vì Hot Reload và Inspector cần chế độ Debug.

## 3. Mở Flutter Inspector giống Inspect của web

1. Khi ứng dụng đang chạy, nhấn `F1` trong VS Code.
2. Gõ `Flutter: Open DevTools`.
3. Chọn **Open Inspector**.
4. Bật nút **Select Widget Mode** ở góc trên của Inspector.
5. Bấm trực tiếp vào phần giao diện trên ứng dụng.
6. Inspector sẽ chọn đúng widget và hiển thị kích thước, padding, constraints và cây widget.
7. Bấm vào liên kết source để nhảy đến dòng code tương ứng.

Flutter Inspector dùng để tìm widget và xem bố cục. Flutter không sửa CSS trực tiếp giống trình duyệt; thay đổi bền vững vẫn phải được lưu trong file Dart.

## 4. Dùng Flutter Property Editor

Nếu Flutter SDK từ 3.32 trở lên:

1. Chọn một widget bằng Flutter Inspector.
2. Mở **Flutter Property Editor** trong VS Code.
3. Các thuộc tính đơn giản như số, chuỗi, `true/false` hoặc enum có thể chỉnh bằng ô nhập và danh sách.
4. Nhấn `Enter` hoặc `Tab` để ghi thay đổi vào source code.

Các thuộc tính phức tạp như `EdgeInsets`, `TextStyle`, `Color` thường vẫn cần sửa trong code.

## 5. Bật tự động lưu và Hot Reload

Mở file `.vscode/settings.json` và đặt:

```json
{
  "files.autoSave": "afterDelay",
  "dart.flutterHotReloadOnSave": "all"
}
```

Khi thay đổi số trong code, ứng dụng sẽ tự cập nhật. Bạn cũng có thể nhấn `Ctrl + S` hoặc nút Hot Reload.

## 6. Chỉnh riêng phần đầu trang chủ

Ở gần đầu file `lib/features/home_page.dart`, tìm:

```dart
class _HomeHeaderUiTuning {
```

### Đẩy tìm kiếm và 4 chức năng lên hoặc xuống

```dart
static const double controlsLiftMobile = 56;
```

- Tăng `56` thành `65`, `70`... để đẩy lên cao hơn.
- Giảm `56` thành `45`, `35`... để hạ xuống.
- Không nên tăng quá nhiều vì ô tìm kiếm có thể đè lên phần mô tả.

### Thay đổi kích thước logo

```dart
static const double brandLogoSize = 48;
```

- Tăng số để logo lớn hơn.
- Giảm số để logo nhỏ hơn.

### Thay khoảng cách trái/phải của khung 4 chức năng

Tìm đoạn:

```dart
left: compact ? 28 : 72,
right: compact ? 28 : 72,
```

- Giảm `28` để khung rộng hơn.
- Tăng `28` để khung hẹp hơn.

### Thay chiều cao banner

Tìm:

```dart
final heroHeight = compact ? (verySmall ? 470.0 : 490.0) : 440.0;
```

- `470.0`: máy có màn hình rất nhỏ.
- `490.0`: điện thoại thông thường.
- `440.0`: tablet hoặc màn hình rộng.

### Thay ảnh banner

Chép ảnh mới vào:

```text
assets/web_assets/Cities/
```

Sau đó sửa đường dẫn trong:

```text
lib/core/app_assets.dart
```

Ví dụ:

```dart
static const String homeHeroFull =
    '$_root/Cities/ten_anh_banner_moi.png';
```

Nếu thêm ảnh vào một thư mục mới chưa được khai báo trong `pubspec.yaml`, cần bổ sung đường dẫn assets rồi chạy lại `flutter pub get`.

## 7. Các thuộc tính Flutter tương đương CSS

| Flutter | Gần giống CSS |
|---|---|
| `Padding` | `padding` |
| `margin` của `Container` | `margin` |
| `SizedBox(height: 10)` | khoảng cách dọc |
| `SizedBox(width: 10)` | khoảng cách ngang |
| `Transform.translate` | `transform: translate(...)` |
| `Positioned(top, left, right)` | `position: absolute` |
| `BoxDecoration` | background, border, shadow, radius |
| `BorderRadius.circular(24)` | `border-radius: 24px` |
| `BoxShadow` | `box-shadow` |
| `TextStyle(fontSize...)` | font-size, font-weight, color |
| `Row` | flex theo chiều ngang |
| `Column` | flex theo chiều dọc |
| `Expanded` | `flex: 1` |
| `BoxFit.cover` | `object-fit: cover` |
| `BoxFit.contain` | `object-fit: contain` |

## 8. Khi chỉnh sai giao diện

- Nhấn `Ctrl + Z` trong VS Code để hoàn tác.
- Lỗi đỏ trong Terminal thường có ghi rõ tên file và số dòng.
- Nếu Hot Reload không cập nhật, nhấn **Hot Restart**.
- Nếu thay ảnh hoặc sửa `pubspec.yaml`, nên dừng ứng dụng rồi chạy lại.
