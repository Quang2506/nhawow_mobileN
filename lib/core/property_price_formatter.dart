import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';

/// Hiển thị giá BĐS công khai theo cùng quy ước với website.
///
/// Website dùng đơn vị 万 / 亿 cho tiếng Trung thay vì dịch trực tiếp
/// "triệu / tỷ" sang 百万 / 十亿. Mobile ưu tiên giá số để giữ cách hiển thị
/// đồng nhất ngay cả khi API cũ vẫn trả priceLabel theo định dạng trước đây.
String displayPropertyPrice(BuildContext context, PropertyModel property) {
  final languageCode = Localizations.localeOf(context).languageCode.toLowerCase();

  if (!languageCode.startsWith('zh') || property.price <= 0) {
    return context.tr(property.priceLabel);
  }

  final base = formatChineseVndCompact(property.price);
  return property.kind.isRent ? '$base/月' : base;
}

/// Định dạng tiền VND theo đúng quy tắc tiếng Trung của website:
/// 10.000 VND = 1万, 100.000.000 VND = 1亿.
String formatChineseVndCompact(num amount) {
  final value = amount.toDouble();
  if (!value.isFinite) return '';

  if (value < 0) {
    return '-${formatChineseVndCompact(-value)}';
  }

  if (value < 10000) {
    return value.round().toString();
  }

  if (value < 100000000) {
    return '${_compactWithoutRounding(value / 10000)}万';
  }

  return '${_compactWithoutRounding(value / 100000000)}亿';
}

String _compactWithoutRounding(double value) {
  final truncated = (value * 1000).truncateToDouble() / 1000;
  return truncated
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
