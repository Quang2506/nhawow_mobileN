# Account deactivation - 2026-09-23

## Mobile app

- Added **Account > Deactivate account**.
- User confirms a 1-hour grace period before deactivation.
- Shows the scheduled time and a live countdown.
- User can cancel the request during the grace period.
- When the grace period ends, the app clears the local session automatically.
- Listings, photos, and account data are not deleted.
- Added Vietnamese / English / Chinese UI strings.

## Required backend APIs

- `POST /mobile-api/auth/deactivate`
- `POST /mobile-api/auth/cancel-deactivation`

The backend must store the scheduled timestamp and enforce the disabled status after the grace period. The matching backend package and PostgreSQL migration are provided separately.
