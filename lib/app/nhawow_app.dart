import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/app_theme.dart';
import '../features/language_selection_page.dart';
import '../features/main_shell.dart';
import '../l10n/app_language.dart';
import '../l10n/app_localizations.dart';
import 'app_store.dart';

class NhaWowApp extends StatefulWidget {
  const NhaWowApp({super.key});

  @override
  State<NhaWowApp> createState() => _NhaWowAppState();
}

class _NhaWowAppState extends State<NhaWowApp> {
  late final AppStore _store;

  @override
  void initState() {
    super.initState();
    _store = AppStore();
    _store.initialize();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: _store,
      child: AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          return MaterialApp(
            title: 'NhaWOW',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            locale: _store.locale,
            supportedLocales: AppLanguage.values
                .map((language) => language.locale)
                .toList(growable: false),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const _AppEntryPoint(),
          );
        },
      ),
    );
  }
}

class _AppEntryPoint extends StatelessWidget {
  const _AppEntryPoint();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (!store.isBootstrapComplete) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 14),
              Text(context.tr('Đang tải dữ liệu...')),
            ],
          ),
        ),
      );
    }

    if (!store.hasLanguagePreference) {
      return const LanguageSelectionPage();
    }

    return const MainShell();
  }
}
