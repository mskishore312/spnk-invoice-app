import 'package:flutter/material.dart';
import 'screens/invoice_form.dart';
import 'screens/subscription_screen.dart';
import 'services/subscription_service.dart';

void main() => runApp(const KanakkuPullaApp());

class KanakkuPullaApp extends StatelessWidget {
  const KanakkuPullaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanakku Pulla',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B5E20),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/subscribe': (context) => const SubscriptionScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final subscribed = await SubscriptionService.isSubscribed();
    if (subscribed) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/subscribe');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.receipt_long, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text('Kanakku Pulla', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Smart Invoice Generator', style: TextStyle(fontSize: 16, color: Colors.white.withAlpha(179))),
          const SizedBox(height: 40),
          const CircularProgressIndicator(color: Colors.white),
        ],
      )),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanakku Pulla'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.card_membership),
            onPressed: () async {
              final details = await SubscriptionService.getDetails();
              if (!context.mounted) return;
              showDialog(context: context, builder: (_) => AlertDialog(
                title: const Text('Subscription'),
                content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Plan: ${details["plan"]}'),
                  Text('Since: ${details["subscribed_at"]?.substring(0, 10) ?? "N/A"}'),
                  Text('ID: ${details["subscription_id"]}'),
                ]),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
              ));
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long, size: 80, color: Color(0xFF1B5E20)),
              const SizedBox(height: 20),
              const Text('KANAKKU PULLA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              const Text('Smart Invoice Generator', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 28),
                  label: const Text('CREATE NEW INVOICE', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const InvoiceFormScreen())),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
