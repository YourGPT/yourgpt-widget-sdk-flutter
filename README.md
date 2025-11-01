# YourGPT Flutter SDK

A Flutter package for integrating the YourGPT chatbot widget in your Flutter applications. The SDK displays the chat in a modal bottom sheet with swipe-to-dismiss functionality and an integrated close button.

## Overview

The YourGPT Flutter SDK provides a seamless way to integrate YourGPT's conversational AI chatbot into your Flutter apps. It uses a WebView-based approach with a bidirectional JavaScript bridge for native communication, offering full customization and event-driven callbacks.

### Key Features

- **Bottom Sheet Display**: Native mobile-style bottom sheet presentation (recommended)
- **Full-Screen Chat Interface**: Alternative full-screen mode available
- **Integrated Close Button**: Widget includes a built-in close button that communicates with the SDK
- **Swipe-to-Dismiss**: Native gesture support for closing the bottom sheet
- **Bidirectional Communication**: JavaScript ↔ Dart bridge for seamless message passing
- **Event-Driven Architecture**: Callbacks for messages, chat state changes, and errors
- **Customizable UI**: Custom loading and error widgets
- **User Context Management**: Set user data dynamically through the bridge
- **State Management**: Built-in SDK state tracking with Stream support
- **Singleton Pattern**: Single SDK instance across your app
- **Simple Configuration**: Only widget UID required to get started

## Architecture

The SDK consists of four main layers:

### 1. Configuration Layer (`config.dart`)
Manages SDK configuration, endpoint URLs, and parameter building:
- **YourGPTConfig**: Main configuration class with widget UID (required) and optional debug mode
- **YourGPTConfigBuilder**: Builds complete widget URLs with query parameters
- **YourGPTSDKConfig**: Constants for endpoints and SDK metadata

### 2. Core SDK Layer (`yourgpt_sdk.dart`)
Singleton SDK instance that handles:
- SDK initialization and validation
- State management with Stream support
- Event system for publish-subscribe communication
- Widget URL generation
- User context updates

### 3. UI Layer (`yourgpt_chat_screen.dart`)
Flutter widget that provides:
- WebView integration for loading YourGPT widget
- JavaScript bridge setup for native communication
- Loading and error state handling
- Customizable UI components
- Public methods for programmatic control (sendMessage, setUserContext, openChat)

### 4. Public API (`yourgpt_flutter_sdk.dart`)
Single entry point that exports all public interfaces

## How It Works

### Initialization Flow

1. **Widget Creation**: User creates `YourGPTChatScreen` with required `widgetUid`
2. **SDK Initialization**: SDK validates configuration and connects
3. **URL Building**: Constructs widget URL with SDK metadata and mobileWebView=true parameter
4. **WebView Loading**: Loads YourGPT widget in WebView
5. **JavaScript Bridge Setup**: Injects JavaScript to enable native communication
6. **Event Handling**: Widget messages trigger Dart callbacks

### Communication Flow

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│   Flutter App   │ ←──────→│   YourGPT SDK    │ ←──────→│  WebView/Widget │
│   (Your Code)   │  Dart   │  (Bridge Layer)  │   JS    │  (YourGPT Chat) │
└─────────────────┘         └──────────────────┘         └─────────────────┘
       ↓                             ↓                            ↓
  Callbacks              State Management              postMessage Events
```

**Dart → JavaScript** (Native to Web):
- `sendMessage()`: Send messages to chatbot
- `setUserContext()`: Update user information
- `openChat()`: Programmatically open chat

**JavaScript → Dart** (Web to Native):
- `message:new`: New message received from chatbot
- `chat:opened`: Chat interface opened
- `chat:closed`: Chat interface closed
- `chatbot-close`: Close button clicked in widget (closes bottom sheet)

## Requirements

- **Flutter**: 3.13 or newer
- **Dart**: 3.0 or newer
- **Android**: minSdk 21+, compileSdk 33+ (or your project default)
- **iOS**: iOS 12.0+

Note: Internet/network permissions are required. See the Permissions section below for platform-specific details.

## Quick Start

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  yourgpt_flutter_sdk: ^1.0.0
  webview_flutter: ^4.4.2
```

