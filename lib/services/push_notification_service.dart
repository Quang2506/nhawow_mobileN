import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_runtime_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final options = FirebaseRuntimeOptions.currentPlatform;
  if (options == null) return;

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: options);
    }
  } catch (_) {
    // Notification payload vẫn có thể được hệ điều hành hiển thị. Không để
    // lỗi Firebase trong isolate nền làm ảnh hưởng đến ứng dụng.
  }
}

class PushPayload {
  const PushPayload({
    required this.type,
    required this.conversationId,
    required this.propertyId,
    required this.notificationId,
    required this.url,
  });

  final String type;
  final int conversationId;
  final int propertyId;
  final int notificationId;
  final String url;

  bool get isChat =>
      conversationId > 0 ||
      type.toLowerCase().contains('chat') ||
      type.toLowerCase().contains('message');

  factory PushPayload.fromMessage(RemoteMessage message) {
    int parseInt(Object? value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final data = message.data;
    return PushPayload(
      type: (data['type'] ?? data['kind'] ?? '').toString().trim(),
      conversationId: parseInt(
        data['conversationId'] ?? data['conversation_id'] ?? data['chatId'],
      ),
      propertyId: parseInt(data['propertyId'] ?? data['property_id']),
      notificationId: parseInt(
        data['notificationId'] ?? data['notification_id'] ?? data['id'],
      ),
      url: (data['url'] ?? data['targetUrl'] ?? '').toString().trim(),
    );
  }
}

typedef PushTokenCallback = Future<void> Function(
  String token,
  String platform,
);
typedef PushForegroundCallback = Future<void> Function(PushPayload payload);

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final StreamController<PushPayload> _openedController =
      StreamController<PushPayload>.broadcast();

  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;

  PushTokenCallback? _onToken;
  PushForegroundCallback? _onForeground;
  bool _listenersReady = false;

  Stream<PushPayload> get openedMessages => _openedController.stream;

  bool get isFirebaseReady => Firebase.apps.isNotEmpty;

  String get platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return defaultTargetPlatform.name;
    }
  }

  Future<bool> activate({
    required PushTokenCallback onToken,
    required PushForegroundCallback onForeground,
  }) async {
    _onToken = onToken;
    _onForeground = onForeground;

    if (!isFirebaseReady) return false;

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return false;
    }

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!_listenersReady) {
      _listenersReady = true;

      _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
        final callback = _onForeground;
        if (callback != null) {
          unawaited(callback(PushPayload.fromMessage(message)));
        }
      });

      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _openedController.add(PushPayload.fromMessage(message)),
      );

      _tokenSubscription = messaging.onTokenRefresh.listen((token) {
        final callback = _onToken;
        if (callback != null && token.trim().isNotEmpty) {
          unawaited(callback(token.trim(), platformName));
        }
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        scheduleMicrotask(
          () => _openedController.add(PushPayload.fromMessage(initialMessage)),
        );
      }
    }

    final token = await _readTokenSafely(messaging);
    if (token != null) {
      await onToken(token, platformName);
    }
    return true;
  }

  Future<String?> currentToken() async {
    if (!isFirebaseReady) return null;
    return _readTokenSafely(FirebaseMessaging.instance);
  }

  Future<String?> _readTokenSafely(FirebaseMessaging messaging) async {
    try {
      // Firebase iOS SDK 10.4+ yêu cầu APNs token có trước khi gọi getToken.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await messaging.getAPNSToken();
        if (apnsToken == null || apnsToken.trim().isEmpty) return null;
      }

      final token = (await messaging.getToken())?.trim() ?? '';
      return token.isEmpty ? null : token;
    } catch (_) {
      return null;
    }
  }

  void suspendSessionCallbacks() {
    _onToken = null;
    _onForeground = null;
  }

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _openedController.close();
  }
}
