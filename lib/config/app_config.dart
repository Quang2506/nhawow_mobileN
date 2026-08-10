
////////////////////////// host \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

import 'package:flutter/foundation.dart';
 class AppConfig {
  AppConfig._();

  /// API chính thức dành cho bản phát hành App Store.
 static const String _productionApiBaseUrl =
    'https://nhawow.com/mobile-api';

  /// Chỉ dùng để đổi server khi phát triển hoặc kiểm thử.
 ///
 /// Ví dụ:
  /// flutter run \
  ///   --dart-define=NHAWOW_API_BASE_URL=http://192.168.1.10:59864/mobile-api
 static const String _developmentApiBaseUrl = String.fromEnvironment(
    'NHAWOW_API_BASE_URL',
    defaultValue: _productionApiBaseUrl,
  );

 /// Trong bản Release/App Store, luôn bắt buộc sử dụng server production.
  ///
  /// Vì vậy, kể cả khi cấu hình build bị thiếu hoặc có dart-define cũ,
   /// bản tải từ App Store vẫn gọi:
   /// https://nhawow.com/mobile-api
   static const String apiBaseUrl = kReleaseMode
      ? _productionApiBaseUrl
      : _developmentApiBaseUrl;

  /// Địa chỉ website gốc, dùng cho:
   /// /Assets/...
  /// /Content/...
  /// /media/...
   static String get webBaseUrl {
    final normalizedApiUrl = _removeTrailingSlashes(apiBaseUrl.trim());

     final uri = Uri.tryParse(normalizedApiUrl);

     if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return normalizedApiUrl;
    }

    final pathSegments = List<String>.from(uri.pathSegments);

    if (pathSegments.isNotEmpty &&
        pathSegments.last.toLowerCase() == 'mobile-api') {
       pathSegments.removeLast();
    }

    return uri
         .replace(
         pathSegments: pathSegments,
         queryParameters: null,
          fragment: null,
        )
       .toString()
         .replaceAll(RegExp(r'/$'), '');
  }

   /// Tạo URL hoàn chỉnh để gọi API.
   ///
   /// Ví dụ:
   /// buildApiUri('/properties')
  /// https://nhawow.com/mobile-api/properties
  ///
  /// buildApiUri('/properties', {'page': '1'})
  /// https://nhawow.com/mobile-api/properties?page=1
   static Uri buildApiUri(
     String path, [
    Map<String, String?> query = const <String, String?>{},
   ]) {
   final normalizedBase = _removeTrailingSlashes(apiBaseUrl.trim());

    final normalizedPath = path.trim();
     final suffix = normalizedPath.isEmpty
        ? ''
        : normalizedPath.startsWith('/')
           ? normalizedPath
            : '/$normalizedPath';

    final filteredQuery = <String, String>{};

     for (final entry in query.entries) {
      final key = entry.key.trim();
      final value = entry.value?.trim();

      if (key.isNotEmpty && value != null && value.isNotEmpty) {
        filteredQuery[key] = value;
       }
    }

     final uri = Uri.parse('$normalizedBase$suffix');

     if (filteredQuery.isEmpty) {
       return uri;
     }

     return uri.replace(queryParameters: filteredQuery);
   }

   /// Ghép đường dẫn ảnh hoặc tài nguyên từ website.
   ///
   /// Ví dụ:
   /// buildWebUri('/Assets/properties/1/image.jpg')
  static Uri buildWebUri(String path) {
    final normalizedBase = _removeTrailingSlashes(webBaseUrl.trim());
   final normalizedPath = path.trim();

   if (normalizedPath.isEmpty) {
      return Uri.parse(normalizedBase);
    }

    // Nếu dữ liệu API đã trả về URL đầy đủ thì sử dụng trực tiếp.
   final absoluteUri = Uri.tryParse(normalizedPath);

    if (absoluteUri != null &&
         absoluteUri.hasScheme &&
         absoluteUri.host.isNotEmpty) {
       return absoluteUri;
   }

     final suffix = normalizedPath.startsWith('/')
        ? normalizedPath
       : '/$normalizedPath';

   return Uri.parse('$normalizedBase$suffix');
  }

  static String _removeTrailingSlashes(String value) {
     return value.replaceAll(RegExp(r'/+$'), '');
 }
 }




////////////////////////// Local \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

// class AppConfig {
//   AppConfig._();

//   /// Khi chạy Flutter Web, truyền đúng port của website ASP.NET:
//   /// flutter run -d chrome --dart-define=NHAWOW_API_BASE_URL=https://localhost:44323/mobile-api
//   static const String apiBaseUrl = String.fromEnvironment(
//     'NHAWOW_API_BASE_URL',
//     defaultValue: 'https://localhost:44323/mobile-api',
//   );

//   /// Gốc website dùng để ghép các đường dẫn ảnh /Assets/... trả về từ PostgreSQL.
//   /// Hỗ trợ cả trường hợp website chạy trong virtual directory, ví dụ:
//   /// https://server/NhaWOW/mobile-api -> https://server/NhaWOW
//   static String get webBaseUrl {
//     var normalized = apiBaseUrl.trim();
//     while (normalized.endsWith('/')) {
//       normalized = normalized.substring(0, normalized.length - 1);
//     }
//     final lower = normalized.toLowerCase();
//     final apiIndex = lower.lastIndexOf('/mobile-api');
//     if (apiIndex >= 0) return normalized.substring(0, apiIndex);

//     final uri = Uri.tryParse(normalized);
//     if (uri != null && uri.hasScheme && uri.authority.isNotEmpty) {
//       return '${uri.scheme}://${uri.authority}';
//     }
//     return normalized;
//   }

//   static Uri buildApiUri(
//     String path, [
//     Map<String, String?> query = const <String, String?>{},
//   ]) {
//     final base = apiBaseUrl.endsWith('/')
//         ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
//         : apiBaseUrl;
//     final suffix = path.startsWith('/') ? path : '/$path';
//     final filtered = <String, String>{};
//     for (final entry in query.entries) {
//       final value = entry.value;
//       if (value != null && value.trim().isNotEmpty) {
//         filtered[entry.key] = value.trim();
//       }
//     }
//     return Uri.parse('$base$suffix').replace(
//       queryParameters: filtered.isEmpty ? null : filtered,
//     );
//   }
// }
