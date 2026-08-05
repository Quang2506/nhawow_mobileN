# Fix iOS: Connection closed while receiving data

Đã sửa `lib/data/remote/api_transport_io.dart`.

Nguyên nhân: các hàm `_send` và `postMultipart` trả về `_readResponse(response)` nhưng không `await`. Vì vậy khối `finally` có thể chạy `client.close(force: true)` khi response body vẫn đang được tải, gây lỗi trên mạng thật/iOS:

`HttpException: Connection closed while receiving data`

Sửa thành:

```dart
return await _readResponse(response);
```

Đồng thời bổ sung bắt `HttpException` để hiển thị lỗi rõ hơn.
