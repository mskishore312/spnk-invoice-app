import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late Razorpay _razorpay;
  bool _loading = false;
  bool _isYearly = false;
  String? _currentSubId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _subscribe(bool yearly) async {
    setState(() { _loading = true; _isYearly = yearly; });

    final subId = await SubscriptionService.createSubscription(isYearly: yearly);
    if (subId == null) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create subscription. Try again.')),
        );
      }
      return;
    }

    _currentSubId = subId;

    _razorpay.open({
      'key': SubscriptionService.keyId,
      'subscription_id': subId,
      'name': 'Kanakku Pulla',
      'description': yearly ? 'Yearly Plan - ₹3,999/yr' : 'Monthly Plan - ₹399/mo',
      'prefill': {'method': 'upi'},
      'theme': {'color': '#1B5E20'},
      'recurring': '1',
    });
  }

  void _onSuccess(PaymentSuccessResponse response) async {
    await SubscriptionService.saveSubscription(
      subscriptionId: _currentSubId ?? '',
      paymentId: response.paymentId ?? '',
      isYearly: _isYearly,
    );
    setState(() => _loading = false);
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  void _onError(PaymentFailureResponse response) {
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${response.message ?? "Unknown error"}')),
      );
    }
  }

  void _onWallet(ExternalWalletResponse response) {
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.receipt_long, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text('Kanakku Pulla', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              const SizedBox(height: 4),
              Text('Smart Invoice Generator', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 30),
              _featureItem(Icons.picture_as_pdf, 'GST-Compliant PDF Invoices'),
              _featureItem(Icons.calculate, 'Auto CBM Calculator'),
              _featureItem(Icons.share, 'Print & Share Instantly'),
              _featureItem(Icons.storage, 'Unlimited Invoices'),
              _featureItem(Icons.autorenew, 'UPI Autopay - Cancel Anytime'),
              const SizedBox(height: 30),
              _planCard(
                title: 'Monthly', price: '₹399', period: '/month',
                subtitle: 'Flexible monthly billing', highlight: false,
                onTap: () => _subscribe(false),
              ),
              const SizedBox(height: 12),
              _planCard(
                title: 'Yearly', price: '₹3,999', period: '/year',
                subtitle: 'Save 17% — just ₹333/month', highlight: true,
                onTap: () => _subscribe(true),
              ),
              const SizedBox(height: 20),
              if (_loading) const CircularProgressIndicator(color: Color(0xFF1B5E20)),
              const SizedBox(height: 16),
              Text('Powered by Razorpay • Secure UPI Autopay', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 20, color: const Color(0xFF1B5E20)),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 14)),
      ]),
    );
  }

  Widget _planCard({
    required String title, required String price, required String period,
    required String subtitle, required bool highlight, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFF1B5E20) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1B5E20), width: 2),
          boxShadow: highlight ? [BoxShadow(color: Colors.green.withAlpha(77), blurRadius: 12, offset: const Offset(0, 4))] : null,
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (highlight) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
              child: const Text('BEST VALUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: highlight ? Colors.white : const Color(0xFF1B5E20))),
            Text(subtitle, style: TextStyle(fontSize: 12, color: highlight ? Colors.white70 : Colors.grey)),
          ])),
          Column(children: [
            Text(price, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: highlight ? Colors.white : const Color(0xFF1B5E20))),
            Text(period, style: TextStyle(fontSize: 12, color: highlight ? Colors.white70 : Colors.grey)),
          ]),
        ]),
      ),
    );
  }
}
