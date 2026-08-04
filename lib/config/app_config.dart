class AppConfig {
  AppConfig._();

  /// Khi chạy Flutter Web, truyền đúng port của website ASP.NET:
  /// flutter run -d chrome --dart-define=NHAWOW_API_BASE_URL=https://localhost:44323/mobile-api
  static const String apiBaseUrl = String.fromEnvironment(
    'NHAWOW_API_BASE_URL',
    defaultValue: 'https://localhost:44323/mobile-api',
  );

  /// Gốc website dùng để ghép các đường dẫn ảnh /Assets/... trả về từ PostgreSQL.
  /// Hỗ trợ cả trường hợp website chạy trong virtual directory, ví dụ:
  /// https://server/NhaWOW/mobile-api -> https://server/NhaWOW
  static String get webBaseUrl {
    var normalized = apiBaseUrl.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    final lower = normalized.toLowerCase();
    final apiIndex = lower.lastIndexOf('/mobile-api');
    if (apiIndex >= 0) return normalized.substring(0, apiIndex);

    final uri = Uri.tryParse(normalized);
    if (uri != null && uri.hasScheme && uri.authority.isNotEmpty) {
      return '${uri.scheme}://${uri.authority}';
    }
    return normalized;
  }

  static Uri buildApiUri(
    String path, [
    Map<String, String?> query = const <String, String?>{},
  ]) {
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final suffix = path.startsWith('/') ? path : '/$path';
    final filtered = <String, String>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value != null && value.trim().isNotEmpty) {
        filtered[entry.key] = value.trim();
      }
    }
    return Uri.parse('$base$suffix').replace(
      queryParameters: filtered.isEmpty ? null : filtered,
    );
  }
}
