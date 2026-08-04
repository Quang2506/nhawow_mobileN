# Authentication and permissions — 2026-07-31

- Removed the demo account and the broker-role switch from the login screen.
- Login now uses the same email/phone, password, account status and role data as the NhaWOW website.
- Added registration, email OTP verification/resend, forgot password, reset password, profile update and change password.
- Login token is saved in SharedPreferences and restored when the application starts.
- Favorites are synchronized with the logged-in web account.
- Full owner phone number, chat, messages, notifications and favorites require login.
- **Đăng tin** follows the website permission flow: require login, then enable Partner posting permission and open listing management.
- Expired sessions are removed from the device and the user is asked to log in again.
- Added Vietnamese, English and Chinese text for the account flow.

The Web/API package must be deployed first because the application calls the new `/mobile-api/auth/*` and `/mobile-api/favorites/*` endpoints.
