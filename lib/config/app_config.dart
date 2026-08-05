class AppConfig {
  AppConfig._();

  /// Địa chỉ API dùng cho ứng dụng NhaWOW.
  ///
  /// Mặc định app sẽ gọi API trên server production:
  /// https://nhawow.com/mobile-api
  ///
  /// Khi cần chạy với server khác, có thể ghi đè bằng --dart-define:
  /// flutter run --dart-define=NHAWOW_API_BASE_URL=https://domain/mobile-api
  static const String apiBaseUrl = String.fromEnvironment(
    'NHAWOW_API_BASE_URL',
    defaultValue: 'https://nhawow.com/mobile-api',
  );

  /// Địa chỉ gốc của website, dùng để ghép các đường dẫn tương đối như:
  /// /Assets/...
  /// /Content/...
  /// /media/...
  ///
  /// Ví dụ:
  /// https://nhawow.com/mobile-api -> https://nhawow.com
  /// https://server/NhaWOW/mobile-api -> https://server/NhaWOW
  static String get webBaseUrl {
    var normalized = apiBaseUrl.trim();

    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    final lower = normalized.toLowerCase();
    final apiIndex = lower.lastIndexOf('/mobile-api');

    if (apiIndex >= 0) {
      return normalized.substring(0, apiIndex);
    }

    final uri = Uri.tryParse(normalized);

    if (uri != null && uri.hasScheme && uri.authority.isNotEmpty) {
      return '${uri.scheme}://${uri.authority}';
    }

    return normalized;
  }

  /// Tạo URL đầy đủ để gọi API.
  ///
  /// Ví dụ:
  /// buildApiUri('/properties')
  /// -> https://nhawow.com/mobile-api/properties
  ///
  /// buildApiUri('/properties', {'page': '1'})
  /// -> https://nhawow.com/mobile-api/properties?page=1
  static Uri buildApiUri(
    String path, [
    Map<String, String?> query = const <String, String?>{},
  ]) {
    final normalizedBase = apiBaseUrl.trim();

    final base = normalizedBase.endsWith('/')
        ? normalizedBase.substring(0, normalizedBase.length - 1)
        : normalizedBase;

    final normalizedPath = path.trim();
    final suffix = normalizedPath.startsWith('/')
        ? normalizedPath
        : '/$normalizedPath';

    final filteredQuery = <String, String>{};

    for (final entry in query.entries) {
      final value = entry.value?.trim();

      if (value != null && value.isNotEmpty) {
        filteredQuery[entry.key] = value;
      }
    }

    return Uri.parse('$base$suffix').replace(
      queryParameters: filteredQuery.isEmpty ? null : filteredQuery,
    );
  }
}
