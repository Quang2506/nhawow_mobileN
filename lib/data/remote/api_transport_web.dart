import 'dart:async';
// ignore_for_file: deprecated_member_use
import 'dart:html';
import 'dart:typed_data';

import 'api_transport.dart';

ApiTransport createApiTransport() => WebApiTransport();

class WebApiTransport implements ApiTransport {
  @override
  Future<String> get(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
  }) {
    return _send(uri, method: 'GET', headers: headers);
  }

  @override
  Future<String> post(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
    String body = '',
  }) {
    return _send(uri, method: 'POST', headers: headers, body: body);
  }

  @override
  Future<String> postMultipart(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
    Map<String, String> fields = const <String, String>{},
    List<ApiMultipartFile> files = const <ApiMultipartFile>[],
  }) async {
    final data = FormData();
    for (final entry in fields.entries) {
      data.append(entry.key, entry.value);
    }
    for (final file in files) {
      final blob = Blob(
        <Object>[Uint8List.fromList(file.bytes)],
        file.contentType,
      );
      data.appendBlob(file.fieldName, blob, file.fileName);
    }
    return _send(
      uri,
      method: 'POST',
      headers: headers,
      formData: data,
    );
  }

  Future<String> _send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    String body = '',
    FormData? formData,
  }) async {
    final completer = Completer<HttpRequest>();
    final request = HttpRequest();
    StreamSubscription<ProgressEvent>? loadSubscription;
    StreamSubscription<ProgressEvent>? errorSubscription;
    StreamSubscription<ProgressEvent>? timeoutSubscription;

    try {
      request
        ..open(method, uri.toString())
        ..timeout = 25000;

      final requestHeaders = <String, String>{
        'Accept': 'application/json',
        ...headers,
      };
      if (method == 'POST' && formData == null) {
        requestHeaders['Content-Type'] = 'application/json';
      }
      requestHeaders.forEach(request.setRequestHeader);

      void completeOnce(HttpRequest value) {
        if (!completer.isCompleted) completer.complete(value);
      }

      void completeErrorOnce(Object error) {
        if (!completer.isCompleted) completer.completeError(error);
      }

      loadSubscription = request.onLoad.listen((_) => completeOnce(request));
      errorSubscription = request.onError.listen((_) {
        completeErrorOnce(
          const ApiTransportException(
            'Không thể kết nối API. Hãy kiểm tra địa chỉ API và cấu hình CORS.',
          ),
        );
      });
      timeoutSubscription = request.onTimeout.listen((_) {
        completeErrorOnce(
          const ApiTransportException('Máy chủ phản hồi quá lâu.'),
        );
      });

      request.send(formData ?? (method == 'POST' ? body : null));
      final response = await completer.future;
      final status = response.status ?? 0;
      final responseBody = response.responseText ?? '';

      if (status < 200 || status >= 300) {
        if (responseBody.trimLeft().startsWith('{')) return responseBody;
        throw ApiTransportException(
          responseBody.isEmpty
              ? 'Không thể tải dữ liệu từ máy chủ.'
              : responseBody,
          statusCode: status,
        );
      }

      return responseBody;
    } on ApiTransportException {
      rethrow;
    } on TimeoutException {
      throw const ApiTransportException('Máy chủ phản hồi quá lâu.');
    } catch (_) {
      throw const ApiTransportException(
        'Không thể kết nối API. Hãy kiểm tra địa chỉ API và cấu hình CORS.',
      );
    } finally {
      if (loadSubscription != null) await loadSubscription.cancel();
      if (errorSubscription != null) await errorSubscription.cancel();
      if (timeoutSubscription != null) await timeoutSubscription.cancel();
    }
  }
}
