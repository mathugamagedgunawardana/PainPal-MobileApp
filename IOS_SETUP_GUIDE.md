# PainPal iOS Setup & Build Instructions

## Quick Start (Windows Users - No Mac Needed!)

### Step 1: Push Code to GitHub
```bash
git init
git add .
git commit -m "Initial commit: PainPal iOS ready"
git push origin main
```

### Step 2: Set Up Codemagic (Free)
1. Go to **[codemagic.io](https://codemagic.io)**
2. Click "Sign Up" → Choose "GitHub"
3. Authorize Codemagic to access your repositories
4. Click your painpal repository
5. Select "iOS" as target platform
6. Click "Start building"

**That's it!** Codemagic will:
- ✅ Build your iOS app automatically
- ✅ Run tests
- ✅ Generate .ipa file
- ✅ Send you download link
- ✅ Optionally deploy to TestFlight

---

## Manual iOS Build (If You Have a Mac)

### Prerequisites on Mac:
```bash
# Install Xcode (from App Store or command line)
xcode-select --install

# Install CocoaPods
sudo gem install cocoapods

# Verify Flutter is installed
flutter doctor
```

### Build Commands:

#### Debug Build (for testing):
```bash
cd D:\painpal
flutter clean
flutter pub get
flutter run -d ios
```

#### Release Build (for App Store):
```bash
flutter build ios --release
```

#### Build with Verbose Output (troubleshooting):
```bash
flutter build ios --release -v
```

---

## iOS Configuration Files (Already Configured!)

### ✅ Permissions (Info.plist)
- Camera access ✓
- Photo library read ✓
- Photo library write ✓

### ✅ App Name
- Display name: "Painpal" ✓
- Bundle identifier: `com.yourcompany.painpal`
- Minimum iOS: 12.0+

---

## Preparing for App Store Release

### Step 1: Update Version Numbers
Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

**Version Format:** `major.minor.patch+buildNumber`
- **1.0.0**: Public version (for App Store)
- **+1**: Internal build number (increments with each build)

### Step 2: Update iOS-Specific Settings
Edit `ios/Runner/Info.plist`:
```xml
<key>CFBundleDisplayName</key>
<string>PainPal</string>

<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <false/>
  <key>NSExceptionDomains</key>
  <dict>
    <key>your-api-server.com</key>
    <dict>
      <key>NSIncludesSubdomains</key>
      <true/>
      <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
      <true/>
    </dict>
  </dict>
</dict>
```

### Step 3: App Icon
Replace app icons in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

**Required Sizes:**
- 20x20 (notifications)
- 29x29 (settings)
- 40x40 (spotlight)
- 60x60 (app icon)
- 76x76, 83.5x83.5 (iPad)
- 120x120, 180x180 (retina)
- 1024x1024 (App Store)

### Step 4: Launch Screen
Edit `ios/Runner/Base.lproj/LaunchScreen.storyboard`:
- Update brand color
- Add app logo
- Customize loading message

---

## App Store Submission Checklist

### Before Building:
- [ ] Increment version number in `pubspec.yaml`
- [ ] Update app icon (1024x1024 PNG)
- [ ] Test on iOS simulator
- [ ] Run `flutter analyze` (no errors)
- [ ] Update `README.md` with iOS instructions
- [ ] Create privacy policy URL
- [ ] Prepare app screenshots (5.5" and 6.5" sizes)

### Apple Developer Setup:
- [ ] Enroll in Apple Developer Program ($99/year)
- [ ] Create app record in App Store Connect
- [ ] Generate iOS App ID
- [ ] Create Signing Certificate
- [ ] Create Provisioning Profile
- [ ] Configure Team ID in Xcode

### For App Store:
- [ ] Write compelling app description
- [ ] Add keywords (health, migraine, tracker, MRI)
- [ ] Set age rating (12+ typical for health apps)
- [ ] Configure privacy policy
- [ ] Add support URL/email
- [ ] Accept terms and conditions

---

## Codemagic Workflow Setup (Recommended)

### 1. Configure in Codemagic UI:

**Environment Variables:**
```
APP_STORE_CONNECT_ISSUER_ID=your_issuer_id
APP_STORE_CONNECT_KEY_ID=your_key_id
APP_STORE_CONNECT_PRIVATE_KEY=your_private_key_content
```

**Team ID:**
- Set in `ios/ExportOptions.plist`
- Or configure in Codemagic dashboard

### 2. Automatic Deployment to TestFlight:

Codemagic can automatically upload to TestFlight:
```yaml
publishing:
  app_store_connect:
    auth: integration
    submit_to_testflight: true
    submit_to_app_store: false
```

### 3. Manual Release to App Store:

After testing on TestFlight (1-2 weeks):
1. Log in to App Store Connect
2. Go to "TestFlight" tab
3. Review version
4. Click "Add for Review"
5. Submit for App Store review
6. Apple reviews (2-3 days typical)
7. App goes live! 🎉

---

## TestFlight Beta Testing (Recommended Before App Store)

**Why TestFlight?**
- ✅ Share with beta testers (up to 10,000)
- ✅ Get user feedback
- ✅ Find bugs before public release
- ✅ Required before App Store submission

**Steps:**
1. Upload build via Codemagic or Xcode
2. Add internal testers (your team)
3. Send TestFlight links to external testers
4. Collect feedback for 1-2 weeks
5. Fix issues
6. Submit to App Store

---

## Troubleshooting iOS Builds

### Issue: "Pod install" fails
```bash
cd ios
rm Podfile.lock
pod repo update
pod install --repo-update
cd ..
```

### Issue: Xcode "No space left on device"
```bash
# Clear iOS build cache
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### Issue: Signing certificate expired
- Generate new certificate in Apple Developer Console
- Update provisioning profile
- Configure in Xcode (Preferences → Accounts)

### Issue: "Bitcode not supported"
Edit `ios/Podfile`:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
```

### Issue: Build takes too long
```bash
# Skip bitcode and symbols
flutter build ios --release \
  --split-debug-info=build/app/outputs/symbols
```

---

## Network Configuration for Migraine API

For your migraine prediction API to work on iOS:

### Update API Base URL Settings:
1. Open PainPal app
2. Go to Settings
3. Enter your API base URL
4. Enable/disable HTTPS validation as needed

### In Production:
- ✅ Always use HTTPS (required for App Store)
- ✅ Configure proper SSL certificates
- ✅ Use API keys/tokens for authentication
- ✅ Test with real network conditions

---

## Files Created for iOS Build:

✅ `codemagic.yaml` - Automated build configuration
✅ `ios/ExportOptions.plist` - Signing configuration
✅ `ios/Runner/Info.plist` - App permissions (updated)
✅ `.github/workflows/ios-build.yml` - GitHub Actions (optional)
✅ `IOS_BUILD_GUIDE.md` - This guide!

---

## Summary: Your Options

| Option | Effort | Cost | Time | Best For |
|--------|--------|------|------|----------|
| **Codemagic** | 10 min setup | Free | Automated | Windows users, continuous deployment |
| **GitHub Actions** | 15 min setup | Free | Automated | Already on GitHub |
| **Mac + Xcode** | Manual | Free | 30+ min | Full control, testing |
| **Local CI/CD** | Complex | Free | Varies | Advanced users |

---

## Next Actions:

### For Windows Users (Recommended):
1. ✅ Push code to GitHub
2. ✅ Sign up for Codemagic
3. ✅ Connect GitHub repository
4. ✅ Configure Apple Developer credentials
5. ✅ Click "Build" - Done!

### For Mac Users:
1. ✅ Run `flutter build ios --release`
2. ✅ Open in Xcode: `open ios/Runner.xcworkspace`
3. ✅ Sign with Apple Developer certificate
4. ✅ Click "Archive" then "Upload to App Store"

---

## Support Resources

- **Flutter iOS Deployment:** https://docs.flutter.dev/deployment/ios
- **Codemagic Docs:** https://docs.codemagic.io/
- **App Store Connect:** https://appstoreconnect.apple.com
- **Apple Developer:** https://developer.apple.com

**Ready to build?** Start with Codemagic - it's the easiest path! 🚀

