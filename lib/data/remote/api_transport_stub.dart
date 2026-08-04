import 'api_transport.dart';

ApiTransport createApiTransport() => _UnsupportedApiTransport();

class _UnsupportedApiTransport implements ApiTransport {
  @override
  Future<String> get(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
  }) {
    throw const ApiTransportException(
      'Nền tảng hiện tại không hỗ trợ kết nối HTTP.',
    );
  }

  @override
  Future<String> post(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
    String body = '',
  }) {
    throw const ApiTransportException(
      'Nền tảng hiện tại không hỗ trợ kết nối HTTP.',
    );
  }

  @override
  Future<String> postMultipart(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
    Map<String, String> fields = const <String, String>{},
    List<ApiMultipartFile> files = const <ApiMultipartFile>[],
  }) {
    throw const ApiTransportException(
      'Nền tảng hiện tại không hỗ trợ tải tệp lên.',
    );
  }
}
