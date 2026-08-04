# Database integration changes

- Added API base configuration with `--dart-define=NHAWOW_API_BASE_URL=...`.
- Added conditional HTTP transport for Web and Android/iOS without third-party packages.
- Added parsing of real property, owner, image and lookup data.
- `AppStore` now loads PostgreSQL-backed data through the ASP.NET web API.
- Added refresh/loading/error states and mock fallback banner.
- Property details are refreshed from the API when opened.
- Property cards and detail gallery display network images.
- Added Android INTERNET permission.
- Admin is not included in the Flutter app.
