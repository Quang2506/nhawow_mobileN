# NhaWOW – quy ước ảnh Web và Mobile

## Nguồn ảnh chuẩn

Project web hiện lưu ảnh tại:

```text
D:\Code\NhaWOW\Homenow\Assets
```

Khi website chạy, đường dẫn công khai tương ứng là:

```text
https://<web-host>:<port>/Assets/...
```

Ví dụ:

```text
D:\Code\NhaWOW\Homenow\Assets\properties\14\gallery\abc.png
https://localhost:44323/Assets/properties/14/gallery/abc.png
```

Flutter không đọc trực tiếp đường dẫn ổ D. Ứng dụng lấy URL từ API và `MediaUrlResolver` chuyển các dạng dữ liệu cũ về URL `/Assets/...`.

## Ảnh tĩnh đã đóng gói vào ứng dụng

Các nhóm dưới đây ít thay đổi và đã được chép vào `assets/web_assets`:

- `Amenities`: 20 biểu tượng tiện ích.
- `Cities`: logo, ảnh banner, hình giới thiệu chủ nhà, VR và QR Zalo.
- `Guide`: 8 hình hướng dẫn đăng ký, xác thực, đăng tin, quản lý tin và VR.

Các thư mục được khai báo trong `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/web_assets/Amenities/
    - assets/web_assets/Cities/
    - assets/web_assets/Guide/
```

## Ảnh động phải tiếp tục tải từ Web/API

Không đóng gói vào APK vì các ảnh này thay đổi theo dữ liệu PostgreSQL:

| Nhóm | Thư mục Web | URL |
|---|---|---|
| Ảnh bìa và gallery bất động sản | `Assets/properties` | `/Assets/properties/...` |
| Ảnh bìa cũ | `Assets/covers` | `/Assets/covers/...` |
| Avatar người dùng | `Assets/UserAvatars` | `/Assets/UserAvatars/...` |
| Ảnh chat | `Assets/ChatImages` | `/Assets/ChatImages/...` |
| Panorama VR | `Assets/Vr` | `/Assets/Vr/...` |
| Tile VR | `Assets/VrTiles` | `/Assets/VrTiles/...` |
| Preview hoặc ảnh nhà cũ | `Assets/Perview`, `Assets/Houses` | `/Assets/Perview/...`, `/Assets/Houses/...` |

## Các đường dẫn cũ được Mobile hỗ trợ

`MediaUrlResolver` chuẩn hóa các dạng sau:

```text
~/Assets/properties/...
/Assets/properties/...
Assets/properties/...
/media/properties/...
/img/properties/...
/Content/VR/...
D:\Code\NhaWOW\Homenow\Assets\...
D:\img\...
```

Đích cuối cùng là URL cùng host với Web:

```text
https://localhost:44323/Assets/...
```

## Phân loại 49 file trong Assets.zip

- 20 file `Amenities` – đóng gói vào app.
- 18 file `Cities` – đóng gói vào app.
- 8 file `Guide` – đóng gói vào app.
- 1 avatar – dữ liệu động, không đóng gói.
- 1 panorama VR – dữ liệu động, không đóng gói.
- 1 ảnh gallery bất động sản – dữ liệu động, không đóng gói.

Cách phân loại này tránh làm APK tăng dung lượng và tránh phải phát hành lại app mỗi khi môi giới thay ảnh.
