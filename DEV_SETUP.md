# YourGPT Flutter SDK - Development Environment Setup

## Prerequisites

### Required Software
- **Flutter SDK** (3.0.0 or higher) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (included with Flutter)
- **Git** for version control

### Platform-Specific Requirements

#### For iOS Development
- **macOS** (required for iOS development)
- **Xcode** (latest version) - [Mac App Store](https://apps.apple.com/app/xcode/id497799835)
- **iOS Simulator** (included with Xcode)
- **CocoaPods** - `sudo gem install cocoapods`

#### For Android Development
- **Android Studio** - [Download](https://developer.android.com/studio)
- **Android SDK** (API level 21+)
- **Android Emulator** or physical device
- **Java Development Kit (JDK)** - OpenJDK 11

## Environment Verification

### Check Flutter Installation
```bash
# Verify Flutter installation
flutter doctor

# This should show checkmarks for:
# ✓ Flutter (Channel stable, 3.x.x)
# ✓ Android toolchain - develop for Android devices
# ✓ Xcode - develop for iOS and macOS (macOS only)
# ✓ Android Studio
# ✓ VS Code or IntelliJ IDEA
```

### Fix Common Issues
```bash
# Accept Android licenses
flutter doctor --android-licenses

# Update Flutter
flutter upgrade

# Clean Flutter cache if needed
flutter clean
```

## Quick Start

### 1. Setup Project
```bash
# Navigate to Flutter SDK directory
cd flutter-sdk

# Get dependencies for the SDK
flutter pub get

# Navigate to example app
cd example

# Get dependencies for example app
flutter pub get
```

### 2. iOS Setup
```bash
# Open iOS Simulator
open -a Simulator

# Run on iOS
flutter run

# Or specify a specific device
flutter run -d "iPhone 14"

# For iOS device (requires developer account)
flutter run -d "Your iPhone"
```

### 3. Android Setup
```bash
# List available devices
flutter devices

# Start Android emulator (if not running)
# Use Android Studio AVD Manager or:
flutter emulators --launch <emulator_id>

# Run on Android
flutter run

# Or specify a specific device
flutter run -d <device_id>
```

## Development Workflow

### Local SDK Development

The example app uses the local SDK through the `pubspec.yaml` dependency:

```yaml
dependencies:
  yourgpt_flutter_sdk:
    path: ../  # Points to parent directory (the SDK)
```

### Hot Reload & Restart

Flutter supports instant code updates:

```bash
# Hot reload (preserves app state)
# Press 'r' in terminal or Ctrl+S in IDE

# Hot restart (resets app state)
# Press 'R' in terminal or Ctrl+Shift+S in IDE

# Quit app
# Press 'q' in terminal
```

### Running with Different Configurations

```bash
# Run in debug mode (default)
flutter run

# Run in profile mode (performance testing)
flutter run --profile

# Run in release mode
flutter run --release

# Run with verbose logging
flutter run -v
```

## Testing the SDK

### 1. Basic Functionality Test
```dart
// In example/lib/main.dart, verify these features work:
1. SDK initialization with valid widgetUid
2. Loading states display correctly
3. Error handling with invalid configuration
4. WebView loads the widget successfully
5. Bidirectional communication (send message, receive events)
```

### 2. Debug Mode Testing
```dart
// Enable debug mode in the example app
final config = YourGPTConfig(
  widgetUid: 'widget_123456',
  debug: true, // Enable detailed logging
);
```

### 3. Platform-Specific Testing

#### iOS Testing
```bash
# Run on different iOS simulators
flutter run -d "iPhone 14"
flutter run -d "iPhone 14 Pro Max"
flutter run -d "iPad Pro (12.9-inch)"

# List iOS simulators
xcrun simctl list devices

# Run on physical iOS device
flutter run -d "Your iPhone Name"
```

#### Android Testing
```bash
# List Android devices and emulators
flutter devices
adb devices

# Run on specific Android device
flutter run -d <device_id>

# Run on Android emulator with specific API level
flutter emulators --launch Pixel_API_33
```

## Development Commands

### SDK Development
```bash
# In flutter-sdk/ directory

# Analyze code quality
flutter analyze

# Format code
flutter format .

# Get dependencies
flutter pub get

# Run tests
flutter test
```

### Example App Commands
```bash
# In flutter-sdk/example/ directory

# Run app
flutter run

# Clean build
flutter clean

# Build APK (Android)
flutter build apk

# Build iOS app
flutter build ios

# Install on device
flutter install
```

## Debugging

### Flutter Inspector
```bash
# Run with Flutter Inspector
flutter run --track-widget-creation

# Open DevTools in browser
# Click the link shown in terminal output
```

### Debug Console
```bash
# Enable debug mode in your app for detailed logging
print('Debug message');
debugPrint('Debug message with longer text');

# Use Flutter logging
import 'dart:developer' as developer;
developer.log('Custom log message', name: 'YourGPTSDK');
```

### Platform-Specific Debugging

#### iOS Debugging (Xcode)
```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace

# Use Xcode debugger for native iOS code
# Set breakpoints in platform channels
```

#### Android Debugging (Android Studio)
```bash
# Open Android project
# File > Open > flutter-sdk/example/android

# View logs in Android Studio
# Or use command line:
flutter logs
adb logcat | grep flutter
```

### WebView Debugging
```bash
# For Android WebView debugging
# Enable USB debugging and WebView debugging in app

# Chrome DevTools for WebView
# Navigate to chrome://inspect in Chrome browser
# Select your app's WebView
```

## IDE Setup

### Visual Studio Code (Recommended)
Install these extensions:
- Dart
- Flutter
- Flutter Widget Snippets
- Bracket Pair Colorizer
- GitLens

Configure settings in `.vscode/settings.json`:
```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true
}
```

### Android Studio/IntelliJ IDEA
Install plugins:
- Flutter
- Dart

### Xcode
- Required for iOS development
- No additional plugins needed

## Performance Testing

### Performance Monitoring
```bash
# Run in profile mode for performance analysis
flutter run --profile

# Use Flutter Performance tab in DevTools
# Monitor CPU, memory, and frame rendering
```

### Memory Analysis
```bash
# Use Observatory for memory debugging
flutter run --observatory-port=8080

# Or use DevTools memory tab
flutter run --track-widget-creation
```

### Network Monitoring
```bash
# Enable network logging in debug mode
# Use DevTools Network tab
# Check WebView network requests
```

## Common Issues & Solutions

### Flutter Issues
```bash
# Clear Flutter cache
flutter clean
flutter pub get

# Reset Flutter
flutter clean
rm -rf ~/.flutter
flutter doctor
```

### iOS Build Issues
```bash
# Clean iOS build
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter run
```

### Android Build Issues
```bash
# Clean Android build
flutter clean
cd android
./gradlew clean
cd ..
flutter run

# Fix Gradle issues
cd android
./gradlew --stop
./gradlew clean build
```

### WebView Issues
1. **WebView not loading**:
   - Check internet permissions in AndroidManifest.xml
   - Verify ATS settings in iOS Info.plist
   - Test with simple URL first

2. **JavaScript not working**:
   - Ensure JavaScript is enabled in WebView settings
   - Check for JavaScript errors in DevTools

3. **Communication bridge not working**:
   - Verify JavaScriptChannel setup
   - Check message format consistency

## CI/CD Setup

### GitHub Actions Example
```yaml
# .github/workflows/flutter.yml
name: Flutter CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.x.x'
    - run: flutter pub get
    - run: flutter test
    - run: flutter analyze
    - run: flutter build apk
```

## Release Testing

### Pre-release Checklist
- [ ] Test on iOS simulators (iPhone, iPad)
- [ ] Test on Android emulators (different API levels)
- [ ] Test on physical devices (iOS and Android)
- [ ] Verify all SDK methods work correctly
- [ ] Test error handling scenarios
- [ ] Performance testing with Flutter DevTools
- [ ] Memory leak testing
- [ ] Network interruption testing
- [ ] Different screen sizes and orientations

### Build for Distribution
```bash
# Android Release Build
flutter build apk --release
flutter build appbundle --release

# iOS Release Build
flutter build ios --release

# Generate signed APK (Android)
flutter build apk --release --shrink
```

## Troubleshooting

### Common Error Messages

1. **"MissingPluginException"**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **"CocoaPods not installed"**:
   ```bash
   sudo gem install cocoapods
   pod setup
   ```

3. **"Android license status unknown"**:
   ```bash
   flutter doctor --android-licenses
   ```

4. **"Xcode not found"**:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   ```

## Support Resources

### Documentation
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [WebView Flutter Plugin](https://pub.dev/packages/webview_flutter)

### Community
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [Flutter Discord](https://discord.gg/flutter)

### Tools
- [Flutter DevTools](https://docs.flutter.dev/development/tools/devtools/overview)
- [Dart DevTools](https://dart.dev/tools/dart-devtools)
- [Flutter Inspector](https://docs.flutter.dev/development/tools/devtools/inspector)