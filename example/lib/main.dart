// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:yourgpt_flutter_sdk/yourgpt_flutter_sdk.dart';
import 'firebase_options.dart';

const String _widgetUid = 'yourgpt-widget-uid';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Push notifications ───────────────────────────────────────────────────
  //
  // iOS:     Uses native APNs via MethodChannel (no Firebase needed).
  // Android: Uses Firebase Cloud Messaging.

  // Android: Initialize Firebase (FCM).
  // iOS: Uses native APNs via MethodChannel — no Firebase needed.
  if (defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(yourgptFirebaseBackgroundHandler);
  }

  // ─────────────────────────────────────────────────────────────────────────

  runApp(const MyApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// App
// ─────────────────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SecureBank — YourGPT Demo',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E3A5F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A5F),
          primary: const Color(0xFF1E3A5F),
          secondary: const Color(0xFF4A90E2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A5F),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const BankingApp(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BankingApp — root with bottom navigation
// ─────────────────────────────────────────────────────────────────────────────

class BankingApp extends StatefulWidget {
  const BankingApp({Key? key}) : super(key: key);

  @override
  State<BankingApp> createState() => _BankingAppState();
}

class _BankingAppState extends State<BankingApp>
    implements YourGPTEventListener {
  int _selectedIndex = 2; // Start on Support tab

  // ── Controller — lets us call methods from outside the chat widget ─────────
  final YourGPTChatController _chatController = YourGPTChatController();

  @override
  void initState() {
    super.initState();
    _setupSDK();
  }

  Future<void> _setupSDK() async {
    final sdk = YourGPTSDK.instance;

    // Initialize notification client (APNs on iOS, FCM on Android).
    // Must happen AFTER runApp() so the UI is rendered before any
    // permission dialogs appear (iOS watchdog kills the app otherwise).
    await YourGPTNotificationClient.instance.initialize(
      widgetUid: _widgetUid,
      mode: NotificationMode.minimalist,
      config: const YourGPTNotificationConfig(
        quietHoursEnabled: true,
        quietHoursStart: 22,
        quietHoursEnd: 8,
      ),
    );

    // Register this screen as the global event listener.
    sdk.setEventListener(this);
    YourGPTNotificationClient.instance.setEventListener(this);

    // Also subscribe to the raw event stream for reactive UI updates.
    sdk.on('sdk:stateChanged', (YourGPTSDKState state) {
      if (mounted) setState(() {});
    });

    sdk.on('sdk:error', (String error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SDK Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  // ── Open chat ──────────────────────────────────────────────────────────────

  void _openChat() {
    YourGPTChatScreen.showAsBottomSheet(
      context: context,
      widgetUid: _widgetUid,
      controller: _chatController,
      eventListener: this,
      debug: false,
      onChatOpened: () => print('[App] Chat opened'),
      onChatClosed: () => print('[App] Chat closed'),
      onMessage: (msg) => print('[App] Message received: $msg'),
      onConnectionEstablished: () => print('[App] Connection established'),
      onConnectionLost: (reason) => print('[App] Connection lost: $reason'),
      onTyping: () => print('[App] Bot typing…'),
      onEscalationToHuman: () => print('[App] Escalated to human agent'),
    );

    // After opening, send user context (typically comes from your auth system).
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_chatController.isAttached) {
        _chatController.setContactData({
          'email': 'john.doe@email.com',
          'phone': '+1-555-0100',
        });
        _chatController.setVisitorData({
          'name': 'John Doe',
          'accountType': 'Premium',
        });
        _chatController.setSessionData({
          'accountId': 'ACC-12345',
          'plan': 'Premium Banking',
        });
      }
    });
  }

  // ── YourGPTEventListener —————————————————————————————————————————————————

  @override
  void onMessageReceived(Map<String, dynamic> message) {
    print('[Listener] Message received: $message');
  }

  @override
  void onChatOpened() => print('[Listener] Chat opened');

  @override
  void onChatClosed() => print('[Listener] Chat closed');

  @override
  void onError(String error) => print('[Listener] Error: $error');

  @override
  void onLoadingStarted() => print('[Listener] Loading started');

  @override
  void onLoadingFinished() => print('[Listener] Loading finished');

  @override
  void onConnectionEstablished() => print('[Listener] Connected');

  @override
  void onConnectionLost({String? reason}) =>
      print('[Listener] Connection lost: $reason');

  @override
  void onConnectionRestored() => print('[Listener] Connection restored');

  @override
  void onUserTyping() => print('[Listener] Bot typing…');

  @override
  void onEscalationToHuman() => print('[Listener] Escalated to human');

  @override
  void onEscalationResolved() => print('[Listener] Escalation resolved');

  @override
  void onUserStoppedTyping() => print('[Listener] Bot stopped typing');

  @override
  void onMessageSent(Map<String, dynamic> message) =>
      print('[Listener] Message sent: $message');

  @override
  void onPushTokenReceived(String token) =>
      print('[Listener] Push token: $token');

  @override
  void onPushMessageReceived(Map<String, dynamic> data) =>
      print('[Listener] Push message received: $data');

  @override
  void onNotificationPermissionGranted() =>
      print('[Listener] Notification permission granted');

  @override
  void onNotificationPermissionDenied() =>
      print('[Listener] Notification permission denied');

  @override
  void onNotificationClicked(Map<String, dynamic> data) {
    print('[Listener] Notification clicked: $data');
    final sessionUid = data['session_uid'] as String?;
    if (sessionUid != null && mounted) {
      // Close any existing widget bottom sheet before opening a new one.
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      YourGPTChatScreen.openSession(
        context: context,
        widgetUid: _widgetUid,
        sessionUid: sessionUid,
        controller: _chatController,
        eventListener: this,
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const CardsScreen(),
      SupportScreen(onChatPressed: _openChat),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: const Color(0xFF1E3A5F),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_rounded),
            label: 'Cards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent_rounded),
            label: 'Support',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screens
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: false,
            backgroundColor: const Color(0xFF1E3A5F),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A5F), Color(0xFF2E5A8F)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Good Morning,',
                          style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const Text('John Doe',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Balance',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                            SizedBox(height: 4),
                            Text('\$24,563.89',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F))),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _quickAction(Icons.send_rounded, 'Transfer',
                          const Color(0xFF4A90E2)),
                      _quickAction(Icons.payment_rounded, 'Pay Bills',
                          const Color(0xFF50C878)),
                      _quickAction(Icons.account_balance_wallet_rounded,
                          'Deposit', const Color(0xFF9B59B6)),
                      _quickAction(Icons.qr_code_scanner_rounded, 'Scan QR',
                          const Color(0xFFFF6B6B)),
                      _quickAction(
                          Icons.savings_rounded, 'Savings', const Color(0xFFFFB347)),
                      _quickAction(
                          Icons.more_horiz_rounded, 'More', const Color(0xFF95A5A6)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Recent Transactions',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F))),
                  const SizedBox(height: 16),
                  _txItem('Grocery Store', 'Payment', '-\$125.50', 'Today',
                      Icons.shopping_cart_rounded, true),
                  _txItem('Salary Credit', 'Income', '+\$5,250.00', 'Yesterday',
                      Icons.account_balance_rounded, false),
                  _txItem('Electric Bill', 'Utilities', '-\$89.00', '2 days ago',
                      Icons.bolt_rounded, true),
                  _txItem('Restaurant', 'Food & Dining', '-\$45.80', '3 days ago',
                      Icons.restaurant_rounded, true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _txItem(String title, String subtitle, String amount, String date,
      IconData icon, bool isExpense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isExpense ? Colors.red : Colors.green).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon,
                color: isExpense ? Colors.red : Colors.green, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isExpense ? Colors.red : Colors.green)),
              Text(date,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class CardsScreen extends StatelessWidget {
  const CardsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cards & Payments')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_rounded, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Your Cards',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text('Manage your debit and credit cards',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

class SupportScreen extends StatelessWidget {
  final VoidCallback onChatPressed;

  const SupportScreen({Key? key, required this.onChatPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support Center'), elevation: 0),
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF4A90E2), Color(0xFF6BA3F5)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.headset_mic_rounded,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text('How can we help you today?',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Get instant support from our AI assistant',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: onChatPressed,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_rounded,
                                    size: 20, color: Color(0xFF4A90E2)),
                                SizedBox(width: 8),
                                Text('Chat with AI Assistant',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4A90E2))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Frequently Asked Questions',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F))),
                  const SizedBox(height: 16),
                  _faqItem('How do I reset my password?',
                      'You can reset your password from the login screen or contact support.'),
                  _faqItem('How do I transfer money internationally?',
                      'Use the international transfer option in the Transfer menu.'),
                  _faqItem('What are the daily transfer limits?',
                      'Standard accounts have a daily limit of \$10,000 for transfers.'),
                  _faqItem('How do I dispute a transaction?',
                      'Go to transaction history and tap the transaction to dispute it.'),
                  const SizedBox(height: 24),
                  const Text('Other Support Options',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F))),
                  const SizedBox(height: 16),
                  _supportOption(Icons.phone_rounded, 'Call Us',
                      '1-800-SECURE', Colors.green),
                  _supportOption(Icons.email_rounded, 'Email Support',
                      'support@securebank.com', Colors.blue),
                  _supportOption(Icons.location_on_rounded, 'Visit Branch',
                      'Find nearest branch', Colors.orange),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(question,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(answer,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _supportOption(
      IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing:
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
        onTap: () {},
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF1E3A5F), width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.person_rounded,
                    size: 50, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            const Text('John Doe',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('john.doe@email.com',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Account: ****1234',
                style:
                    TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
