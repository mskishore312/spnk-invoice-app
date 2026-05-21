import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/invoice.dart';

class PdfGenerator {
  static final _fmt = NumberFormat('#,##0', 'en_IN');
  static final _fmtDec = NumberFormat('#,##0.0', 'en_IN');

  // Colors matching the Google Sheets invoice
  static const _headerBg = PdfColor.fromInt(0xFF1F4E79);    // Dark blue header
  static const _headerText = PdfColor.fromInt(0xFFFFFFFF);   // White text
  static const _labelBg = PdfColor.fromInt(0xFFD6E4F0);     // Light blue labels
  static const _borderColor = PdfColor.fromInt(0xFF000000);  // Black borders
  static const _titleColor = PdfColor.fromInt(0xFF1F4E79);   // Dark blue title

  static String _amountInWords(double amount) {
    int amt = amount.round();
    if (amt == 0) return 'ZERO RUPEES ONLY.';
    final ones = ['', 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE',
      'TEN', 'ELEVEN', 'TWELVE', 'THIRTEEN', 'FOURTEEN', 'FIFTEEN', 'SIXTEEN', 'SEVENTEEN', 'EIGHTEEN', 'NINETEEN'];
    final tens = ['', '', 'TWENTY', 'THIRTY', 'FOURTY', 'FIFTY', 'SIXTY', 'SEVENTY', 'EIGHTY', 'NINETY'];
    String twoDigits(int n) {
      if (n < 20) return ones[n];
      return '${tens[n ~/ 10]} ${ones[n % 10]}'.trim();
    }
    String threeDigits(int n) {
      if (n >= 100) return '${ones[n ~/ 100]} HUNDRED AND ${twoDigits(n % 100)}'.trim();
      return twoDigits(n);
    }
    List<String> parts = [];
    if (amt >= 10000000) { parts.add('${twoDigits(amt ~/ 10000000)} CRORE'); amt %= 10000000; }
    if (amt >= 100000) { parts.add('${twoDigits(amt ~/ 100000)} LAKHS'); amt %= 100000; }
    if (amt >= 1000) { parts.add('${twoDigits(amt ~/ 1000)} THOUSAND'); amt %= 1000; }
    if (amt > 0) { parts.add(threeDigits(amt)); }
    return '${parts.join(' ')} RUPEES ONLY.';
  }

  static pw.Widget _headerCell(String text, {double width = 0, pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Container(
      width: width > 0 ? width : null,
      padding: const pw.EdgeInsets.all(2),
      color: _headerBg,
      child: pw.Text(text, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: _headerText), textAlign: align),
    );
  }

