class ApiMultipartFile {
  const ApiMultipartFile({
    required this.fieldName,
    required this.fileName,
    required this.bytes,
    this.contentType = 'application/octet-stream',
  });

  final String fieldName;
  final String fileName;
  final List<int> bytes;
  final String contentType;
}

abstract class ApiTransport {
  Future<String> get(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
  });

  Future<String> post(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
    String body = '',
  });

  Future<String> postMultipart(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
    Map<String, String> fields = const <String, String>{},
    List<ApiMultipartFile> files = const <ApiMultipartFile>[],
  });
}

class ApiTransportException implements Exception {
  const ApiTransportException(
    this.message, {
    this.statusCode,
    this.code,
    this.data = const <String, dynamic>{},
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic> data;

  bool get needLogin => code == 'AUTH_REQUIRED' || data['needLogin'] == true;
  bool get needVerify => code == 'EMAIL_NOT_VERIFIED' || data['needVerify'] == true;

  @override
  String toString() => message;
}
