import 'package:flutter/material.dart';
import 'package:yourgpt_flutter_sdk/yourgpt_flutter_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YourGPT Flutter SDK Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey _chatKey = GlobalKey();
  String _sdkStatus = 'Not initialized';

  @override
  void initState() {
    super.initState();
    _setupSDKListeners();
  }

  void _setupSDKListeners() {
    final sdk = YourGPTSDK.instance;
    
    sdk.on('sdk:stateChanged', (YourGPTSDKState state) {
      setState(() {
        _sdkStatus = state.connectionState.name;
      });
    });

    sdk.on('sdk:error', (String error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SDK Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _openChatbot() {
    YourGPTChatScreen.showAsBottomSheet(
      context: context,
      widgetUid: 'your-widget-uid',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YourGPT Flutter SDK Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'SDK Status: $_sdkStatus',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tap the button to open the chatbot:',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openChatbot,
              child: const Text('Open Chatbot'),
            ),
          ],
        ),
      ),
    );
  }
}