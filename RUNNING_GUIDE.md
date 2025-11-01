# How to Run the Flutter SDK Example App

## 🚀 Complete Step-by-Step Guide

Follow these instructions to run the Flutter SDK example app with mobile data management features and modern UI.

## 📋 **Prerequisites**

### **System Requirements**
- **Flutter SDK**: 3.0.0+ 
- **Dart SDK**: 2.17.0+
- **Android Studio** or **VS Code** with Flutter extension
- **Device/Simulator**: Android or iOS

### **Check Your Flutter Setup**
```bash
# Verify Flutter installation
flutter doctor

# Check available devices
flutter devices

# Verify Flutter version
flutter --version
```

Expected output should show:
```
✓ Flutter (Channel stable, 3.x.x)
✓ Android toolchain
✓ VS Code or Android Studio
✓ Connected device or simulator
```

## 🛠️ **Setup Instructions**

### **Step 1: Navigate to Flutter Project**
```bash
cd "/Users/superman41/Drive/AI/Widget Mobile SDK/flutter-sdk"
```

### **Step 2: Check Project Structure**
Verify the Flutter project exists:
```bash
ls -la
# Should show: pubspec.yaml, lib/, android/, ios/, etc.
```

### **Step 3: Install Dependencies**
```bash
# Get Flutter packages
flutter pub get

# Clean previous builds (if any)
flutter clean
```

### **Step 4: Check Available Devices**
```bash
# List connected devices and simulators
flutter devices
```

You should see options like:
- **Android Emulator**: `Pixel_7_API_34 (mobile)`
- **iOS Simulator**: `iPhone 15 Pro (mobile)`
- **Physical Device**: `SM-G991B (mobile)` or `John's iPhone (mobile)`

### **Step 5: Start Device/Simulator**

#### **For Android Emulator**
```bash
# List available Android Virtual Devices
flutter emulators

# Launch specific emulator
flutter emulators --launch Pixel_7_API_34

# Or open Android Studio → AVD Manager → Start emulator
```

#### **For iOS Simulator** (macOS only)
```bash
# Open iOS Simulator
open -a Simulator

# Or launch specific simulator
xcrun simctl boot "iPhone 15 Pro"
```

#### **For Physical Device**
- **Android**: Enable USB debugging in Developer Options
- **iOS**: Trust computer when prompted, ensure device is unlocked

### **Step 6: Run the Flutter App**
```bash
# Run on default device
flutter run

# Run on specific device
flutter run -d "device_id"

# Run in debug mode with hot reload
flutter run --debug

# Run in release mode (for performance testing)
flutter run --release
```

### **Step 7: Development Mode Options**
Once running, you can use:
- **`r`** - Hot reload (apply changes instantly)
- **`R`** - Hot restart (full app restart)
- **`q`** - Quit the application
- **`h`** - Help (show all commands)

## 📱 **What You'll See**

### **🏠 Flutter Support Home Screen**
When the app launches, you'll see:

#### **App Bar**
- **Title**: "Help & Support"
- **Settings Icon**: Gear icon in top-right
- **Material Design**: Modern Flutter/Material 3 styling

#### **Status Card**
- **Connection Indicator**: Circular progress or status icon
- **Status Text**: 
  - 🔄 "Connecting to Support..." (orange)
  - ✅ "AI Assistant Ready" (green)
  - ❌ "Connection Failed" (red)
- **Chat Button**: Floating Action Button or elevated button

#### **Quick Actions Section**
Interactive Material cards:
- 💬 **Start Conversation** → Opens AI chat
- 📧 **Email Support** → Demo email functionality
- 📞 **Call Support** → Demo call functionality
- 🔍 **Help Search** → Demo search functionality

#### **FAQ Section**
Expandable cards with common questions:
- Password reset instructions
- Payment method updates
- Subscription management
- Support contact methods

### **💬 Enhanced Chat Experience**
When you tap the **Chat** button (after SDK shows ready):

#### **Full-Screen Chat Interface**
- **App Bar**: "AI Assistant" title with back arrow
- **WebView**: Full-screen widget integration
- **Loading States**: Circular progress indicators
- **Error States**: Material error widgets with retry buttons

#### **Automatic Data Injection**
The Flutter app automatically sends demo data:

```dart
// Session Data
{
  'userId': 'demo-user-123',
  'plan': 'premium',
  'sessionStart': DateTime.now().toIso8601String(),
  'features': ['ai-actions', 'support-chat', 'escalation'],
  'userSegment': 'premium-support',
  'platform': 'Flutter'
}

// Visitor Data (auto-enriched with Flutter/device info)
{
  'source': 'flutter-support-screen',
  'platform': 'Flutter',
  'dartVersion': '2.19.0',
  'flutterVersion': '3.7.0',
  'deviceModel': 'Pixel 7',
  'operatingSystem': 'Android 13',
  'screenSize': '1080x2400'
}

// Contact Data
{
  'email': 'demo@example.com',
  'name': 'Flutter Demo User',
  'phone': '+1-555-0123',
  'preferredLanguage': 'en',
  'timezone': 'America/New_York'
}
```

## 🔧 **Flutter Development Tools**

### **Hot Reload** (Recommended for Development)
```bash
# After making code changes, press 'r' in terminal
r
```
Changes apply instantly without losing app state.

### **Hot Restart** (For Larger Changes)
```bash
# Press 'R' in terminal for full restart
R
```
Restarts the entire app - needed for changes to main() or state initialization.

