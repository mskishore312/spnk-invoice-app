import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/invoice_template.dart';

class PdfGenerator {
  static final _fmt = NumberFormat('#,##0', 'en_IN');
  static final _fmtDec = NumberFormat('#,##0.00', 'en_IN');
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  static String _amountInWords(double amount) {
    int amt = amount.round();
    if (amt == 0) return 'ZERO RUPEES ONLY.';
    final ones = ['','ONE','TWO','THREE','FOUR','FIVE','SIX','SEVEN','EIGHT','NINE',
      'TEN','ELEVEN','TWELVE','THIRTEEN','FOURTEEN','FIFTEEN','SIXTEEN','SEVENTEEN','EIGHTEEN','NINETEEN'];
    final tens = ['','','TWENTY','THIRTY','FORTY','FIFTY','SIXTY','SEVENTY','EIGHTY','NINETY'];
    String twoD(int n) => n < 20 ? ones[n] : '${tens[n~/10]} ${ones[n%10]}'.trim();
    String threeD(int n) => n >= 100 ? '${ones[n~/100]} HUNDRED${n%100>0?" AND ${twoD(n%100)}":""}' : twoD(n);
    List<String> p = [];
    if (amt >= 10000000) { p.add('${twoD(amt~/10000000)} CRORE'); amt %= 10000000; }
    if (amt >= 100000) { p.add('${twoD(amt~/100000)} LAKHS'); amt %= 100000; }
    if (amt >= 1000) { p.add('${twoD(amt~/1000)} THOUSAND'); amt %= 1000; }
    if (amt > 0) p.add(threeD(amt));
    return '${p.join(' ')} RUPEES ONLY.';
  }

  static Future<Uint8List> generate(Invoice inv, InvoiceTemplate tmpl) async {
    switch (tmpl.style) {
      case InvoiceStyle.classic: return _classic(inv, tmpl);
      case InvoiceStyle.modern: return _modern(inv, tmpl);
      case InvoiceStyle.minimalist: return _minimalist(inv, tmpl);
      case InvoiceStyle.corporate: return _corporate(inv, tmpl);
      case InvoiceStyle.elegant: return _elegant(inv, tmpl);
    }
  }