Then run:
```bash
flutter pub get
```

### Development Environment Setup

For local development and testing, see [DEV_SETUP.md](./DEV_SETUP.md) for detailed instructions on:
- Setting up Flutter development environment
- Running the example app locally
- Platform-specific configurations (iOS/Android)
- Debugging and testing the SDK
- Using Flutter DevTools and platform debugging tools

## Usage

### Basic Usage (Bottom Sheet - Recommended)

The recommended way to display the YourGPT chat is in a bottom sheet. This provides a native mobile experience with swipe-to-dismiss functionality. The widget includes an integrated close button that communicates with the SDK to dismiss the bottom sheet.

```dart
import 'package:yourgpt_flutter_sdk/yourgpt_flutter_sdk.dart';

// Show chatbot in a bottom sheet (recommended)
YourGPTChatScreen.showAsBottomSheet(
  context: context,
  widgetUid: 'your-widget-uid', // Required: Your YourGPT widget UID
);
```

### Alternative: Full-Screen Usage

You can also use the widget in full-screen mode if needed:

```dart
import 'package:yourgpt_flutter_sdk/yourgpt_flutter_sdk.dart';

// Full-screen navigation (alternative approach)
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => Scaffold(
      body: SafeArea(
        child: YourGPTChatScreen(
          widgetUid: 'your-widget-uid',
        ),
      ),
    ),
  ),
);
```

### Advanced Usage with SDK Listeners

Monitor SDK state changes and handle events globally:

```dart
import 'package:yourgpt_flutter_sdk/yourgpt_flutter_sdk.dart';

void setupSDK() {
  final sdk = YourGPTSDK.instance;

  // Listen to SDK state changes
  sdk.stateStream.listen((YourGPTSDKState state) {
    print('SDK State: ${state.connectionState}');
    print('Initialized: ${state.isInitialized}');
    print('Loading: ${state.isLoading}');
    if (state.error != null) {
      print('Error: ${state.error}');
    }
  });

  // Listen to SDK events
  sdk.on('sdk:initialized', (config) {
    print('SDK initialized with widget: ${config.widgetUid}');
  });

  sdk.on('sdk:error', (error) {
    print('SDK error: $error');
  });

  sdk.on('sdk:stateChanged', (state) {
    print('State changed to: ${state.connectionState.name}');
  });
}
```

### Bottom Sheet Customization

The bottom sheet can be customized with various options:

```dart
YourGPTChatScreen.showAsBottomSheet(
  context: context,
  widgetUid: 'your-widget-uid',
  isDismissible: true,         // Allow tapping outside to dismiss (default: true)
  enableDrag: true,            // Allow dragging to dismiss (default: true)
  onChatClosed: () {
    print('Bottom sheet closed');
  },
);
```

### Close Button Behavior

- The close button is integrated within the widget UI itself
- When clicked, the widget sends a `chatbot-close` event to the SDK
- The SDK receives this event and automatically closes the bottom sheet
- This provides a seamless user experience with proper communication between the widget and native app

### Custom Loading and Error Widgets

```dart
YourGPTChatScreen(
  widgetUid: 'your-widget-uid',
  customLoadingWidget: Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text('Loading your assistant...'),
        ],
      ),
    ),
  ),
  customErrorWidget: (error) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text('Failed to load: $error'),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Go Back'),
          ),
        ],
      ),
    ),
  ),
  onLoading: (isLoading) {
    print('Chat loading: $isLoading');
  },
  onError: (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  },
)
```

### YourGPTSDK Methods

Access the SDK singleton instance: `YourGPTSDK.instance`

#### State Management

