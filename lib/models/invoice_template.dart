import 'package:pdf/pdf.dart';

enum InvoiceStyle {
  classic,
  modern,
  minimalist,
  corporate,
  elegant,
}

class InvoiceTemplate {
  final InvoiceStyle style;
  final String name;
  final String description;
  final PdfColor primaryColor;
  final PdfColor secondaryColor;
  final PdfColor textOnPrimary;
  final PdfColor bodyText;
  final PdfColor borderColor;
  final PdfColor altRowColor;

  const InvoiceTemplate({
    required this.style,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textOnPrimary,
    required this.bodyText,
    required this.borderColor,
    required this.altRowColor,
  });

  static const classic = InvoiceTemplate(
    style: InvoiceStyle.classic,
    name: 'Classic',
    description: 'Navy blue headers, full borders',
    primaryColor: PdfColor.fromInt(0xFF1F4E79),
    secondaryColor: PdfColor.fromInt(0xFFD6E4F0),
    textOnPrimary: PdfColor.fromInt(0xFFFFFFFF),
    bodyText: PdfColor.fromInt(0xFF000000),
    borderColor: PdfColor.fromInt(0xFF000000),
    altRowColor: PdfColor.fromInt(0xFFF2F7FB),
  );

  static const modern = InvoiceTemplate(
    style: InvoiceStyle.modern,
    name: 'Modern',
    description: 'Bold sidebar, clean layout',
    primaryColor: PdfColor.fromInt(0xFF2D5F2D),
    secondaryColor: PdfColor.fromInt(0xFFE8F5E9),
    textOnPrimary: PdfColor.fromInt(0xFFFFFFFF),
    bodyText: PdfColor.fromInt(0xFF333333),
    borderColor: PdfColor.fromInt(0xFFCCCCCC),
    altRowColor: PdfColor.fromInt(0xFFF9F9F9),
  );

  static const minimalist = InvoiceTemplate(
    style: InvoiceStyle.minimalist,
    name: 'Minimalist',
    description: 'Black & white, thin lines',
    primaryColor: PdfColor.fromInt(0xFF000000),
    secondaryColor: PdfColor.fromInt(0xFFF5F5F5),
    textOnPrimary: PdfColor.fromInt(0xFFFFFFFF),
    bodyText: PdfColor.fromInt(0xFF1A1A1A),
    borderColor: PdfColor.fromInt(0xFFDDDDDD),
    altRowColor: PdfColor.fromInt(0xFFFAFAFA),
  );

  static const corporate = InvoiceTemplate(
    style: InvoiceStyle.corporate,
    name: 'Corporate',
    description: 'Dark banner, grey rows',
    primaryColor: PdfColor.fromInt(0xFF263238),
    secondaryColor: PdfColor.fromInt(0xFFECEFF1),
    textOnPrimary: PdfColor.fromInt(0xFFFFFFFF),
    bodyText: PdfColor.fromInt(0xFF37474F),
    borderColor: PdfColor.fromInt(0xFFB0BEC5),
    altRowColor: PdfColor.fromInt(0xFFF5F5F5),
  );

  static const elegant = InvoiceTemplate(
    style: InvoiceStyle.elegant,
    name: 'Elegant',
    description: 'Dark theme, gold accents',
    primaryColor: PdfColor.fromInt(0xFF1A1A2E),
    secondaryColor: PdfColor.fromInt(0xFFD4AF37),
    textOnPrimary: PdfColor.fromInt(0xFFD4AF37),
    bodyText: PdfColor.fromInt(0xFF2C2C2C),
    borderColor: PdfColor.fromInt(0xFFD4AF37),
    altRowColor: PdfColor.fromInt(0xFFFFF8E7),
  );

  static const List<InvoiceTemplate> all = [classic, modern, minimalist, corporate, elegant];
}
