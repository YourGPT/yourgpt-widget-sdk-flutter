# YourGPT Flutter SDK - Internal Developer Documentation

## Architecture Overview

The Flutter SDK employs a clean architecture pattern with separation between the core SDK logic and UI components:

```
YourGPTSDK (Singleton Core)
├── State management via Streams
├── Configuration validation
├── Event-driven communication
└── Widget URL generation

YourGPTChatScreen (StatefulWidget)
├── Lifecycle management
├── WebView integration
├── Error handling & loading states
└── Bridge communication
```

## Core Components

### 1. YourGPTSDK (Singleton)

**Location**: `lib/yourgpt_sdk.dart`

**Purpose**: Central SDK management with reactive state handling

**Architecture Patterns**:
- Singleton pattern for global state consistency
- Stream-based reactive programming
- Event-driven loose coupling
- Future-based async operations

**State Management**:
```dart
enum YourGPTConnectionState { 
  disconnected, connecting, connected, error 
}

class YourGPTSDKState {
  final bool isInitialized;
  final bool isLoading;
  final String? error;
  final YourGPTConnectionState connectionState;
}
```

**Key Features**:
- `Stream<YourGPTSDKState>` for reactive state updates
- Immutable state objects with `copyWith` pattern
- Async initialization with proper error handling
- Event system for cross-component communication

**Initialization Flow**:
1. `initialize(config)` called with `YourGPTConfig`
2. State transitions: `disconnected` → `connecting`
3. Widget validation (simulated API call)
4. Success: `connected` | Failure: `error`
5. Events emitted for state changes

### 2. YourGPTConfig

**Purpose**: Immutable configuration object

**Features**:
- Strongly typed with enum for theme
- Built-in URL parameter generation
- Default value handling
- Debug mode support

```dart
class YourGPTConfig {
  final String widgetUid;        // Required
  final String baseUrl;          // Default: https://yourgpt.ai
  final String? userId;          // Optional
  final String? authToken;       // Optional
  final YourGPTTheme theme;      // Default: light
  final bool debug;              // Default: false
}
```

### 3. YourGPTChatScreen (StatefulWidget)

**Location**: `lib/yourgpt_chat_screen.dart`

**Purpose**: WebView wrapper with enhanced functionality

**Component Lifecycle**:
```
initState()
    ↓
_initializeSDK()
    ↓ (async)
SDK.initialize() → Success/Error
    ↓
_initializeWebView() (if success)
    ↓
WebView.loadRequest()
    ↓
Bridge communication established
```

**State Variables**:
- `_isSDKReady`: SDK initialization completion
- `_isLoading`: Loading state for UI feedback
- `_error`: Error message for display

**UI State Management**:
- Loading widget: Custom or default circular progress
- Error widget: Custom or default error display
- Success state: WebView with full functionality

## Communication Architecture

### Event System
```dart
// SDK-level events
sdk.on('sdk:initialized', callback);
sdk.on('sdk:stateChanged', callback);
sdk.on('sdk:error', callback);
sdk.on('sdk:userContextSet', callback);
sdk.on('sdk:configUpdated', callback);
```

### Bridge Communication
```dart
// Flutter → JavaScript
controller.runJavaScript('window.postMessage(...)')

// JavaScript → Flutter
JavaScriptChannel('YourGPTNative', 
  onMessageReceived: (message) => _handleMessage(message.message)
)
```

### WebView Integration
```dart
WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..setNavigationDelegate(NavigationDelegate(...))
  ..addJavaScriptChannel('YourGPTNative', ...)
  ..loadRequest(Uri.parse(url))
```

## Error Handling Strategy

### Layered Error Handling
1. **SDK Level**: Initialization, validation, network errors
2. **WebView Level**: Page loading, resource errors
3. **Component Level**: State management, lifecycle errors
4. **Bridge Level**: Communication, parsing errors

### Error Propagation Flow
```
Error Source
    ↓
Internal Error Handling
    ↓
State Update (setState)
    ↓
UI Callback (onError)
    ↓
User Interface Display
```

### Error Types
- `ArgumentError`: Invalid configuration
- `StateError`: SDK not ready/initialized
- `WebResourceError`: WebView loading failures
- `FormatException`: JSON parsing errors

## Performance Considerations

### Memory Management
- Singleton pattern prevents multiple SDK instances
- Proper Stream controller disposal
- WebView lifecycle management
- Event listener cleanup

### Async Operations
- Future-based initialization with proper error handling
- Non-blocking UI during SDK setup
- Progressive loading states
- Graceful degradation on errors

### Widget Lifecycle
```dart
initState() → Setup listeners and initialize
build() → Reactive UI based on state
dispose() → Cleanup resources (if needed)
```

## State Synchronization

### Reactive State Updates
```dart
StreamController<YourGPTSDKState> _stateController;

// State changes automatically propagate
_setState(newState) {
  _state = newState;
  _stateController.add(_state);
  _emit('sdk:stateChanged', _state);
}
```

### Component State Coordination
- SDK state drives component behavior
- Loading states prevent premature WebView creation
- Error states block normal operation flow
- Ready state enables full functionality

## Debug & Development Features

### Debug Mode
```dart
YourGPTConfig(debug: true) // Enables verbose logging
```

### Development Tools
- `debugPrint` statements for state transitions
- Stream monitoring for state changes
- Error callback integration
- Console logging for bridge communication

### Testing Hooks
```dart
// Access SDK for testing
final sdk = YourGPTSDK.instance;
print('Current State: ${sdk.state}');
print('Is Ready: ${sdk.isReady}');
```

## Extension Points

### Custom UI Components
```dart
YourGPTChatScreen(
  customLoadingWidget: MyCustomLoader(),
  customErrorWidget: (error) => MyErrorDisplay(error),
)
```

### Event Handling
```dart
// Custom event handlers
sdk.on('custom:event', (data) => handleCustomEvent(data));
```

### Configuration Extensions
- Theme customization
- Additional URL parameters
- Custom base URLs
- Environment-specific settings

## Testing Strategy

### Unit Testing
- SDK initialization logic
- Configuration validation
- URL building functions
- Event system functionality
- State management

### Widget Testing
- Component rendering in different states
- Loading state display
- Error state handling
- WebView integration
- User interaction

### Integration Testing
- End-to-end initialization flow
- Bridge communication
- Error recovery
- Performance under load

### Manual Testing Checklist
- [ ] SDK initializes with valid configuration
- [ ] Loading states display correctly
- [ ] Error states show appropriate messages
- [ ] WebView loads and communicates
- [ ] Multiple screen transitions work
- [ ] Memory usage remains stable

## Build & Deployment

### Dependencies
```yaml
dependencies:
  flutter: sdk
  webview_flutter: ^4.4.2

dev_dependencies:
  flutter_test: sdk
  flutter_lints: ^2.0.0
```

### Platform Requirements
- **Android**: API 21+ (WebView support)
- **iOS**: iOS 11+ (WKWebView support)

### Release Process
1. Version bump in `pubspec.yaml`
2. Update CHANGELOG.md
3. Test on both platforms
4. Publish to pub.dev
5. Update documentation

## Common Issues & Solutions

### WebView Not Loading
- Check internet permissions
- Verify widget URL validity
- Test with debug mode enabled

### SDK Initialization Fails
- Validate widgetUid format
- Check network connectivity
- Review error callback messages

### Bridge Communication Issues
- Ensure JavaScript injection timing
- Verify message format
- Check channel name consistency

### Memory Leaks
- Proper disposal of streams
- WebView cleanup on navigation
- Event listener management