  static pw.Widget _labelCell(String text, {double width = 0, pw.TextAlign align = pw.TextAlign.left, double fontSize = 6.5}) {
    return pw.Container(
      width: width > 0 ? width : null,
      padding: const pw.EdgeInsets.all(2),
      color: _labelBg,
      child: pw.Text(text, style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold), textAlign: align),
    );
  }

  static pw.Widget _dataCell(String text, {double width = 0, pw.TextAlign align = pw.TextAlign.left, double fontSize = 6.5, bool bold = false}) {
    return pw.Container(
      width: width > 0 ? width : null,
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(text, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal), textAlign: align),
    );
  }

  static Future<Uint8List> generate(Invoice inv) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('M/d/yyyy');
    final border = pw.TableBorder.all(color: _borderColor, width: 0.5);
    final thinBorder = pw.TableBorder.all(color: _borderColor, width: 0.3);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ===== INVOICE TITLE =====
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                child: pw.Column(children: [
                  pw.Container(
                    color: _headerBg,
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    child: pw.Center(child: pw.Text('INVOICE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _headerText))),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                    child: pw.Center(child: pw.Text('ORIGINAL', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _titleColor))),
                  ),
                ]),
              ),
              pw.SizedBox(height: 3),

              // ===== SELLER + INVOICE INFO =====
              pw.Table(border: border, children: [
                pw.TableRow(children: [
                  pw.Container(width: 340, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    _labelCell('SELLER :'),
                    pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1), child:
                      pw.Text('SPNK GRANITES', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _titleColor))),
                    _infoLine('OFFICE : NO 2/A2, 3RD CROSS,'),
                    _infoLine('GOPALA KRISHNA COLONY, KRISHNAGIRI (TK & DT)'),
                    _infoLine('KRISHNAGIRI - 635001, TAMIL NADU, INDIA.'),
                    _infoLine('GSTIN : 33ALAPS2464D1ZF, MOB : 9994882044'),
                    _infoLine('EMAIL : spnkgranites22@gmail.com'),
                  ])),
                  pw.Table(border: thinBorder, children: [
                    _kvTableRow('INVOICE NO', inv.invoiceNo),
                    _kvTableRow('INV DATE', dateFmt.format(inv.invoiceDate)),
                    _kvTableRow('INV REF', inv.invoiceRef),
                    _kvTableRow('BUYER ORDER NO & DATE', ''),
                    _kvTableRow('OTHER REFERENCES', ''),
                  ]),
                ]),
              ]),

              // ===== CONSIGNEE + DELIVERY =====
              pw.Table(border: border, children: [
                pw.TableRow(children: [
                  pw.Container(width: 280, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    _labelCell('CONSIGNEE :'),
                    _infoLine('M/s ${inv.buyerName},'),
                    _infoLine(inv.buyerAddress1),
                    _infoLine(inv.buyerAddress2),
                    if (inv.buyerAddress3.isNotEmpty) _infoLine(inv.buyerAddress3),
                    _infoLine('GSTIN : ${inv.buyerGstin}'),
                  ])),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    _labelCell('DELIVERY :'),
                    _infoLine('M/s ${inv.deliveryName},'),
                    _infoLine(inv.deliveryAddress1),
                    _infoLine(inv.deliveryAddress2),
                    if (inv.deliveryAddress3.isNotEmpty) _infoLine(inv.deliveryAddress3),
                    _infoLine('GSTIN : ${inv.deliveryGstin}'),
                  ]),
                ]),
              ]),

              // ===== TRANSPORT DETAILS =====
              pw.Table(border: border, columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
              }, children: [
                pw.TableRow(children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    _kvSmallRow('PRE - CARRIAGE BY', ''),
                    _dataCell('ROAD', fontSize: 6),
                    _kvSmallRow('LORRY NO', ''),
                    _dataCell(inv.lorryNo, fontSize: 6),
                    _kvSmallRow('PLACE OF DISCHARGE', ''),
                    _dataCell(inv.placeOfDischarge, fontSize: 6),
                  ]),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    _kvSmallRow('PLACE OF DESPATCH', ''),
                    _dataCell(inv.placeOfDespatch, fontSize: 6),
                    _kvSmallRow('PLACE OF LOADING', ''),
                    _dataCell(inv.placeOfLoading, fontSize: 6),
                    _kvSmallRow('FINAL DESTINATION', ''),
                    _dataCell(inv.finalDestination, fontSize: 6),
                  ]),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    _kvSmallRow('COUNTRY OF ORIGIN OF', ''),
                    _dataCell('GOODS', fontSize: 5),
                    _dataCell('INDIA', fontSize: 6, bold: true),
                    _kvSmallRow('TERMS OF DELIVERY AND PAYMENT', ''),
                    _dataCell('AGAINST PAYMENT', fontSize: 6),
                    _kvSmallRow('HSN CODE', ''),
                    _dataCell('2516', fontSize: 7, bold: true),
                  ]),
                ]),
              ]),

              // ===== ITEMS TABLE HEADER =====
              pw.Table(border: border, columnWidths: {
                0: const pw.FixedColumnWidth(22),
                1: const pw.FixedColumnWidth(62),
                2: const pw.FixedColumnWidth(38),
                3: const pw.FixedColumnWidth(38),
                4: const pw.FixedColumnWidth(38),
                5: const pw.FixedColumnWidth(52),
                6: const pw.FixedColumnWidth(52),
                7: const pw.FixedColumnWidth(68),
              }, children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: _headerBg),
                  children: [
                    _headerCell('SL\nNO'),
                    _headerCell('MARKS &\nBLOCK NO'),
                    pw.Container(color: _labelBg, child: pw.Column(children: [
                      pw.Container(color: _headerBg, padding: const pw.EdgeInsets.all(1),
                        child: pw.Text('GROSS MEASUREMENTS IN CMS', style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold, color: _headerText), textAlign: pw.TextAlign.center)),
                    ])),
                    _headerCell(''),
                    _headerCell(''),
                    _headerCell('QTY\nCBM'),
                    _headerCell('RATE PER\nCBM'),
                    _headerCell('TOTAL\nAMOUNT(RS)'),
                  ],
                ),
                // Sub-header for L W H
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: _labelBg),
                  children: [
                    _labelCell('', align: pw.TextAlign.center),
                    _labelCell('', align: pw.TextAlign.center),
                    _labelCell('L', align: pw.TextAlign.center),
                    _labelCell('W', align: pw.TextAlign.center),
                    _labelCell('H', align: pw.TextAlign.center),
                    _labelCell('', align: pw.TextAlign.center),
                    _labelCell('', align: pw.TextAlign.center),
                    _labelCell('', align: pw.TextAlign.center),
                  ],
                ),
                // Item rows
                ...inv.items.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  return pw.TableRow(children: [
                    _dataCell('${i + 1}', align: pw.TextAlign.center),
                    _dataCell(item.blockNo, align: pw.TextAlign.center),
                    _dataCell('${item.length.toInt()}', align: pw.TextAlign.center),
                    _dataCell('${item.width.toInt()}', align: pw.TextAlign.center),
                    _dataCell('${item.height.toInt()}', align: pw.TextAlign.center),
                    _dataCell(item.cbm.toStringAsFixed(3), align: pw.TextAlign.center),
                    _dataCell(_fmt.format(item.ratePerCbm), align: pw.TextAlign.center),
                    _dataCell(_fmt.format(item.amount), align: pw.TextAlign.right),
                  ]);
                }),
                // TOTAL ROW
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: _labelBg),
                  children: [
                    _labelCell(''),
                    _labelCell(''),
                    _labelCell(''),
                    _labelCell(''),
                    _labelCell('TOTAL', align: pw.TextAlign.center),
                    _labelCell(inv.totalCbm.toStringAsFixed(3), align: pw.TextAlign.center),
                    _labelCell('SUB TOTAL', align: pw.TextAlign.center),
                    _labelCell(_fmt.format(inv.subTotal), align: pw.TextAlign.right),
                  ],
                ),
              ]),

              // ===== BANK DETAILS + TAX =====
              pw.Table(border: border, columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
              }, children: [
                pw.TableRow(children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    _kvSmallRow('NOTE    -       ', 'EX-QUARRY PRICE FIXED'),
                    _kvSmallRow('BANK    -', ' AXIS BANK LTD, KRISHNAGIRI'),
                    _kvSmallRow('A/C NO -', ' 922020021461845'),
                    _kvSmallRow('IFSC      -', ' UTIB0002097'),
                  ]),
                  pw.Table(border: thinBorder, children: [
                    pw.TableRow(children: [
                      _labelCell('CGST 2.5%', align: pw.TextAlign.right),
                      _dataCell(inv.isIgst ? 'NIL' : _fmtDec.format(inv.cgst), align: pw.TextAlign.right),
                    ]),
                    pw.TableRow(children: [
                      _labelCell('SGST 2.5%', align: pw.TextAlign.right),
                      _dataCell(inv.isIgst ? 'NIL' : _fmtDec.format(inv.sgst), align: pw.TextAlign.right),
                    ]),
                    pw.TableRow(children: [
                      _labelCell('IGST 5%', align: pw.TextAlign.right),
                      _dataCell(inv.isIgst ? _fmtDec.format(inv.igst) : 'NIL', align: pw.TextAlign.right),
                    ]),
                    pw.TableRow(decoration: pw.BoxDecoration(color: _headerBg), children: [
                      _headerCell('NETT AMOUNT'),
                      pw.Container(color: _headerBg, padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(_fmt.format(inv.netAmount), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _headerText), textAlign: pw.TextAlign.right)),
                    ]),
                  ]),
                ]),
              ]),

              // ===== AMOUNT IN WORDS =====
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                padding: const pw.EdgeInsets.all(3),
                child: pw.Text(
                  'IN WORDS : ${_amountInWords(inv.netAmount)}',
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _titleColor),
                ),
              ),
              pw.SizedBox(height: 25),

              // ===== SIGNATURES =====
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Receiver's Signature", style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic)),
                  pw.Column(children: [
                    pw.Text('For SPNK GRANITES', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _titleColor)),
                    pw.SizedBox(height: 35),
                    pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic)),
                  ]),
                ],
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  static pw.Widget _infoLine(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 6)),
    );
  }

  static pw.TableRow _kvTableRow(String key, String value) {
    return pw.TableRow(children: [
      _labelCell(key, fontSize: 6),
      _dataCell(value, fontSize: 6.5, bold: true),
    ]);
  }

  static pw.Widget _kvSmallRow(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: pw.Row(children: [
        pw.Text(key, style: pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 6)),
      ]),
    );
  }
}
