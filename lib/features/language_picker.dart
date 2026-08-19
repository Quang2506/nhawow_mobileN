import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_theme.dart';
import '../l10n/app_language.dart';
import '../l10n/app_localizations.dart';

Future<void> showLanguagePicker(BuildContext context) async {
  final store = AppScope.of(context);
  final selected = await showModalBottomSheet<AppLanguage>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _LanguagePickerSheet(
      currentLanguage: store.language,
    ),
  );

  if (selected == null || selected == store.language) return;
  await store.setLanguage(selected);
  if (!context.mounted) return;

  final name = AppLocalizations.of(context).languageName(selected);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.tr('Đã chuyển sang {language}', {'language': name})),
    ),
  );
}

class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet({required this.currentLanguage});

  final AppLanguage currentLanguage;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD8E1E9),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.tr('Chọn ngôn ngữ sử dụng'),
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('Bạn có thể thay đổi lại trong mục Tài khoản.'),
            style: const TextStyle(color: Color(0xFF6C7B8A)),
          ),
          const SizedBox(height: 18),
          for (final language in AppLanguage.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: language == currentLanguage
                    ? const Color(0xFFEAF7FF)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: language == currentLanguage
                        ? AppTheme.primaryDark
                        : const Color(0xFFDDE7F0),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  onTap: () => Navigator.of(context).pop(language),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Text(
                    language.displayMark,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  title: Text(
                    language.nativeName,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(localizations.languageName(language)),
                  trailing: language == currentLanguage
                      ? const Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryDark,
                        )
                      : const Icon(Icons.chevron_right),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
