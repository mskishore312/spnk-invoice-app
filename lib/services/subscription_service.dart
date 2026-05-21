import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static const String _keyId = 'rzp_test_Ss55PZQbGZpQXL';
  static const String _keySecret = 'UxlK7LeUD5TFXXRhvH5jhgN7';
  static const String _monthlyPlanId = 'plan_Ss5BOOHWnS4XqF';
  static const String _yearlyPlanId = 'plan_Ss5BVGw1km3cPi';

  static String get keyId => _keyId;
  static String get monthlyPlanId => _monthlyPlanId;
  static String get yearlyPlanId => _yearlyPlanId;

  /// Create a subscription on Razorpay and return subscription_id
  static Future<String?> createSubscription({required bool isYearly}) async {
    final planId = isYearly ? _yearlyPlanId : _monthlyPlanId;
    final auth = base64Encode(utf8.encode('$_keyId:$_keySecret'));

    try {
      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/subscriptions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $auth',
        },
        body: jsonEncode({
          'plan_id': planId,
          'total_count': isYearly ? 5 : 60, // max billing cycles
          'quantity': 1,
          'customer_notify': 1,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save subscription status locally
  static Future<void> saveSubscription({
    required String subscriptionId,
    required String paymentId,
    required bool isYearly,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_subscribed', true);
    await prefs.setString('subscription_id', subscriptionId);
    await prefs.setString('payment_id', paymentId);
    await prefs.setBool('is_yearly', isYearly);
    await prefs.setString('subscribed_at', DateTime.now().toIso8601String());
  }

  /// Check if user has active subscription
  static Future<bool> isSubscribed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_subscribed') ?? false;
  }

  /// Get subscription details
  static Future<Map<String, String>> getDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'subscription_id': prefs.getString('subscription_id') ?? '',
      'payment_id': prefs.getString('payment_id') ?? '',
      'plan': (prefs.getBool('is_yearly') ?? false) ? 'Yearly' : 'Monthly',
      'subscribed_at': prefs.getString('subscribed_at') ?? '',
    };
  }
}
