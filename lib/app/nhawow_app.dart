import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/app_theme.dart';
import '../features/chat_thread_page.dart';
import '../features/language_selection_page.dart';
import '../features/notifications_page.dart';
import '../features/property_detail_page.dart';
import '../features/main_shell.dart';
import '../l10n/app_language.dart';
import '../l10n/app_localizations.dart';
import '../services/push_notification_service.dart';
import 'app_store.dart';

class NhaWowApp extends StatefulWidget {
  const NhaWowApp({super.key});

  @override
  State<NhaWowApp> createState() => _NhaWowAppState();
}

class _NhaWowAppState extends State<NhaWowApp> {
  late final AppStore _store;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<PushPayload>? _pushOpenedSubscription;
  PushPayload? _pendingPush;
  bool _isOpeningPush = false;

  @override
  void initState() {
    super.initState();
    _store = AppStore();
    _store.addListener(_handleStoreChanged);
    _pushOpenedSubscription =
        PushNotificationService.instance.openedMessages.listen(_queuePushOpen);
    unawaited(_store.initialize());
  }

  @override
  void dispose() {
    _store.removeListener(_handleStoreChanged);
    unawaited(_pushOpenedSubscription?.cancel());
    _store.dispose();
    super.dispose();
  }

  void _handleStoreChanged() {
    if (_pendingPush != null) _schedulePendingPushOpen();
  }

  void _queuePushOpen(PushPayload payload) {
    _pendingPush = payload;
    _schedulePendingPushOpen();
  }

  void _schedulePendingPushOpen() {
    if (_isOpeningPush ||
        !_store.isBootstrapComplete ||
        !_store.hasLanguagePreference) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_openPendingPush());
    });
  }

  Future<void> _openPendingPush() async {
    if (_isOpeningPush) return;
    final payload = _pendingPush;
    final navigator = _navigatorKey.currentState;
    if (payload == null || navigator == null) return;

    _isOpeningPush = true;
    _pendingPush = null;
    try {
      if (_store.isLoggedIn) {
        if (payload.isChat && payload.conversationId > 0) {
          await _store.refreshConversations(force: true);
          await navigator.push<void>(
            MaterialPageRoute<void>(
              builder: (_) =>
                  ChatThreadPage(conversationId: payload.conversationId),
            ),
          );
          return;
        }

        if (payload.propertyId > 0) {
          await _store.refreshNotifications(force: true);
          await navigator.push<void>(
            MaterialPageRoute<void>(
              builder: (_) => PropertyDetailPage(propertyId: payload.propertyId),
            ),
          );
          return;
        }

        await _store.refreshNotifications(force: true);
      }

      await navigator.push<void>(
        MaterialPageRoute<void>(builder: (_) => const NotificationsPage()),
      );
    } finally {
      _isOpeningPush = false;
      if (_pendingPush != null) _schedulePendingPushOpen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: _store,
      child: AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
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
