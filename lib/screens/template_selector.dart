import 'package:flutter/material.dart';
import '../models/invoice_template.dart';
import 'invoice_form.dart';

class TemplateSelectorScreen extends StatelessWidget {
  const TemplateSelectorScreen({super.key});

  static const _templateColors = [
    [Color(0xFF1F4E79), Color(0xFFD6E4F0)], // Classic
    [Color(0xFF2D5F2D), Color(0xFFE8F5E9)], // Modern
    [Color(0xFF000000), Color(0xFFF5F5F5)], // Minimalist
    [Color(0xFF263238), Color(0xFFECEFF1)], // Corporate
    [Color(0xFF1A1A2E), Color(0xFFD4AF37)], // Elegant
  ];

  static const _templateIcons = [
    Icons.grid_on,
    Icons.view_agenda,
    Icons.remove,
    Icons.business,
    Icons.diamond,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Template'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: InvoiceTemplate.all.length,
        itemBuilder: (context, index) {
          final tmpl = InvoiceTemplate.all[index];
          final colors = _templateColors[index];
          return GestureDetector(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => InvoiceFormScreen(template: tmpl))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Row(children: [
                  // Color preview strip
                  Container(
                    width: 100,
                    color: colors[0],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_templateIcons[index], color: index == 4 ? const Color(0xFFD4AF37) : Colors.white, size: 32),
                        const SizedBox(height: 8),
                        Container(width: 40, height: 2, color: colors[1]),
                        const SizedBox(height: 4),
                        Container(width: 55, height: 2, color: colors[1].withAlpha(128)),
                        const SizedBox(height: 4),
                        Container(width: 30, height: 2, color: colors[1].withAlpha(77)),
                      ],
                    ),
                  ),
                  // Info
                  Expanded(child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(tmpl.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors[0])),
                        const SizedBox(height: 4),
                        Text(tmpl.description, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        const SizedBox(height: 10),
                        Row(children: [
                          Text('USE THIS TEMPLATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors[0])),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 14, color: colors[0]),
                        ]),
                      ],
                    ),
                  )),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
