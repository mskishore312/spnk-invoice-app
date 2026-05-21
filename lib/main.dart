import 'package:flutter/material.dart';
import 'screens/invoice_form.dart';

void main() => runApp(const SpnkInvoiceApp());

class SpnkInvoiceApp extends StatelessWidget {
  const SpnkInvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPNK Invoice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B5E20),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SPNK Granites'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long, size: 80, color: Color(0xFF1B5E20)),
              const SizedBox(height: 20),
              const Text('SPNK GRANITES', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              const Text('Invoice Generator', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
