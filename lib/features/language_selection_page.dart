import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_theme.dart';
import '../l10n/app_language.dart';
import '../l10n/app_localizations.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: const BorderSide(color: Color(0xFFDCE9F4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
                  child: Column(
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE6F6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.language_rounded,
                          color: AppTheme.primaryDark,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Chọn ngôn ngữ · Choose language · 选择语言',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.navy,
                          fontSize: 22,
                          height: 1.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bạn có thể thay đổi lại trong mục Tài khoản.\n'
                        'You can change it later in Account.\n'
                        '之后可在“账户”中更改。',
                        textAlign: TextAlign.center,
                        style: TextStyle(height: 1.45, color: Color(0xFF637386)),
                      ),
                      const SizedBox(height: 24),
                      for (final language in AppLanguage.values) ...[
                        _LanguageOption(
                          language: language,
                          selected: store.language == language,
                          onTap: () => store.setLanguage(language),
                        ),
                        if (language != AppLanguage.values.last)
                          const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Material(
      color: selected ? const Color(0xFFEAF7FF) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryDark
                  : const Color(0xFFDDE7F0),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                language.displayMark,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.nativeName,
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      localizations.languageName(language),
                      style: const TextStyle(color: Color(0xFF6C7B8A)),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: AppTheme.primaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
