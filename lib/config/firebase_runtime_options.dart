import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Cấu hình Firebase lấy từ --dart-define / --dart-define-from-file.
///
/// Cách này giúp project vẫn build/chạy bình thường khi chưa có cấu hình
/// Firebase. Khi đủ các giá trị bắt buộc, FCM sẽ được bật tự động.
class FirebaseRuntimeOptions {
  FirebaseRuntimeOptions._();

  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const String _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );

  static const String _androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const String _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );

  static const String _iosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
  );
  static const String _iosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
  );
  static const String _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'vn.nhawow.nhawowMobile',
  );

  static FirebaseOptions? get currentPlatform {
    if (_projectId.trim().isEmpty || _messagingSenderId.trim().isEmpty) {
      return null;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (_androidApiKey.trim().isEmpty || _androidAppId.trim().isEmpty) {
          return null;
        }
        return FirebaseOptions(
          apiKey: _androidApiKey.trim(),
          appId: _androidAppId.trim(),
          messagingSenderId: _messagingSenderId.trim(),
          projectId: _projectId.trim(),
          storageBucket:
              _storageBucket.trim().isEmpty ? null : _storageBucket.trim(),
        );
      case TargetPlatform.iOS:
        if (_iosApiKey.trim().isEmpty || _iosAppId.trim().isEmpty) {
          return null;
        }
        return FirebaseOptions(
          apiKey: _iosApiKey.trim(),
          appId: _iosAppId.trim(),
          messagingSenderId: _messagingSenderId.trim(),
          projectId: _projectId.trim(),
          storageBucket:
              _storageBucket.trim().isEmpty ? null : _storageBucket.trim(),
          iosBundleId: _iosBundleId.trim().isEmpty ? null : _iosBundleId.trim(),
        );
      default:
        return null;
    }
  }
}
