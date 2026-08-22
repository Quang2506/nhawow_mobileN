# NhaWOW Push Notifications - phần còn cần cấu hình

Mobile app đã được bổ sung Firebase Cloud Messaging (FCM) theo cơ chế an toàn:
- Nếu chưa có Firebase config, app vẫn chạy như hiện tại.
- Khi Firebase config hợp lệ và user cho phép notification, app lấy FCM token.
- Token được gửi lên backend theo tài khoản đang đăng nhập.
- Khi logout, app yêu cầu backend xóa token.
- Push có `conversationId` sẽ mở đúng màn Chat.
- Push có `propertyId` sẽ mở đúng Detail.
- Push khác sẽ mở màn Thông báo.

## 1. Firebase Console

Tạo 2 app trong cùng Firebase project:

- Android package: `vn.nhawow.nhawow_mobile`
- iOS bundle id: `vn.nhawow.nhawowMobile`

Với iOS, upload APNs Authentication Key (.p8) lên Firebase Cloud Messaging và đảm bảo Apple Developer/App ID đã bật Push Notifications.

## 2. Tạo file cấu hình local

Copy `firebase_config.example.json` thành `firebase_config.json` rồi thay giá trị thật lấy từ Firebase Console.

Không commit file cấu hình thật nếu team không muốn lưu cấu hình môi trường trong repository.

Chạy debug:

```bash
flutter run --dart-define-from-file=firebase_config.json
```

Build Android:

```bash
flutter build appbundle --release --dart-define-from-file=firebase_config.json
```

Build iOS/App Store:

```bash
flutter build ipa --release --dart-define-from-file=firebase_config.json
```

## 3. Hai API backend bắt buộc

Base URL hiện tại của app là `https://nhawow.com/mobile-api`.

### POST /mobile-api/push/register

Yêu cầu Bearer token đăng nhập.

Body:

```json
{
  "token": "FCM_DEVICE_TOKEN",
  "platform": "android"
}
```

`platform` là `android` hoặc `ios`.

Backend cần lưu ít nhất:
- user_id
- token
- platform
- is_active
- created_at / updated_at

Nên unique theo `token`; nếu token chuyển sang user khác thì cập nhật owner của token.

Response theo envelope hiện tại của app, ví dụ:

```json
{
  "success": true,
  "message": "OK",
  "data": {}
}
```

### POST /mobile-api/push/unregister

Yêu cầu Bearer token đăng nhập.

Body giống register. Backend đặt token inactive hoặc xóa token.

## 4. Khi nào backend phải gửi push

### Tin nhắn chat mới

Sau khi `/chat/send` hoặc `/chat/send-image` ghi message thành công, gửi FCM tới token của người nhận (không gửi cho token của người gửi).

Payload khuyến nghị:

```json
{
  "notification": {
    "title": "Nguyễn Văn A",
    "body": "Bạn có tin nhắn mới"
  },
  "data": {
    "type": "chat",
    "conversationId": "123"
  }
}
```

### Thông báo hệ thống mới

Ngay sau khi backend tạo record notification cho user, gửi FCM:

```json
{
  "notification": {
    "title": "NhaWOW",
    "body": "Tin đăng của bạn đã được duyệt"
  },
  "data": {
    "type": "notification",
    "notificationId": "456",
    "propertyId": "789"
  }
}
```

Để Android/iOS tự hiển thị khi app ở background/terminated, message gửi từ server nên có `notification` payload như trên, không chỉ gửi `data`.

## 5. Lưu ý hệ điều hành

- User phải mở app ít nhất một lần để thiết bị đăng ký FCM.
- Android 13+ và iOS sẽ hỏi quyền notification.
- Nếu user từ chối, app không ép bật notification.
- Android: nếu user Force stop app trong Settings thì push chỉ hoạt động lại sau khi mở app.
- iOS: một số trạng thái người dùng chủ động đóng app có giới hạn riêng của hệ điều hành; cần test trên iPhone thật.
