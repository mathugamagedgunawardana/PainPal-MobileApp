# Changelog

All notable changes to PainPal-MobileApp are documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Open-source documentation and contributor policies
- GitHub Actions CI (`flutter analyze`, `flutter test`)
- `docs/mobile-setup.md` and `docs/architecture-mobile.md`

### Changed

- README rewritten for public contributors
- Renamed `livekit_config.dart` → `ai_config.dart`

### Removed

- Unused `environment.dart` (contained hardcoded credentials)
- Deprecated `livekit_service.dart` stub

### Security

- Removed hardcoded MongoDB credentials from source

## [1.0.0] - 2026-06-29

### Added

- Flutter patient app with 6-tab navigation
- JWT authentication with token refresh
- Migraine logging, MRI upload, analytics, history
- Gemini AI chat with voice input/output
- Local SQLite offline storage
- Medication reminder notifications
- Doctor–patient chat integration

### Compatibility

- Requires [PainPal-Web](https://github.com/YOUR_ORG/PainPal-Web) API `>=1.0.0`

[Unreleased]: https://github.com/YOUR_ORG/PainPal-MobileApp/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/YOUR_ORG/PainPal-MobileApp/releases/tag/v1.0.0
