import '../config/app_config.dart';

/// Chuẩn hóa mọi đường dẫn ảnh được lưu bởi project ASP.NET MVC NhaWOW.
///
/// Nguồn chuẩn hiện tại của website là thư mục Homenow/Assets, được phục vụ
/// bằng URL /Assets/... . Resolver vẫn hỗ trợ các URL cũ /media, /img,
/// /Content/VR và cả đường dẫn vật lý Windows để dữ liệu PostgreSQL cũ không
/// làm hỏng giao diện mobile.
class MediaUrlResolver {
  MediaUrlResolver._();

  static String resolve(String? rawValue) {
    var value = (rawValue ?? '').trim();
    if (value.isEmpty) return '';

    value = value.replaceAll('\\', '/');
    if (value.startsWith('data:') || value.startsWith('blob:')) return value;

    final isWindowsPhysicalPath = RegExp(r'^[a-zA-Z]:/').hasMatch(value);
    final absolute = isWindowsPhysicalPath ? null : Uri.tryParse(value);
    if (absolute != null && absolute.hasScheme) {
      if (absolute.scheme == 'http' || absolute.scheme == 'https') {
        final rewrittenPath = _rewritePath(absolute.path);
        if (rewrittenPath == absolute.path) return value;
        return absolute.replace(path: rewrittenPath).toString();
      }
      return value;
    }

    var suffix = '';
    final fragmentIndex = value.indexOf('#');
    if (fragmentIndex >= 0) {
      suffix = value.substring(fragmentIndex) + suffix;
      value = value.substring(0, fragmentIndex);
    }
    final queryIndex = value.indexOf('?');
    if (queryIndex >= 0) {
      suffix = value.substring(queryIndex) + suffix;
      value = value.substring(0, queryIndex);
    }

    if (value.startsWith('~/')) value = value.substring(1);
    value = _physicalPathToWebPath(value);
    value = _rewritePath(value);
    if (!value.startsWith('/')) value = '/${value.replaceFirst(RegExp(r'^/+'), '')}';

    final encodedRelative = Uri.encodeFull('$value$suffix');
    return Uri.parse(AppConfig.webBaseUrl).resolve(encodedRelative).toString();
  }

  static List<String> resolveAll(Iterable<String> values) {
    final result = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final resolved = resolve(value);
      if (resolved.isNotEmpty && seen.add(resolved)) result.add(resolved);
    }
    return result;
  }

  static String _physicalPathToWebPath(String value) {
    final normalized = value.replaceAll('\\', '/');
    final lower = normalized.toLowerCase();

    const markers = <String>[
      '/homenow/assets/',
      '/assets/',
    ];
    for (final marker in markers) {
      final index = lower.indexOf(marker);
      if (index >= 0) {
        return '/Assets/${normalized.substring(index + marker.length)}';
      }
    }

    final imgIndex = lower.indexOf('/img/');
    if (imgIndex >= 0) {
      return _rewriteImgSuffix(normalized.substring(imgIndex + '/img/'.length));
    }

    return normalized;
  }

  static String _rewritePath(String input) {
    var path = input.trim().replaceAll('\\', '/');
    if (path.isEmpty) return '';
    if (!path.startsWith('/')) path = '/$path';

    final lower = path.toLowerCase();
    if (lower.startsWith('/media/properties/')) {
      return '/Assets/properties/${path.substring('/media/properties/'.length)}';
    }
    if (lower.startsWith('/media/vr/')) {
      return '/Assets/Vr/${path.substring('/media/vr/'.length)}';
    }
    if (lower.startsWith('/media/vrtiles/')) {
      return '/Assets/VrTiles/${path.substring('/media/vrtiles/'.length)}';
    }
    if (lower.startsWith('/media/useravatars/')) {
      return '/Assets/UserAvatars/${path.substring('/media/useravatars/'.length)}';
    }
    if (lower.startsWith('/media/chatimages/')) {
      return '/Assets/ChatImages/${path.substring('/media/chatimages/'.length)}';
    }
    if (lower.startsWith('/media/covers/')) {
      return '/Assets/covers/${path.substring('/media/covers/'.length)}';
    }
    if (lower.startsWith('/media/')) {
      return '/Assets/${path.substring('/media/'.length)}';
    }
    if (lower.startsWith('/img/')) {
      return _rewriteImgSuffix(path.substring('/img/'.length));
    }
    if (lower.startsWith('/content/vr/')) {
      return '/Assets/Vr/${path.substring('/Content/VR/'.length)}';
    }
    if (lower.startsWith('/properties/')) {
      return '/Assets/properties/${path.substring('/properties/'.length)}';
    }
    if (lower.startsWith('/vr/')) {
      return '/Assets/Vr/${path.substring('/vr/'.length)}';
    }

    return path;
  }

  static String _rewriteImgSuffix(String suffix) {
    final clean = suffix.replaceFirst(RegExp(r'^/+'), '');
    final lower = clean.toLowerCase();
    if (lower.startsWith('assets/')) {
      return '/Assets/${clean.substring('assets/'.length)}';
    }
    if (lower.startsWith('properties/')) return '/Assets/$clean';
    if (lower.startsWith('vr/')) {
      return '/Assets/Vr/${clean.substring('vr/'.length)}';
    }
    if (lower.startsWith('vrtiles/')) {
      return '/Assets/VrTiles/${clean.substring('vrtiles/'.length)}';
    }
    if (lower.startsWith('useravatars/')) return '/Assets/$clean';
    if (lower.startsWith('chatimages/')) return '/Assets/$clean';
    if (lower.startsWith('cities/')) return '/Assets/$clean';
    if (lower.startsWith('amenities/')) return '/Assets/$clean';
    if (lower.startsWith('guide/')) return '/Assets/$clean';
    return '/Assets/$clean';
  }
}
