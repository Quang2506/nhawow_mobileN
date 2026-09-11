# NhaWOW Firebase configuration - 2026-08-28

Firebase project: `nhawow-e299a`

## App IDs synchronized
- Android applicationId: `com.nhawow.app`
- iOS bundle identifier: `com.nhawow.app`

## Files installed
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`
- Flutter build config: `firebase_config.json`

## Android build
Run from project root:

```powershell
.\build_android_release.ps1
```

or:

```powershell
flutter clean
flutter pub get
dart run flutter_launcher_icons
flutter build apk --release --dart-define-from-file=firebase_config.json
```

## iOS run/build
On macOS:

```bash
flutter clean
flutter pub get
flutter run --dart-define-from-file=firebase_config.json
```

For App Store builds, use the same `--dart-define-from-file=firebase_config.json` values in the Flutter build process.

## Backend note
These mobile client config files are NOT the Firebase service-account credential used by the ASP.NET backend to send FCM notifications.
The backend still needs a Firebase service-account private key JSON (Firebase Console > Project settings > Service accounts > Generate new private key), stored as configured by the backend patch.
For iOS push delivery, Firebase must also be configured with an APNs authentication key/certificate from Apple Developer.
