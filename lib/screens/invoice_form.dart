import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../services/pdf_generator.dart';
import 'package:printing/printing.dart';

class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({super.key});
  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final inv = Invoice();
  bool _sameAsConsignee = true;
  int _step = 0; // 0=invoice, 1=buyer, 2=transport, 3=items

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(['Invoice Details', 'Buyer Details', 'Transport', 'Block Items'][_step]),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          if (_step > 0)
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _step--)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: [_invoiceStep, _buyerStep, _transportStep, _itemsStep][_step](),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          if (_step > 0) Expanded(child: OutlinedButton(
            onPressed: () => setState(() => _step--),
            child: const Text('BACK'),
          )),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _step < 3 ? () => setState(() => _step++) : _generatePdf,
            child: Text(_step < 3 ? 'NEXT' : 'GENERATE PDF', style: const TextStyle(fontSize: 16)),
          )),
        ]),
      ),
    );
  }

  Widget _invoiceStep() => Column(children: [
    _header('Invoice Info'),
    _field('Invoice No (e.g. SPNK/17/26-27)', (v) => inv.invoiceNo = v, initial: inv.invoiceNo),
    _field('Invoice Ref (e.g. 1.87 HEC)', (v) => inv.invoiceRef = v, initial: inv.invoiceRef),
    _datePicker(),
    SwitchListTile(
      title: const Text('Interstate (IGST 5%)'),
      subtitle: Text(inv.isIgst ? 'IGST 5%' : 'CGST 2.5% + SGST 2.5%'),
      value: inv.isIgst,
      onChanged: (v) => setState(() => inv.isIgst = v),
    ),
  ]);

  Widget _buyerStep() => Column(children: [
    _header('Consignee / Buyer'),
    _field('Buyer Name (without M/s)', (v) => inv.buyerName = v, initial: inv.buyerName),
    _field('Address Line 1', (v) => inv.buyerAddress1 = v, initial: inv.buyerAddress1),
    _field('Address Line 2', (v) => inv.buyerAddress2 = v, initial: inv.buyerAddress2),
    _field('Address Line 3 (optional)', (v) => inv.buyerAddress3 = v, initial: inv.buyerAddress3, required: false),
    _field('GSTIN', (v) => inv.buyerGstin = v, initial: inv.buyerGstin),
    const SizedBox(height: 12),
    SwitchListTile(
      title: const Text('Delivery same as Consignee'),
      value: _sameAsConsignee,
      onChanged: (v) => setState(() { _sameAsConsignee = v; if (v) inv.copyBuyerToDelivery(); }),
    ),
    if (!_sameAsConsignee) ...[
      _header('Delivery Address'),
      _field('Delivery Name', (v) => inv.deliveryName = v, initial: inv.deliveryName),
      _field('Delivery Address 1', (v) => inv.deliveryAddress1 = v, initial: inv.deliveryAddress1),
      _field('Delivery Address 2', (v) => inv.deliveryAddress2 = v, initial: inv.deliveryAddress2),
      _field('Delivery Address 3', (v) => inv.deliveryAddress3 = v, initial: inv.deliveryAddress3, required: false),
      _field('Delivery GSTIN', (v) => inv.deliveryGstin = v, initial: inv.deliveryGstin),
    ],
  ]);

  Widget _transportStep() => Column(children: [
    _header('Transport Details'),
    _field('Lorry No', (v) => inv.lorryNo = v, initial: inv.lorryNo),
    _field('Place of Despatch', (v) => inv.placeOfDespatch = v, initial: inv.placeOfDespatch),
    _field('Place of Loading', (v) => inv.placeOfLoading = v, initial: inv.placeOfLoading),
    _field('Place of Discharge', (v) => inv.placeOfDischarge = v, initial: inv.placeOfDischarge),
    _field('Final Destination', (v) => inv.finalDestination = v, initial: inv.finalDestination),
  ]);

  Widget _itemsStep() => Column(children: [
    _header('Granite Blocks'),
    ...inv.items.asMap().entries.map((e) => _blockCard(e.key, e.value)),
    const SizedBox(height: 8),
    OutlinedButton.icon(
      icon: const Icon(Icons.add),
      label: const Text('ADD BLOCK'),
      onPressed: () => setState(() => inv.items.add(BlockItem())),
    ),
    const SizedBox(height: 16),
    Card(
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          _summaryRow('Total CBM', inv.totalCbm.toStringAsFixed(3)),
          _summaryRow('Sub Total', 'Rs. ${NumberFormat('#,##0', 'en_IN').format(inv.subTotal)}'),
          if (!inv.isIgst) _summaryRow('CGST 2.5%', 'Rs. ${inv.cgst.toStringAsFixed(1)}'),
          if (!inv.isIgst) _summaryRow('SGST 2.5%', 'Rs. ${inv.sgst.toStringAsFixed(1)}'),
          if (inv.isIgst) _summaryRow('IGST 5%', 'Rs. ${inv.igst.toStringAsFixed(2)}'),
          const Divider(),
          _summaryRow('Net Amount', 'Rs. ${NumberFormat('#,##0', 'en_IN').format(inv.netAmount)}', bold: true),
        ]),
      ),
    ),
  ]);

  Widget _blockCard(int idx, BlockItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            Text('Block ${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            if (inv.items.length > 1) IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() => inv.items.removeAt(idx)),
            ),
          ]),
          _field('Block No', (v) => item.blockNo = v, initial: item.blockNo),
          Row(children: [
            Expanded(child: _numField('L (cm)', item.length, (v) => setState(() => item.length = v))),
            const SizedBox(width: 8),
            Expanded(child: _numField('W (cm)', item.width, (v) => setState(() => item.width = v))),
            const SizedBox(width: 8),
            Expanded(child: _numField('H (cm)', item.height, (v) => setState(() => item.height = v))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _numField('Rate/CBM', item.ratePerCbm, (v) => setState(() => item.ratePerCbm = v))),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('CBM: ${item.cbm.toStringAsFixed(3)}', style: const TextStyle(fontSize: 13)),
              Text('Rs. ${NumberFormat('#,##0', 'en_IN').format(item.amount)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
          ]),
        ]),
      ),
    );
  }

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
  );

  Widget _field(String label, Function(String) onSave, {String initial = '', bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: initial,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
        onChanged: onSave,
        validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
      ),
    );
  }

  Widget _numField(String label, double val, Function(double) onChanged) {
    return TextFormField(
      initialValue: val > 0 ? val.toString() : '',
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      keyboardType: TextInputType.number,
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
    );
  }

  Widget _datePicker() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Invoice Date'),
      subtitle: Text(DateFormat('dd MMM yyyy').format(inv.invoiceDate)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: inv.invoiceDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) setState(() => inv.invoiceDate = picked);
      },
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: style), Text(value, style: style),
      ]),
    );
  }

  Future<void> _generatePdf() async {
    if (_sameAsConsignee) inv.copyBuyerToDelivery();
    final pdfBytes = await PdfGenerator.generate(inv);
    if (!mounted) return;
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
  }
}
