$ErrorActionPreference = "Stop"

Write-Host "=== NhaWOW Android release build ===" -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Khong tim thay Flutter trong PATH." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "firebase_config.json")) {
    Write-Host "Chua co firebase_config.json." -ForegroundColor Yellow
    Write-Host "Hay copy firebase_config.example.json thanh firebase_config.json va dien Firebase project that." -ForegroundColor Yellow
    Write-Host "Neu build khong co file nay, app van chay nhung KHONG the nhan push FCM tu server." -ForegroundColor Yellow
    exit 1
}

flutter clean
flutter pub get
dart run flutter_launcher_icons
flutter build apk --release --dart-define-from-file=firebase_config.json

Write-Host "" 
Write-Host "APK: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
