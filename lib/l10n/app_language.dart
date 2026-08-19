import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum AppLanguage {
  vietnamese(
    apiCode: 'vi-VN',
    locale: Locale('vi', 'VN'),
    nativeName: 'Tiếng Việt',
    englishName: 'Vietnamese',
    flag: '🇻🇳',
  ),
  english(
    apiCode: 'en-US',
    locale: Locale('en', 'US'),
    nativeName: 'English',
    englishName: 'English',
    flag: '🇺🇸',
  ),
  chinese(
    apiCode: 'zh-CN',
    locale: Locale('zh', 'CN'),
    nativeName: '中文',
    englishName: 'Chinese',
    flag: '🇨🇳',
  );

  const AppLanguage({
    required this.apiCode,
    required this.locale,
    required this.nativeName,
    required this.englishName,
    required this.flag,
  });

  final String apiCode;
  final Locale locale;
  final String nativeName;
  final String englishName;
  final String flag;

  /// Country flag emoji is kept on Android/iOS. Flutter Web can emit a
  /// missing-Noto-font warning for regional-indicator emoji, so use a short
  /// text mark in web builds instead.
  String get displayMark {
    if (!kIsWeb) return flag;
    switch (this) {
      case AppLanguage.vietnamese:
        return 'VI';
      case AppLanguage.english:
        return 'EN';
      case AppLanguage.chinese:
        return 'ZH';
    }
  }

  static AppLanguage? tryParse(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return null;
    if (normalized.startsWith('en')) return AppLanguage.english;
    if (normalized.startsWith('zh')) return AppLanguage.chinese;
    if (normalized.startsWith('vi')) return AppLanguage.vietnamese;
    return null;
  }
}
