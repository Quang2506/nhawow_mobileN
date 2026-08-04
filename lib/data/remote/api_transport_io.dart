import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'api_transport.dart';

ApiTransport createApiTransport() => IoApiTransport();

class IoApiTransport implements ApiTransport {
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
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    final boundary = '----NhaWow${DateTime.now().microsecondsSinceEpoch}';
    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      for (final entry in headers.entries) {
        request.headers.set(entry.key, entry.value);
      }
      request.headers.contentType = ContentType(
        'multipart',
        'form-data',
        parameters: <String, String>{'boundary': boundary},
      );

      final body = BytesBuilder(copy: false);
      for (final entry in fields.entries) {
        body.add(utf8.encode('--$boundary\r\n'));
        body.add(
          utf8.encode(
            'Content-Disposition: form-data; name="${_escapeHeader(entry.key)}"\r\n\r\n',
          ),
        );
        body.add(utf8.encode(entry.value));
        body.add(utf8.encode('\r\n'));
      }

      for (final file in files) {
        body.add(utf8.encode('--$boundary\r\n'));
        body.add(
          utf8.encode(
            'Content-Disposition: form-data; name="${_escapeHeader(file.fieldName)}"; filename="${_escapeHeader(file.fileName)}"\r\n',
          ),
        );
        body.add(utf8.encode('Content-Type: ${file.contentType}\r\n\r\n'));
        body.add(file.bytes);
        body.add(utf8.encode('\r\n'));
      }

      body.add(utf8.encode('--$boundary--\r\n'));
      final payload = body.takeBytes();
      request.contentLength = payload.length;
      request.add(payload);
      final response = await request.close().timeout(const Duration(seconds: 45));
      return _readResponse(response);
    } on ApiTransportException {
      rethrow;
    } on SocketException catch (error) {
      throw ApiTransportException('Không thể kết nối máy chủ: ${error.message}');
    } on TimeoutException {
      throw const ApiTransportException('Máy chủ phản hồi quá lâu.');
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    String body = '',
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = method == 'POST'
          ? await client.postUrl(uri)
          : await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      for (final entry in headers.entries) {
        request.headers.set(entry.key, entry.value);
      }
      if (method == 'POST') {
        request.headers.contentType = ContentType.json;
        request.write(body);
      }
      final response = await request.close().timeout(const Duration(seconds: 25));
      return _readResponse(response);
    } on ApiTransportException {
      rethrow;
    } on SocketException catch (error) {
      throw ApiTransportException('Không thể kết nối máy chủ: ${error.message}');
    } on TimeoutException {
      throw const ApiTransportException('Máy chủ phản hồi quá lâu.');
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _readResponse(HttpClientResponse response) async {
    final responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (responseBody.trimLeft().startsWith('{')) return responseBody;
      throw ApiTransportException(
        responseBody.isEmpty ? 'Không thể tải dữ liệu từ máy chủ.' : responseBody,
        statusCode: response.statusCode,
      );
    }
    return responseBody;
  }

  String _escapeHeader(String value) {
    return value.replaceAll('"', '').replaceAll('\r', '').replaceAll('\n', '');
  }
}
