# NhaWOW Web + Mobile database integration

## Web

- Added public mobile API backed by the existing PostgreSQL `AppDbContext` / `HomeNowConnection`.
- Added list, detail, lookup and health endpoints.
- Added CORS for Flutter Web development.
- Added secure external media resolver for `D:\img`.
- Added compatibility aliases for old `/Assets/properties`, `/Content/VR` and `/img` URLs.
- Updated partner/admin property image upload and deletion logic to use `/media` and physical storage outside web root.
- Private originals are stored under `D:\img\private` and rejected by the public media controller.

## Mobile

- Added API configuration using `NHAWOW_API_BASE_URL`.
- Added Web and IO HTTP transports without third-party packages.
- Loads all four property groups from the web API.
- Loads real property detail and image gallery when a listing is opened.
- Added loading, refresh, error and mock-fallback states.
- Added network images and owner avatar rendering.
- Added Android INTERNET permission.
- No Admin module was added to Flutter.

## Local run

1. Run the ASP.NET project and verify:
   `https://localhost:44323/mobile-api/health`
2. Create `D:\img` and grant the IIS app-pool read/modify permission.
3. Run Flutter:

```powershell
$flutter = "C:\Flutter\flutter_windows_3.44.6-stable\flutter\bin\flutter.bat"
Set-Location D:\Code\nhawow_mobile
& $flutter run -d chrome --dart-define=NHAWOW_API_BASE_URL=https://localhost:44323/mobile-api
```

Read the docs folders in each project for details.
