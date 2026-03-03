# iOS Build Quick Reference

## TL;DR - 3 Options

### Option 1: Codemagic (EASIEST - Windows)
```
1. Go to codemagic.io
2. Sign up with GitHub
3. Select your repo
4. Click "Start building"
5. Done! ✅
```
**Time:** 10 minutes | **Cost:** Free

---

### Option 2: GitHub Actions (FREE - Automated)
```
1. Push to GitHub
2. Actions automatically builds
3. Download .ipa file
4. Test on TestFlight
5. Submit to App Store
```
**Time:** 15 minutes | **Cost:** Free

---

### Option 3: Mac + Xcode (MANUAL - Best Control)
```bash
flutter build ios --release
open ios/Runner.xcworkspace
# Sign and upload in Xcode UI
```
**Time:** 30-60 minutes | **Cost:** Free

---

## Build Commands (Mac Only)

```bash
# Test on simulator
flutter run -d ios

# Debug build
flutter build ios

# Release build
flutter build ios --release

# Verbose output
flutter build ios --release -v

# Clean and rebuild
flutter clean && flutter pub get && flutter build ios --release
```

---

## Version Numbering

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

For updates:
- Change to `1.0.1+2` for bug fix
- Change to `1.1.0+3` for new features
- Change to `2.0.0+4` for major redesign

---

## Upload to TestFlight

1. **Via Codemagic:** Automatic ✅
2. **Via Xcode:**
   - Open `ios/Runner.xcworkspace`
   - Product → Archive
   - Upload to TestFlight button

---

## Upload to App Store

1. **After TestFlight approval (1-2 weeks)**
2. **Log into App Store Connect**
3. **App → Version History → In Review**
4. **Apple reviews (2-3 days)**
5. **App goes live!**

---

## Files to Edit Before First Build

- [ ] `pubspec.yaml` - Version number
- [ ] `ios/Runner/Info.plist` - App name, permissions
- [ ] `ios/Runner/Assets.xcassets/AppIcon.appiconset/` - App icons
- [ ] `ios/ExportOptions.plist` - Team ID (if using Codemagic)

---

## App Store Requirements Checklist

- [ ] App name & subtitle
- [ ] App description (max 4000 chars)
- [ ] Keywords (comma-separated)
- [ ] App preview (5.5" and 6.5" screenshots)
- [ ] App icon (1024x1024)
- [ ] Privacy policy URL
- [ ] Support URL
- [ ] Contact email
- [ ] Age rating (12+)
- [ ] Category (Medical)
- [ ] Bundle ID unique?
- [ ] Version number incremented?

---

## File Structure

```
painpal/
├── codemagic.yaml              ← Automated iOS build config
├── ios/
│   ├── Runner/
│   │   ├── Assets.xcassets/   ← App icons here
│   │   └── Info.plist         ← Permissions & settings
│   ├── Podfile                ← iOS dependencies
│   ├── ExportOptions.plist    ← Signing config
│   └── Runner.xcworkspace     ← Open this in Xcode
├── pubspec.yaml               ← Version number
└── README.md
```

---

## Permissions Already Configured ✅

- [x] Camera access
- [x] Photo library read
- [x] Photo library write

Messages:
- "Allow camera access to capture MRI images."
- "Allow photo library access to select MRI images."
- "Allow saving MRI images to your library."

---

## Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| Pod install fails | `cd ios && pod repo update && pod install --repo-update` |
| Build cache issue | `flutter clean` |
| Signing error | Configure Team ID in Xcode or codemagic.yaml |
| Memory error | Add `--split-debug-info=build/app/outputs/symbols` |
| Slow build | Use `--release` and remove debug symbols |

---

## Cost Breakdown

| Item | Cost | Notes |
|------|------|-------|
| Flutter SDK | Free | Open source |
| Codemagic | Free | 200 builds/month free |
| Xcode | Free | From App Store |
| Apple Developer | $99/year | Required for App Store |
| Certificate | Included | 3-year cert (auto-renew) |
| **TOTAL FIRST YEAR** | **$99** | One-time setup |

---

## Timeline to App Store

1. **Week 1:** Build with Codemagic ✅
2. **Week 2-3:** Beta test on TestFlight
3. **Week 4:** Submit to App Store
4. **Week 5:** Apple review (2-3 days typical)
5. **Week 5+:** Live on App Store! 🎉

---

## Key Resources

- Codemagic Docs: https://docs.codemagic.io
- Flutter iOS: https://docs.flutter.dev/deployment/ios
- App Store Connect: https://appstoreconnect.apple.com
- Apple Developer: https://developer.apple.com

---

## 🚀 Start Now!

**Recommended:** Use Codemagic
1. Sign up: codemagic.io
2. Connect GitHub repo
3. Select iOS build
4. Click "Build"
5. Get .ipa file in 15-20 minutes!

No Mac needed. No manual steps. Automatic updates. ✨

