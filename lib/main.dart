import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app/nhawow_app.dart';
import 'config/firebase_runtime_options.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseOptions = FirebaseRuntimeOptions.currentPlatform;
  if (firebaseOptions != null) {
    try {
      await Firebase.initializeApp(options: firebaseOptions);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {
      // Firebase chưa cấu hình đúng thì app vẫn phải khởi động bình thường.
      // Push sẽ tự hoạt động sau khi các dart-define Firebase hợp lệ được cấp.
    }
  }

  runApp(const NhaWowApp());
}
