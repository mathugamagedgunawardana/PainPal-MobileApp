# PainPal Mobile Roadmap

Platform roadmap: [PainPal-Web/ROADMAP.md](https://github.com/YOUR_ORG/PainPal-Web/blob/main/ROADMAP.md)

## v1.0 — Open Source Launch

- [x] MIT license and contributor docs
- [x] CI with analyze + test
- [x] Security cleanup (no hardcoded DB credentials)
- [ ] Tag `v1.0.0` release with APK artifact

## v1.5 — Production Hardening

- Push notifications (FCM/APNs) for medication reminders
- Android application ID: `com.painpal.app` (from `com.example.painpal`)
- Widget and golden tests for analytics charts
- Improved offline sync conflict handling
- Remove unused dependencies (`dio`, `provider`, `uuid`, `web_socket_channel`)

## v2.0 — Platform Scale

- Shared Dart API client generated from OpenAPI spec
- Internationalization (i18n)
- Tablet-optimized layouts
- Biometric app lock

## Compatibility Matrix

| Mobile | Web API | Notes |
|--------|---------|-------|
| 1.0.x  | 1.0.x   | Initial public release |
| 1.5.x  | 1.5.x   | Push notifications require backend support |
| 2.0.x  | 2.0.x   | Breaking API changes — see CHANGELOG |
