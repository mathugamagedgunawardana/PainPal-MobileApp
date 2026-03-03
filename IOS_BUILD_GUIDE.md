# Building PainPal iOS App Guide

## Quick Answer
**Yes, you can build an iOS app from this Flutter project.** However, you need a Mac with Xcode installed.

---

## Prerequisites for iOS Build

### On Mac:
- [ ] macOS 10.15 or higher
- [ ] Xcode 12.0 or higher
- [ ] CocoaPods
- [ ] Flutter SDK (3.41.2+)
- [ ] Apple Developer Account (for App Store deployment)

### Check if ready:
```bash
flutter doctor -v
```

---

## Step-by-Step: Build on Mac

### 1. **Get Dependencies**
```bash
cd D:\painpal
flutter clean
flutter pub get
```

### 2. **Build iOS App (Debug)**
```bash
flutter build ios
```

### 3. **Build iOS App (Release)**
```bash
flutter build ios --release
```

Output location: `build/ios/iphoneos/Runner.app`

### 4. **Open in Xcode** (Optional - for signing & deployment)
```bash
open ios/Runner.xcworkspace
```

### 5. **Archive & Submit to App Store**
In Xcode:
1. Select "Product" → "Archive"
2. Sign with your Apple Developer certificate
3. Use Xcode Organizer to upload to App Store

---

## Option 2: GitHub Actions (Automated on macOS)

### Setup:
1. Push code to GitHub
2. Enable GitHub Actions in Settings
3. Create `.github/workflows/ios-build.yml` ✅ (already created)

The workflow will automatically build iOS app on every push.

---

## Option 3: Codemagic CI/CD (Recommended for Windows Users)

### Steps:
1. Go to [Codemagic.io](https://codemagic.io)
2. Sign up with GitHub account
3. Select your repository
4. Select "iOS" as target platform
5. Click "Start building"

**Advantages:**
- ✅ No Mac needed
- ✅ Free tier available
- ✅ Automatic builds on push
- ✅ Automatic deployment to App Store/TestFlight
- ✅ Build logs and artifacts saved

**Codemagic Config** (`codemagic.yaml`):
```yaml
workflows:
  ios-workflow:
    name: iOS Workflow
    max_build_duration: 120
    environment:
      ios: default
      xcode: latest
      cocoapods: default
    triggering:
      events:
        - push
        - pull_request
      branch:
        patterns:
          - main
          - develop
    scripts:
      - name: Get Flutter packages
        script: flutter pub get
      - name: Build iOS
        script: flutter build ios --release
    artifacts:
      - build/ios/iphoneos/Runner.app
    publishing:
      app_store_connect:
        auth: integration
```

---

## iOS Build Settings to Check

### 1. **Minimum iOS Deployment Target**
Edit `ios/Podfile`:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_PHOTOS=1',
      ]
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

### 2. **App Permissions** (for camera & photo library)
Edit `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>PainPal needs camera access to upload MRI scans</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>PainPal needs photo library access to select MRI images</string>
</key>NSPhotoLibraryAddUsageDescription</key>
<string>PainPal needs to save MRI scans to your photo library</string>
```

### 3. **App Icon**
Replace `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-*.png` with your app icon (all sizes).

### 4. **App Display Name**
Edit `ios/Runner/Info.plist`:
```xml
<key>CFBundleDisplayName</key>
<string>PainPal</string>
```

---

## Common iOS Build Issues & Solutions

### **Issue 1: CocoaPods Issues**
```bash
cd ios
rm Podfile.lock
pod repo update
pod install --repo-update
cd ..
flutter build ios
```

### **Issue 2: Signing Certificate Not Found**
```bash
flutter build ios --release \
  --code-sign-identity="iPhone Developer" \
  --provisioning-profile-path="/path/to/profile.mobileprovision"
```

### **Issue 3: Xcode Compilation Error**
```bash
flutter clean
flutter pub get
flutter build ios --verbose
```

### **Issue 4: Memory Issues During Build**
```bash
flutter build ios --release --split-debug-info=build/app/outputs/symbols
```

---

## Deployment to App Store

### Requirements:
1. **Apple Developer Account** ($99/year)
2. **App Store Certificate** (signed in Xcode)
3. **Provisioning Profile** (from Apple)
4. **App ID** (registered in Apple Developer Console)

### Process:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Set Team ID: Select "Runner" → "General" → Choose Team
3. Archive app: Product → Archive
4. In Organizer, click "Distribute App"
5. Select "App Store Connect"
6. Follow upload wizard

---

## TestFlight Distribution (Beta Testing)

### Easier than full App Store submission:
1. Archive in Xcode
2. Upload to App Store Connect → TestFlight
3. Add internal testers (Apple Developer team members)
4. Testers download from TestFlight app
5. Get feedback before full release

---

## File Structure for iOS Build

```
ios/
├── Runner/
│   ├── Assets.xcassets/          # App icons & assets
│   ├── Base.lproj/               # Launch screen
│   ├── GeneratedPluginRegistrant.*
│   ├── Info.plist                # App configuration
│   └── Runner-Bridging-Header.h  # Swift/Objective-C bridge
├── Runner.xcodeproj/
├── Runner.xcworkspace/           # Use this workspace!
└── Podfile                        # iOS dependencies
```

---

## Recommendations for PainPal iOS

### Before Building:
1. ✅ Update app version in `pubspec.yaml`
2. ✅ Update iOS version in `ios/Podfile`
3. ✅ Add app icon (replace default)
4. ✅ Configure permissions in `Info.plist`
5. ✅ Test on iOS simulator first

### Build Command:
```bash
flutter build ios --release -v
```

### Sign & Deploy:
```bash
open ios/Runner.xcworkspace
# Then use Xcode UI to sign and deploy
```

---

## Next Steps

1. **If you have a Mac:**
   - Run `flutter build ios --release`
   - Test on simulator: `flutter run -d ios`

2. **If you don't have a Mac:**
   - Option A: Use Codemagic (easiest)
   - Option B: Use GitHub Actions (free)
   - Option C: Ask a colleague with Mac to build

3. **For App Store submission:**
   - Enroll in Apple Developer Program
   - Follow deployment guide above
   - Submit app with required information

---

## Testing iOS Build Locally (with Mac)

```bash
# Build for iOS simulator
flutter run -d ios

# Build for physical device
flutter build ios --release
# Then open in Xcode and select device
```

---

## Troubleshooting iOS Builds

| Issue | Solution |
|-------|----------|
| `Pods/flutter_framework.sh: No such file` | Run `pod deintegrate && pod install --repo-update` |
| `ARCHS=i386 i686 x86_64` error | Update `ios/Podfile` minimum target to 12.0+ |
| `Swift version mismatch` | Update Xcode and CocoaPods |
| `Memory error` | Reduce app size: `--split-debug-info` |
| `Signing error` | Configure Team ID in Xcode |

---

## Summary

**Can you build iOS?**
- ✅ **YES** - Flutter fully supports iOS
- ✅ **Works on all platforms** - Even from Windows using CI/CD
- ✅ **Easy deployment** - Codemagic or GitHub Actions

**Recommended Path:**
1. Use **Codemagic** for cloud builds (Windows-friendly)
2. Or borrow a Mac for local `flutter build ios` command
3. Deploy to App Store via Xcode or Codemagic

---

**Questions?** Check Flutter's official iOS deployment guide:
https://docs.flutter.dev/deployment/ios


