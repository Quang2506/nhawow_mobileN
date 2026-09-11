import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    // Với message có notification payload, Android/iOS vẫn có thể tự hiển thị
    // thông báo. Không để lỗi Firebase trong isolate nền làm crash ứng dụng.
  }
}

class PushPayload {
  const PushPayload({
    required this.type,
    required this.conversationId,
    required this.propertyId,
    required this.notificationId,
    required this.url,
    this.title = '',
    this.body = '',
  });

  final String type;
  final int conversationId;
  final int propertyId;
  final int notificationId;
  final String url;
  final String title;
  final String body;

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
      title: (message.notification?.title ?? data['title'] ?? '')
          .toString()
          .trim(),
      body: (message.notification?.body ??
              data['body'] ??
              data['message'] ??
              '')
          .toString()
          .trim(),
    );
  }

  factory PushPayload.fromLocalNotificationPayload(String rawPayload) {
    int parseInt(Object? value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is! Map) return PushPayload.empty;
      final data = Map<String, dynamic>.from(decoded);
      return PushPayload(
        type: (data['type'] ?? '').toString().trim(),
        conversationId: parseInt(data['conversationId']),
        propertyId: parseInt(data['propertyId']),
        notificationId: parseInt(data['notificationId']),
        url: (data['url'] ?? '').toString().trim(),
      );
    } catch (_) {
      return PushPayload.empty;
    }
  }

  String toLocalNotificationPayload() => jsonEncode(<String, Object>{
        'type': type,
        'conversationId': conversationId,
        'propertyId': propertyId,
        'notificationId': notificationId,
        'url': url,
      });

  static const PushPayload empty = PushPayload(
    type: '',
    conversationId: 0,
    propertyId: 0,
    notificationId: 0,
    url: '',
  );
}

typedef PushTokenCallback = Future<void> Function(
  String token,
  String platform,
);
typedef PushForegroundCallback = Future<void> Function(PushPayload payload);

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'nhawow_messages',
    'Tin nhắn và thông báo NhaWOW',
    description: 'Tin nhắn mới và các thông báo quan trọng từ NhaWOW.',
    importance: Importance.max,
    playSound: true,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<PushPayload> _openedController =
      StreamController<PushPayload>.broadcast();

  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;

  PushTokenCallback? _onToken;
  PushForegroundCallback? _onForeground;
  bool _listenersReady = false;
  bool _localNotificationsReady = false;

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

  /// Khởi tạo local notifications độc lập với Firebase. Nhờ đó Android 13+
  /// vẫn có thể hiện popup xin quyền ngay sau khi người dùng chọn ngôn ngữ,
  /// kể cả khi Firebase chưa được cấu hình trong bản build hiện tại.
  Future<void> initializeLocalNotifications() async {
    if (_localNotificationsReady) return;

    const androidSettings = AndroidInitializationSettings('ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final rawPayload = response.payload?.trim() ?? '';
        if (rawPayload.isEmpty) return;
        final payload = PushPayload.fromLocalNotificationPayload(rawPayload);
        _openedController.add(payload);
      },
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }

    _localNotificationsReady = true;
  }

  /// Xin quyền notification ở thời điểm phù hợp với UX (sau chọn ngôn ngữ),
  /// thay vì chờ tới khi đăng nhập mới hỏi như code cũ.
  Future<bool> requestNotificationPermission() async {
    try {
      await initializeLocalNotifications();

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final granted = await _localNotifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission();
          // Android < 13 không cần runtime permission nên plugin có thể trả null.
          return granted ?? true;
        case TargetPlatform.iOS:
          final granted = await _localNotifications
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true);
          return granted ?? false;
        case TargetPlatform.macOS:
          final granted = await _localNotifications
              .resolvePlatformSpecificImplementation<
                  MacOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true);
          return granted ?? false;
        default:
          return true;
      }
    } catch (_) {
      // Notification là tính năng bổ sung, không được ngăn app khởi động.
      return false;
    }
  }

  Future<bool> activate({
    required PushTokenCallback onToken,
    required PushForegroundCallback onForeground,
  }) async {
    _onToken = onToken;
    _onForeground = onForeground;

    await initializeLocalNotifications();
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

    // Foreground notification do flutter_local_notifications hiển thị để
    // Android và iOS có hành vi giống nhau và tránh iOS hiển thị trùng 2 lần.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    if (!_listenersReady) {
      _listenersReady = true;

      _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
        final payload = PushPayload.fromMessage(message);
        unawaited(_showForegroundNotification(payload));

        final callback = _onForeground;
        if (callback != null) {
          unawaited(callback(payload));
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

  Future<void> _showForegroundNotification(PushPayload payload) async {
    final title = payload.title.isEmpty ? 'NhaWOW' : payload.title;
    final body = payload.body.isNotEmpty
        ? payload.body
        : payload.isChat
            ? 'Bạn có tin nhắn mới.'
            : 'Bạn có thông báo mới.';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'nhawow_messages',
        'Tin nhắn và thông báo NhaWOW',
        channelDescription: 'Tin nhắn mới và các thông báo quan trọng từ NhaWOW.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: 'ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final notificationId = payload.notificationId > 0
        ? payload.notificationId
        : DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

    try {
      await _localNotifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload.toLocalNotificationPayload(),
      );
    } catch (_) {
      // Không để lỗi local notification làm gián đoạn việc refresh chat/data.
    }
  }

  Future<String?> currentToken() async {
    if (!isFirebaseReady) return null;
    return _readTokenSafely(FirebaseMessaging.instance);
  }

  Future<String?> _readTokenSafely(FirebaseMessaging messaging) async {
    try {
      // Firebase iOS SDK yêu cầu APNs token có trước khi gọi getToken.
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
