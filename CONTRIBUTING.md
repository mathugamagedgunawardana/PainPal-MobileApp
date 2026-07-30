# Contributing to PainPal Mobile

Thank you for improving the PainPal Flutter app!

**Backend/API docs:** [PainPal-Web](https://github.com/YOUR_ORG/PainPal-Web) — clone and run the API before mobile work.

## Code of Conduct

[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

## Setup

```bash
git clone https://github.com/YOUR_ORG/PainPal-MobileApp.git
cd PainPal-MobileApp
cp .env.example .env
flutter pub get
```

Start [PainPal-Web](https://github.com/YOUR_ORG/PainPal-Web) API first:

```bash
cd PainPal-Web/client && npm run dev
```

See [docs/mobile-setup.md](docs/mobile-setup.md).

## Before Opening a PR

```bash
dart analyze
dart format --set-exit-if-changed .
flutter test
```

Manual test on at least one target (Android emulator or iOS simulator).

## Branch & Commit Conventions

Same as web repo — [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(analytics): add 7-day filter chip
fix(auth): refresh token on 401 from patient API
docs: update Android emulator API URL
```

## PR Guidelines

- Link issues (`Fixes #42`)
- Include test plan and screenshots for UI changes
- No PHI in commits or screenshots
- Keep PRs focused

## Project Areas

| Label | Path |
|-------|------|
| `mobile` | `lib/screens/`, `lib/widgets/` |
| `backend` | Issues in PainPal-Web for API changes |
| `documentation` | `docs/`, `README.md` |
| `accessibility` | Touch targets, semantics, contrast |

## License

Contributions licensed under [MIT](LICENSE).
