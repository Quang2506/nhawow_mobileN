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

  static AppLanguage? tryParse(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return null;
    if (normalized.startsWith('en')) return AppLanguage.english;
    if (normalized.startsWith('zh')) return AppLanguage.chinese;
    if (normalized.startsWith('vi')) return AppLanguage.vietnamese;
    return null;
  }
}