```dart
// Get current SDK state
YourGPTSDKState state = sdk.state;
print('Is Ready: ${sdk.isReady}');
print('Is Initialized: ${state.isInitialized}');
print('Connection: ${state.connectionState}');

// Listen to state stream
sdk.stateStream.listen((state) {
  // Handle state changes
});
```

#### Event System

```dart
// Register event listener
sdk.on('sdk:initialized', (config) {
  print('SDK initialized');
});

// Remove event listener
sdk.off('sdk:initialized', callback);
```

#### Available Events:
- `sdk:initialized` - SDK initialization complete
- `sdk:error` - SDK error occurred
- `sdk:stateChanged` - SDK state changed
- `sdk:configUpdated` - Configuration updated
- `sdk:userContextSet` - User context updated

### YourGPTChatScreen Methods

You can interact with the chatbot programmatically using a GlobalKey:

```dart
final GlobalKey<YourGPTChatScreenState> chatKey = GlobalKey();

// Use the key when creating the widget
YourGPTChatScreen(
  key: chatKey,
  widgetUid: 'your-widget-uid',
)

// Send a message programmatically
chatKey.currentState?.sendMessage('Hello! How can I help?');

// Set user context data
chatKey.currentState?.setUserContext({
  'name': 'John Doe',
  'email': 'john@example.com',
  'plan': 'premium',
  'customData': 'any-value'
});

// Open chat programmatically
chatKey.currentState?.openChat();
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:yourgpt_flutter_sdk/yourgpt_flutter_sdk.dart';

class ChatExample extends StatefulWidget {
  @override
  State<ChatExample> createState() => _ChatExampleState();
}

class _ChatExampleState extends State<ChatExample> {
  final GlobalKey<YourGPTChatScreenState> _chatKey = GlobalKey();

  void _openChatWithContext() {
    YourGPTChatScreen.showAsBottomSheet(
      context: context,
      widgetUid: 'your-widget-uid',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _openChatWithContext,
      child: Text('Open Chat'),
    );
  }
}
```

## Permissions

### Android

Add internet permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS

No permissions needed.

## Events

### WebView to Native Events (JavaScript → Dart)

The YourGPT widget sends these events through the JavaScript bridge:

| Event | Data Type | Description |
|-------|-----------|-------------|
| `message:new` | `Map<String, dynamic>` | New message received from chatbot |
| `chat:opened` | - | Chat interface opened by user |
| `chat:closed` | - | Chat interface closed by user |
| `chatbot-close` | - | Close button clicked in widget (closes bottom sheet) |

### SDK Events (Internal)

SDK-level events you can listen to via `YourGPTSDK.instance.on()`:

| Event | Data Type | Description |
|-------|-----------|-------------|
| `sdk:initialized` | `YourGPTConfig` | SDK initialization completed |
| `sdk:error` | `String` | SDK encountered an error |
| `sdk:stateChanged` | `YourGPTSDKState` | SDK state changed |
| `sdk:configUpdated` | `YourGPTConfig` | Configuration updated |
| `sdk:userContextSet` | `Map<String, dynamic>` | User context was set |


## Best Practices

1. **Singleton Pattern**: The SDK uses a singleton pattern. Access it via `YourGPTSDK.instance`
2. **Error Handling**: Always implement `onError` callback for production apps
3. **Loading States**: Use `onLoading` callback or `customLoadingWidget` for better UX
4. **User Context**: Set user context dynamically using `setUserContext()` method for personalized experiences
5. **Event Cleanup**: Remove event listeners when no longer needed using `sdk.off()`
6. **State Management**: Listen to `stateStream` for reactive state updates
7. **Simple Configuration**: Only `widgetUid` is required - the SDK handles URL construction with mobileWebView=true parameter automatically

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write/update tests
5. Submit a pull request

## License

See [LICENSE](LICENSE) file for details.

## Support

- Documentation: [https://docs.yourgpt.ai](https://docs.yourgpt.ai)
- Issues: [GitHub Issues](https://github.com/yourgpt/flutter-sdk/issues)
- Email: support@yourgpt.ai