  // ========== CLASSIC ==========
  static Future<Uint8List> _classic(Invoice inv, InvoiceTemplate t) async {
    final pdf = pw.Document();
    final hdr = pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: t.textOnPrimary);
    final lbl = pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold);
    final nrm = const pw.TextStyle(fontSize: 6.5);
    final sml = const pw.TextStyle(fontSize: 6);
    final border = pw.TableBorder.all(color: t.borderColor, width: 0.5);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(20),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        // Title
        pw.Container(color: t.primaryColor, padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Center(child: pw.Text('INVOICE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: t.textOnPrimary)))),
        pw.Container(padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Center(child: pw.Text('ORIGINAL', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1F4E79))))),
        pw.SizedBox(height: 3),

        // Seller + Invoice info
        pw.Table(border: border, children: [
          pw.TableRow(children: [
            pw.Container(width: 330, padding: const pw.EdgeInsets.all(3), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Container(color: t.secondaryColor, padding: const pw.EdgeInsets.all(2), child: pw.Text('SELLER :', style: lbl)),
              pw.Text('SPNK GRANITES', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1F4E79))),
              pw.Text('OFFICE : NO 2/A2, 3RD CROSS, GOPALA KRISHNA COLONY,', style: sml),
              pw.Text('KRISHNAGIRI (TK & DT) - 635001, TAMIL NADU, INDIA.', style: sml),
              pw.Text('GSTIN : 33ALAPS2464D1ZF  |  MOB : 9994882044', style: sml),
              pw.Text('EMAIL : spnkgranites22@gmail.com', style: sml),
            ])),
            pw.Container(padding: const pw.EdgeInsets.all(2), child: pw.Table(border: pw.TableBorder.all(width: 0.3), children: [
              _classicKV('INVOICE NO', inv.invoiceNo, t), _classicKV('INV DATE', _dateFmt.format(inv.invoiceDate), t),
              _classicKV('INV REF', inv.invoiceRef, t), _classicKV('BUYER ORDER NO', '', t), _classicKV('OTHER REF', '', t),
            ])),
          ]),
        ]),

        // Consignee + Delivery
        pw.Table(border: border, children: [pw.TableRow(children: [
          pw.Container(width: 280, padding: const pw.EdgeInsets.all(3), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Container(color: t.secondaryColor, padding: const pw.EdgeInsets.all(2), child: pw.Text('CONSIGNEE :', style: lbl)),
            pw.Text('M/s ${inv.buyerName}', style: nrm), pw.Text(inv.buyerAddress1, style: sml),
            pw.Text(inv.buyerAddress2, style: sml), if (inv.buyerAddress3.isNotEmpty) pw.Text(inv.buyerAddress3, style: sml),
            pw.Text('GSTIN : ${inv.buyerGstin}', style: sml),
          ])),
          pw.Container(padding: const pw.EdgeInsets.all(3), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Container(color: t.secondaryColor, padding: const pw.EdgeInsets.all(2), child: pw.Text('DELIVERY :', style: lbl)),
            pw.Text('M/s ${inv.deliveryName}', style: nrm), pw.Text(inv.deliveryAddress1, style: sml),
            pw.Text(inv.deliveryAddress2, style: sml), if (inv.deliveryAddress3.isNotEmpty) pw.Text(inv.deliveryAddress3, style: sml),
            pw.Text('GSTIN : ${inv.deliveryGstin}', style: sml),
          ])),
        ])]),

        // Transport
        pw.Table(border: border, columnWidths: {0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1)}, children: [
          pw.TableRow(children: [
            _transportCol(['PRE-CARRIAGE BY : ROAD', 'LORRY NO : ${inv.lorryNo}', 'PLACE OF DISCHARGE : ${inv.placeOfDischarge}'], sml),
            _transportCol(['PLACE OF DESPATCH : ${inv.placeOfDespatch}', 'PLACE OF LOADING : ${inv.placeOfLoading}', 'FINAL DESTINATION : ${inv.finalDestination}'], sml),
            _transportCol(['COUNTRY OF ORIGIN : INDIA', 'TERMS : AGAINST PAYMENT', 'HSN CODE : 2516'], sml),
          ]),
        ]),

        // Items table
        pw.Table(border: border, columnWidths: _itemColWidths(), children: [
          pw.TableRow(decoration: pw.BoxDecoration(color: t.primaryColor), children: [
            _hCell('SL\nNO', hdr), _hCell('MARKS &\nBLOCK NO', hdr), _hCell('L', hdr), _hCell('W', hdr), _hCell('H', hdr),
            _hCell('QTY\nCBM', hdr), _hCell('RATE/\nCBM', hdr), _hCell('AMOUNT\n(RS)', hdr),
          ]),
          ...inv.items.asMap().entries.map((e) => pw.TableRow(
            decoration: e.key % 2 == 1 ? pw.BoxDecoration(color: t.altRowColor) : null,
            children: [
              _dCell('${e.key+1}', nrm), _dCell(e.value.blockNo, nrm),
              _dCell('${e.value.length.toInt()}', nrm), _dCell('${e.value.width.toInt()}', nrm), _dCell('${e.value.height.toInt()}', nrm),
              _dCell(e.value.cbm.toStringAsFixed(3), nrm), _dCell(_fmt.format(e.value.ratePerCbm), nrm), _dCell(_fmt.format(e.value.amount), nrm),
            ],
          )),
          pw.TableRow(decoration: pw.BoxDecoration(color: t.secondaryColor), children: [
            _dCell('', lbl), _dCell('', lbl), _dCell('', lbl), _dCell('', lbl),
            _dCell('TOTAL', lbl), _dCell(inv.totalCbm.toStringAsFixed(3), lbl), _dCell('SUB TOTAL', lbl), _dCell(_fmt.format(inv.subTotal), lbl),
          ]),
        ]),

        // Bank + Tax
        pw.Table(border: border, columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(2)}, children: [
          pw.TableRow(children: [
            pw.Container(padding: const pw.EdgeInsets.all(3), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('NOTE - EX-QUARRY PRICE FIXED', style: pw.TextStyle(fontSize: 5.5, fontStyle: pw.FontStyle.italic)),
              pw.Text('BANK - AXIS BANK LTD, KRISHNAGIRI', style: sml),
              pw.Text('A/C NO - 922020021461845  |  IFSC - UTIB0002097', style: sml),
            ])),
            pw.Table(border: pw.TableBorder.all(width: 0.3), children: [
              _taxRow('CGST 2.5%', inv.isIgst ? 'NIL' : _fmtDec.format(inv.cgst), t),
              _taxRow('SGST 2.5%', inv.isIgst ? 'NIL' : _fmtDec.format(inv.sgst), t),
              _taxRow('IGST 5%', inv.isIgst ? _fmtDec.format(inv.igst) : 'NIL', t),
              pw.TableRow(decoration: pw.BoxDecoration(color: t.primaryColor), children: [
                pw.Container(padding: const pw.EdgeInsets.all(3), child: pw.Text('NETT AMOUNT', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: t.textOnPrimary), textAlign: pw.TextAlign.right)),
                pw.Container(padding: const pw.EdgeInsets.all(3), child: pw.Text(_fmt.format(inv.netAmount), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: t.textOnPrimary), textAlign: pw.TextAlign.right)),
              ]),
            ]),
          ]),
        ]),

        pw.Container(decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)), padding: const pw.EdgeInsets.all(3),
          child: pw.Text('IN WORDS : ${_amountInWords(inv.netAmount)}', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1F4E79)))),
        pw.SizedBox(height: 25),
        _signatures(t),
      ]),
    ));
    return pdf.save();
  }

  // ========== MODERN ==========
  static Future<Uint8List> _modern(Invoice inv, InvoiceTemplate t) async {
    final pdf = pw.Document();
    final title = pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: t.primaryColor);
    final lbl = pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF666666));
    final val = pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold);
    final nrm = const pw.TextStyle(fontSize: 7);
    final hdr = pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: t.textOnPrimary);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(0),
      build: (ctx) => pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        // Left sidebar
        pw.Container(width: 8, height: double.infinity, color: t.primaryColor),
        pw.SizedBox(width: 20),
        // Main content
        pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.only(top: 30, right: 25, bottom: 20), child:
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('INVOICE', style: title),
                pw.Container(width: 50, height: 3, color: t.primaryColor),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('SPNK GRANITES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: t.primaryColor)),
                pw.Text('Krishnagiri - 635001, Tamil Nadu', style: nrm),
                pw.Text('GSTIN: 33ALAPS2464D1ZF', style: nrm),
              ]),
            ]),
            pw.SizedBox(height: 20),
            pw.Row(children: [
              _modernField('Invoice No', inv.invoiceNo, lbl, val), pw.SizedBox(width: 40),
              _modernField('Date', _dateFmt.format(inv.invoiceDate), lbl, val), pw.SizedBox(width: 40),
              _modernField('HSN Code', '2516', lbl, val),
            ]),
            pw.SizedBox(height: 15),
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('BILL TO', style: lbl), pw.SizedBox(height: 3),
                pw.Text('M/s ${inv.buyerName}', style: val),
                pw.Text('${inv.buyerAddress1}, ${inv.buyerAddress2}', style: nrm),
                pw.Text('GSTIN: ${inv.buyerGstin}', style: nrm),
              ])),
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('SHIP TO', style: lbl), pw.SizedBox(height: 3),
                pw.Text('M/s ${inv.deliveryName}', style: val),
                pw.Text('${inv.deliveryAddress1}, ${inv.deliveryAddress2}', style: nrm),
              ])),
            ]),
            pw.SizedBox(height: 5),
            pw.Row(children: [
              _modernField('Lorry No', inv.lorryNo, lbl, val), pw.SizedBox(width: 30),
              _modernField('Loading', inv.placeOfLoading, lbl, val), pw.SizedBox(width: 30),
              _modernField('Destination', inv.finalDestination, lbl, val),
            ]),
            pw.SizedBox(height: 12),
            // Items table
            pw.Table(border: pw.TableBorder(horizontalInside: pw.BorderSide(color: t.borderColor, width: 0.3)), columnWidths: _itemColWidths(), children: [
              pw.TableRow(decoration: pw.BoxDecoration(color: t.primaryColor, borderRadius: pw.BorderRadius.circular(2)), children: [
                _hCell('SL', hdr), _hCell('BLOCK NO', hdr), _hCell('L', hdr), _hCell('W', hdr), _hCell('H', hdr),
                _hCell('CBM', hdr), _hCell('RATE', hdr), _hCell('AMOUNT', hdr),
              ]),
              ...inv.items.asMap().entries.map((e) => pw.TableRow(
                decoration: e.key % 2 == 1 ? pw.BoxDecoration(color: t.secondaryColor) : null,
                children: [
                  _dCell('${e.key+1}', nrm), _dCell(e.value.blockNo, nrm),
                  _dCell('${e.value.length.toInt()}', nrm), _dCell('${e.value.width.toInt()}', nrm), _dCell('${e.value.height.toInt()}', nrm),
                  _dCell(e.value.cbm.toStringAsFixed(3), nrm), _dCell(_fmt.format(e.value.ratePerCbm), nrm), _dCell(_fmt.format(e.value.amount), nrm),
                ],
              )),
            ]),
            pw.SizedBox(height: 10),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.Container(width: 200, child: pw.Column(children: [
                _summLine('Sub Total', _fmt.format(inv.subTotal), lbl, val),
                if (!inv.isIgst) _summLine('CGST 2.5%', _fmtDec.format(inv.cgst), lbl, nrm),
                if (!inv.isIgst) _summLine('SGST 2.5%', _fmtDec.format(inv.sgst), lbl, nrm),
                if (inv.isIgst) _summLine('IGST 5%', _fmtDec.format(inv.igst), lbl, nrm),
                pw.Divider(color: t.primaryColor, thickness: 1.5),
                _summLine('Net Amount', _fmt.format(inv.netAmount), pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: t.primaryColor), pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: t.primaryColor)),
              ])),
            ]),
            pw.SizedBox(height: 8),
            pw.Text('IN WORDS: ${_amountInWords(inv.netAmount)}', style: pw.TextStyle(fontSize: 6.5, fontStyle: pw.FontStyle.italic, color: PdfColor.fromInt(0xFF666666))),
            pw.SizedBox(height: 8),
            pw.Container(padding: const pw.EdgeInsets.all(6), color: t.secondaryColor, child: pw.Row(children: [
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Bank: Axis Bank Ltd, Krishnagiri', style: nrm),
                pw.Text('A/C: 922020021461845  |  IFSC: UTIB0002097', style: nrm),
              ])),
            ])),
            pw.Spacer(),
            _signatures(t),
          ]),
        )),
      ]),
    ));
    return pdf.save();
  }

  // ========== MINIMALIST ==========
  static Future<Uint8List> _minimalist(Invoice inv, InvoiceTemplate t) async {
    final pdf = pw.Document();
    final title = pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: t.primaryColor, letterSpacing: 4);
    final lbl = pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF999999));
    final val = const pw.TextStyle(fontSize: 7.5);
    final nrm = const pw.TextStyle(fontSize: 7);
    final hdr = pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('INVOICE', style: title),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('SPNK GRANITES', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text('Krishnagiri - 635001', style: nrm),
          ]),
        ]),
        pw.Container(width: double.infinity, height: 0.5, color: t.primaryColor, margin: const pw.EdgeInsets.symmetric(vertical: 12)),
        pw.Row(children: [
          _minField('Invoice', inv.invoiceNo, lbl, val), pw.SizedBox(width: 50),
          _minField('Date', _dateFmt.format(inv.invoiceDate), lbl, val), pw.SizedBox(width: 50),
          _minField('GSTIN', '33ALAPS2464D1ZF', lbl, val),
        ]),
        pw.SizedBox(height: 15),
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('TO', style: lbl), pw.SizedBox(height: 2),
            pw.Text(inv.buyerName, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            pw.Text('${inv.buyerAddress1}, ${inv.buyerAddress2}', style: nrm),
            pw.Text('GSTIN: ${inv.buyerGstin}', style: nrm),
          ])),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('TRANSPORT', style: lbl), pw.SizedBox(height: 2),
            pw.Text('Lorry: ${inv.lorryNo}', style: nrm),
            pw.Text('From: ${inv.placeOfLoading}', style: nrm),
            pw.Text('To: ${inv.finalDestination}', style: nrm),
          ])),
        ]),
        pw.SizedBox(height: 15),
        // Items - minimal borders
        pw.Table(border: pw.TableBorder(bottom: pw.BorderSide(color: t.borderColor, width: 0.3), horizontalInside: pw.BorderSide(color: t.borderColor, width: 0.2)),
          columnWidths: _itemColWidths(), children: [
          pw.TableRow(decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))), children: [
            _dCell('NO', hdr), _dCell('BLOCK', hdr), _dCell('L', hdr), _dCell('W', hdr), _dCell('H', hdr),
            _dCell('CBM', hdr), _dCell('RATE', hdr), _dCell('AMOUNT', hdr),
          ]),
          ...inv.items.asMap().entries.map((e) => pw.TableRow(children: [
            _dCell('${e.key+1}', nrm), _dCell(e.value.blockNo, nrm),
            _dCell('${e.value.length.toInt()}', nrm), _dCell('${e.value.width.toInt()}', nrm), _dCell('${e.value.height.toInt()}', nrm),
            _dCell(e.value.cbm.toStringAsFixed(3), nrm), _dCell(_fmt.format(e.value.ratePerCbm), nrm), _dCell(_fmt.format(e.value.amount), nrm),
          ])),
        ]),
        pw.SizedBox(height: 12),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Container(width: 180, child: pw.Column(children: [
            _summLine('Sub Total', _fmt.format(inv.subTotal), lbl, val),
            if (!inv.isIgst) _summLine('CGST 2.5%', _fmtDec.format(inv.cgst), lbl, nrm),
            if (!inv.isIgst) _summLine('SGST 2.5%', _fmtDec.format(inv.sgst), lbl, nrm),
            if (inv.isIgst) _summLine('IGST 5%', _fmtDec.format(inv.igst), lbl, nrm),
            pw.Container(height: 0.5, color: t.primaryColor, margin: const pw.EdgeInsets.symmetric(vertical: 4)),
            _summLine('TOTAL', '₹ ${_fmt.format(inv.netAmount)}', pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ])),
        ]),
        pw.SizedBox(height: 8),
        pw.Text(_amountInWords(inv.netAmount), style: pw.TextStyle(fontSize: 6.5, fontStyle: pw.FontStyle.italic, color: PdfColor.fromInt(0xFF999999))),
        pw.SizedBox(height: 6),
        pw.Text('Bank: Axis Bank Ltd | A/C: 922020021461845 | IFSC: UTIB0002097', style: pw.TextStyle(fontSize: 6, color: PdfColor.fromInt(0xFF999999))),
        pw.Spacer(),
        _signatures(t),
      ]),
    ));
    return pdf.save();
  }

  // ========== CORPORATE ==========
  static Future<Uint8List> _corporate(Invoice inv, InvoiceTemplate t) async {
    final pdf = pw.Document();
    final nrm = pw.TextStyle(fontSize: 7, color: t.bodyText);
    final lbl = pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: t.bodyText);
    final hdr = pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: t.textOnPrimary);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(20),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        // Full width dark banner
        pw.Container(color: t.primaryColor, padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 12), child:
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('SPNK GRANITES', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: t.textOnPrimary)),
              pw.Text('Krishnagiri - 635001, Tamil Nadu, India', style: pw.TextStyle(fontSize: 7, color: PdfColor.fromInt(0xFFB0BEC5))),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: t.textOnPrimary)),
              pw.Text('GSTIN: 33ALAPS2464D1ZF', style: pw.TextStyle(fontSize: 7, color: PdfColor.fromInt(0xFFB0BEC5))),
            ]),
          ]),
        ),
        pw.SizedBox(height: 10),
        // Invoice meta
        pw.Container(color: t.secondaryColor, padding: const pw.EdgeInsets.all(8), child:
          pw.Row(children: [
            pw.Expanded(child: pw.Row(children: [pw.Text('Invoice No: ', style: lbl), pw.Text(inv.invoiceNo, style: nrm)])),
            pw.Expanded(child: pw.Row(children: [pw.Text('Date: ', style: lbl), pw.Text(_dateFmt.format(inv.invoiceDate), style: nrm)])),
            pw.Expanded(child: pw.Row(children: [pw.Text('Ref: ', style: lbl), pw.Text(inv.invoiceRef, style: nrm)])),
            pw.Expanded(child: pw.Row(children: [pw.Text('HSN: ', style: lbl), pw.Text('2516', style: nrm)])),
          ]),
        ),
        pw.SizedBox(height: 8),
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(child: pw.Container(padding: const pw.EdgeInsets.all(6), decoration: pw.BoxDecoration(border: pw.Border.all(color: t.borderColor, width: 0.3)), child:
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('CONSIGNEE', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: t.primaryColor)),
              pw.SizedBox(height: 3), pw.Text('M/s ${inv.buyerName}', style: lbl),
              pw.Text('${inv.buyerAddress1}\n${inv.buyerAddress2}', style: nrm),
              pw.Text('GSTIN: ${inv.buyerGstin}', style: nrm),
            ]),
          )),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.Container(padding: const pw.EdgeInsets.all(6), decoration: pw.BoxDecoration(border: pw.Border.all(color: t.borderColor, width: 0.3)), child:
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('TRANSPORT', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: t.primaryColor)),
              pw.SizedBox(height: 3),
              pw.Text('Lorry: ${inv.lorryNo}', style: nrm), pw.Text('Loading: ${inv.placeOfLoading}', style: nrm),
              pw.Text('Destination: ${inv.finalDestination}', style: nrm), pw.Text('Pre-carriage: ROAD', style: nrm),
            ]),
          )),
        ]),
        pw.SizedBox(height: 8),
        // Items
        pw.Table(border: pw.TableBorder.all(color: t.borderColor, width: 0.3), columnWidths: _itemColWidths(), children: [
          pw.TableRow(decoration: pw.BoxDecoration(color: t.primaryColor), children: [
            _hCell('SL', hdr), _hCell('BLOCK NO', hdr), _hCell('L', hdr), _hCell('W', hdr), _hCell('H', hdr),
            _hCell('CBM', hdr), _hCell('RATE/CBM', hdr), _hCell('AMOUNT', hdr),
          ]),
          ...inv.items.asMap().entries.map((e) => pw.TableRow(
            decoration: pw.BoxDecoration(color: e.key % 2 == 1 ? t.altRowColor : null),
            children: [
              _dCell('${e.key+1}', nrm), _dCell(e.value.blockNo, nrm),
              _dCell('${e.value.length.toInt()}', nrm), _dCell('${e.value.width.toInt()}', nrm), _dCell('${e.value.height.toInt()}', nrm),
              _dCell(e.value.cbm.toStringAsFixed(3), nrm), _dCell(_fmt.format(e.value.ratePerCbm), nrm), _dCell(_fmt.format(e.value.amount), nrm),
            ],
          )),
          pw.TableRow(decoration: pw.BoxDecoration(color: t.secondaryColor), children: [
            _dCell('', lbl), _dCell('', lbl), _dCell('', lbl), _dCell('', lbl),
            _dCell('TOTAL', lbl), _dCell(inv.totalCbm.toStringAsFixed(3), lbl), _dCell('SUB TOTAL', lbl), _dCell(_fmt.format(inv.subTotal), lbl),
          ]),
        ]),
        pw.SizedBox(height: 6),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(width: 220, padding: const pw.EdgeInsets.all(6), color: t.secondaryColor, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('BANK DETAILS', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: t.primaryColor)),
            pw.Text('Axis Bank Ltd, Krishnagiri', style: nrm),
            pw.Text('A/C: 922020021461845 | IFSC: UTIB0002097', style: nrm),
          ])),
          pw.Container(width: 200, child: pw.Column(children: [
            _summLine('CGST 2.5%', inv.isIgst ? 'NIL' : _fmtDec.format(inv.cgst), lbl, nrm),
            _summLine('SGST 2.5%', inv.isIgst ? 'NIL' : _fmtDec.format(inv.sgst), lbl, nrm),
            _summLine('IGST 5%', inv.isIgst ? _fmtDec.format(inv.igst) : 'NIL', lbl, nrm),
            pw.Container(color: t.primaryColor, padding: const pw.EdgeInsets.all(4), child:
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('NET AMOUNT', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: t.textOnPrimary)),
                pw.Text('Rs. ${_fmt.format(inv.netAmount)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: t.textOnPrimary)),
              ])),
          ])),
        ]),
        pw.SizedBox(height: 6),
        pw.Text('IN WORDS: ${_amountInWords(inv.netAmount)}', style: pw.TextStyle(fontSize: 6.5, fontStyle: pw.FontStyle.italic, color: t.bodyText)),
        pw.Spacer(),
        _signatures(t),
      ]),
    ));
    return pdf.save();
  }

  // ========== ELEGANT ==========
  static Future<Uint8List> _elegant(Invoice inv, InvoiceTemplate t) async {
    final pdf = pw.Document();
    final gold = t.secondaryColor;
    final dark = t.primaryColor;
    final nrm = pw.TextStyle(fontSize: 7, color: t.bodyText);
    final lbl = pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: gold);
    final hdr = pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: t.textOnPrimary);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(0),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        // Dark header with gold accents
        pw.Container(color: dark, padding: const pw.EdgeInsets.all(20), child: pw.Column(children: [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('SPNK', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: gold, letterSpacing: 6)),
              pw.Text('GRANITES', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFF999999), letterSpacing: 8)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: gold, letterSpacing: 3)),
              pw.SizedBox(height: 4),
              pw.Text('No. ${inv.invoiceNo}', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFFCCCCCC))),
              pw.Text('Date: ${_dateFmt.format(inv.invoiceDate)}', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFFCCCCCC))),
            ]),
          ]),
          pw.Container(height: 0.5, color: gold, margin: const pw.EdgeInsets.only(top: 10)),
        ])),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 12), child:
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('BILLED TO', style: lbl), pw.SizedBox(height: 3),
                pw.Text('M/s ${inv.buyerName}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text('${inv.buyerAddress1}, ${inv.buyerAddress2}', style: nrm),
                pw.Text('GSTIN: ${inv.buyerGstin}', style: nrm),
              ])),
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('TRANSPORT', style: lbl), pw.SizedBox(height: 3),
                pw.Text('Lorry: ${inv.lorryNo}', style: nrm),
                pw.Text('HSN: 2516 | ${inv.placeOfLoading}', style: nrm),
                pw.Text('GSTIN: 33ALAPS2464D1ZF', style: nrm),
              ])),
            ]),
            pw.SizedBox(height: 12),
            // Items
            pw.Table(border: pw.TableBorder(bottom: pw.BorderSide(color: gold, width: 0.5), horizontalInside: pw.BorderSide(color: PdfColor.fromInt(0xFFEEEEEE), width: 0.2)),
              columnWidths: _itemColWidths(), children: [
              pw.TableRow(decoration: pw.BoxDecoration(color: dark), children: [
                _hCell('NO', hdr), _hCell('BLOCK', hdr), _hCell('L', hdr), _hCell('W', hdr), _hCell('H', hdr),
                _hCell('CBM', hdr), _hCell('RATE', hdr), _hCell('AMOUNT', hdr),
              ]),
              ...inv.items.asMap().entries.map((e) => pw.TableRow(
                decoration: e.key % 2 == 1 ? pw.BoxDecoration(color: t.altRowColor) : null,
                children: [
                  _dCell('${e.key+1}', nrm), _dCell(e.value.blockNo, nrm),
                  _dCell('${e.value.length.toInt()}', nrm), _dCell('${e.value.width.toInt()}', nrm), _dCell('${e.value.height.toInt()}', nrm),
                  _dCell(e.value.cbm.toStringAsFixed(3), nrm), _dCell(_fmt.format(e.value.ratePerCbm), nrm), _dCell(_fmt.format(e.value.amount), nrm),
                ],
              )),
            ]),
            pw.SizedBox(height: 10),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.Container(width: 200, padding: const pw.EdgeInsets.all(8), decoration: pw.BoxDecoration(border: pw.Border.all(color: gold, width: 0.5)), child:
                pw.Column(children: [
                  _summLine('Sub Total', _fmt.format(inv.subTotal), lbl, nrm),
                  if (!inv.isIgst) _summLine('CGST 2.5%', _fmtDec.format(inv.cgst), lbl, nrm),
                  if (!inv.isIgst) _summLine('SGST 2.5%', _fmtDec.format(inv.sgst), lbl, nrm),
                  if (inv.isIgst) _summLine('IGST 5%', _fmtDec.format(inv.igst), lbl, nrm),
                  pw.Container(height: 0.5, color: gold, margin: const pw.EdgeInsets.symmetric(vertical: 4)),
                  pw.Container(color: dark, padding: const pw.EdgeInsets.all(5), child:
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                      pw.Text('TOTAL', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: gold)),
                      pw.Text('Rs ${_fmt.format(inv.netAmount)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: gold)),
                    ])),
                ]),
              ),
            ]),
            pw.SizedBox(height: 8),
            pw.Text(_amountInWords(inv.netAmount), style: pw.TextStyle(fontSize: 6.5, fontStyle: pw.FontStyle.italic, color: PdfColor.fromInt(0xFF888888))),
            pw.SizedBox(height: 6),
            pw.Container(padding: const pw.EdgeInsets.all(5), color: PdfColor.fromInt(0xFFFFF8E7), child:
              pw.Text('Bank: Axis Bank Ltd, Krishnagiri | A/C: 922020021461845 | IFSC: UTIB0002097', style: pw.TextStyle(fontSize: 6, color: PdfColor.fromInt(0xFF666666)))),
            pw.Spacer(),
            _signatures(t),
          ]),
        ),
      ]),
    ));
    return pdf.save();
  }

  // ===== SHARED HELPERS =====
  static Map<int, pw.TableColumnWidth> _itemColWidths() => {
    0: const pw.FixedColumnWidth(22), 1: const pw.FixedColumnWidth(62), 2: const pw.FixedColumnWidth(35),
    3: const pw.FixedColumnWidth(35), 4: const pw.FixedColumnWidth(35), 5: const pw.FixedColumnWidth(50),
    6: const pw.FixedColumnWidth(50), 7: const pw.FixedColumnWidth(65),
  };

  static pw.Widget _hCell(String t, pw.TextStyle s) => pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(t, style: s, textAlign: pw.TextAlign.center));
  static pw.Widget _dCell(String t, pw.TextStyle s) => pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(t, style: s, textAlign: pw.TextAlign.center));

  static pw.Widget _transportCol(List<String> lines, pw.TextStyle s) =>
    pw.Container(padding: const pw.EdgeInsets.all(3), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: lines.map((l) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 1), child: pw.Text(l, style: s))).toList()));

  static pw.TableRow _classicKV(String k, String v, InvoiceTemplate t) => pw.TableRow(children: [
    pw.Container(color: t.secondaryColor, padding: const pw.EdgeInsets.all(2), child: pw.Text(k, style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
    pw.Container(padding: const pw.EdgeInsets.all(2), child: pw.Text(v, style: const pw.TextStyle(fontSize: 6.5))),
  ]);

  static pw.TableRow _taxRow(String k, String v, InvoiceTemplate t) => pw.TableRow(children: [
    pw.Container(color: t.secondaryColor, padding: const pw.EdgeInsets.all(3), child: pw.Text(k, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
    pw.Container(padding: const pw.EdgeInsets.all(3), child: pw.Text(v, style: const pw.TextStyle(fontSize: 6.5), textAlign: pw.TextAlign.right)),
  ]);

  static pw.Widget _summLine(String k, String v, pw.TextStyle ks, pw.TextStyle vs) =>
    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 1.5), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(k, style: ks), pw.Text(v, style: vs)]));

  static pw.Widget _modernField(String k, String v, pw.TextStyle ks, pw.TextStyle vs) =>
    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text(k.toUpperCase(), style: ks), pw.SizedBox(height: 2), pw.Text(v, style: vs)]);

  static pw.Widget _minField(String k, String v, pw.TextStyle ks, pw.TextStyle vs) =>
    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text(k.toUpperCase(), style: ks), pw.SizedBox(height: 2), pw.Text(v, style: vs)]);

  static pw.Widget _signatures(InvoiceTemplate t) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
    pw.Text("Receiver's Signature", style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic)),
    pw.Column(children: [
      pw.Text('For SPNK GRANITES', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: t.primaryColor)),
      pw.SizedBox(height: 30),
      pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic)),
    ]),
  ]);
}