### **Flutter Inspector** (Debug UI)
```bash
# Run with inspector
flutter run --debug

# Open Flutter Inspector in browser
# Look for inspector URL in terminal output
```

### **Performance Profiling**
```bash
# Run in profile mode
flutter run --profile

# Performance monitoring
flutter run --trace-startup --profile
```

## 🐛 **Troubleshooting**

### **Issue: Flutter Doctor Shows Problems**
```bash
# Run doctor to see issues
flutter doctor

# Common fixes:
flutter doctor --android-licenses  # Accept Android licenses
xcode-select --install             # Install Xcode command line tools (macOS)
```

### **Issue: Dependencies Not Found**
```bash
# Clear and reinstall packages
flutter clean
flutter pub get

# If persistent issues:
rm pubspec.lock
flutter pub get
```

### **Issue: No Devices Available**
```bash
# For Android: Start emulator
flutter emulators --launch Pixel_7_API_34

# For iOS: Open simulator (macOS only)
open -a Simulator

# For physical device: Check USB debugging/trust settings
```

### **Issue: Build Failures**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# For Android build issues:
cd android
./gradlew clean
cd ..
flutter run

# For iOS build issues (macOS only):
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
flutter run
```

### **Issue: WebView Not Loading**
**Solution**: Check internet and widget configuration
1. Verify internet connection on device/simulator
2. Check widget UID in configuration: `232d2602-7cbd-4f6a-87eb-21058599d594`
3. Monitor Flutter console for detailed error logs

### **Issue: Hot Reload Not Working**
**Solution**: Restart development server
```bash
# Stop current session (q)
q

# Start fresh session
flutter run
```

## 📊 **Debug Console Output**

### **Flutter Console Logs**
In your terminal, you'll see:
```
flutter: [YourGPTSDK] Initializing with widgetUid: 232d2602-7cbd-4f6a-87eb-21058599d594
flutter: 🚀 SDK initialized successfully
flutter: 📱 WebView loaded successfully
flutter: 🔗 Connection established
flutter: ⌨️ User started typing
flutter: 📨 Message received: {...}
flutter: 👨‍💼 Escalated to human agent
```

### **Enable Debug Logging**
In `lib/main.dart` or configuration:
```dart
YourGPTConfig config = YourGPTConfig(
  widgetUid: 'your-widget-uid',
  debug: true,  // Enable detailed logging
);
```

## 🎯 **Testing Features**

### **Test SDK Initialization**
1. Launch app
2. Watch status indicator change from loading to ready
3. Verify chat button becomes enabled

### **Test Chat Functionality**
1. Tap chat button when SDK is ready
2. Verify full-screen WebView opens
3. Check console for data injection logs
4. Test back navigation

### **Test Hot Reload** (Development)
1. Make a UI change (change text color, etc.)
2. Press `r` in terminal
3. See changes apply instantly
4. Verify app state is preserved

### **Test Data Management**
1. Monitor console during chat launch
2. Verify session, visitor, and contact data injection
3. Check Flutter/Dart-specific data enrichment
4. Test different device orientations

### **Test Error Handling**
1. Disconnect internet
2. Launch app to see error states
3. Reconnect and test retry functionality
4. Verify error UI follows Material Design

## 📂 **Flutter Project Structure**

```
flutter-sdk/
├── pubspec.yaml                    # Dependencies and project config
├── lib/
│   ├── main.dart                   # App entry point
│   ├── config.dart                 # SDK configuration
│   ├── yourgpt_sdk_core.dart      # Core SDK functionality
│   ├── models/
│   │   └── sdk_state.dart         # State management models
│   ├── widgets/
│   │   ├── support_home_screen.dart    # Professional support UI
│   │   ├── chat_screen.dart           # WebView chat interface
│   │   └── status_card.dart           # Connection status widget
│   └── utils/
│       └── data_manager.dart       # Data injection utilities
├── android/                       # Android-specific configuration
├── ios/                           # iOS-specific configuration  
├── test/                          # Unit and widget tests
└── README.md                      # Flutter SDK documentation
```

## 🚀 **Alternative: VS Code Launch**

If using VS Code:

1. **Open Project**: `File` → `Open Folder` → Select `flutter-sdk`
2. **Install Extensions**: Flutter, Dart extensions
3. **Open Command Palette**: `Cmd+Shift+P` (macOS) or `Ctrl+Shift+P` (Windows/Linux)
4. **Run**: Type "Flutter: Launch Emulator" → Select device
5. **Debug**: Press `F5` or use Debug panel

## 📱 **Platform-Specific Features**

### **Android Features**
- **Material Design 3**: Modern Android UI patterns
- **Adaptive Icons**: Proper launcher icon handling
- **Navigation**: System back button integration
- **Permissions**: Camera, storage permissions for advanced features

### **iOS Features** (when running on iOS)
- **Cupertino Widgets**: iOS-style components where appropriate
- **Navigation**: iOS-style navigation patterns
- **Safe Area**: Proper iPhone notch/Dynamic Island handling
- **iOS Permissions**: iOS-specific permission dialogs

## ✅ **Success Checklist**

After successful setup:
- [ ] `flutter doctor` shows no critical issues
- [ ] Device/simulator is available and connected
- [ ] App launches with Flutter support home screen
- [ ] SDK status card shows connection progress
- [ ] Chat functionality works when ready
- [ ] Hot reload works during development
- [ ] Console shows detailed debug logging
- [ ] Data injection works properly

---

**Once running, you'll have a beautiful Flutter app demonstrating modern mobile SDK capabilities with Material Design, comprehensive data management, and cross-platform compatibility!** 🎉