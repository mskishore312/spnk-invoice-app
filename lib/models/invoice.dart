class BlockItem {
  String blockNo;
  double length; // in cms
  double width;
  double height;
  double ratePerCbm;

  BlockItem({
    this.blockNo = '',
    this.length = 0,
    this.width = 0,
    this.height = 0,
    this.ratePerCbm = 10000,
  });

  double get cbm => (length * width * height) / 1000000;
  double get amount => double.parse((cbm * ratePerCbm).toStringAsFixed(0));

  Map<String, dynamic> toMap() => {
    'blockNo': blockNo, 'length': length, 'width': width,
    'height': height, 'ratePerCbm': ratePerCbm,
  };

  factory BlockItem.fromMap(Map<String, dynamic> m) => BlockItem(
    blockNo: m['blockNo'] ?? '',
    length: (m['length'] ?? 0).toDouble(),
    width: (m['width'] ?? 0).toDouble(),
    height: (m['height'] ?? 0).toDouble(),
    ratePerCbm: (m['ratePerCbm'] ?? 10000).toDouble(),
  );
}

class Invoice {
  String invoiceNo;
  String invoiceRef;
  DateTime invoiceDate;
  String buyerName;
  String buyerAddress1;
  String buyerAddress2;
  String buyerAddress3;
  String buyerGstin;
  String deliveryName;
  String deliveryAddress1;
  String deliveryAddress2;
  String deliveryAddress3;
  String deliveryGstin;
  String lorryNo;
  String placeOfDespatch;
  String placeOfLoading;
  String placeOfDischarge;
  String finalDestination;
  bool isIgst; // true = IGST 5%, false = CGST+SGST 2.5% each
  List<BlockItem> items;

  Invoice({
    this.invoiceNo = '',
    this.invoiceRef = '1.87 HEC',
    DateTime? invoiceDate,
    this.buyerName = '',
    this.buyerAddress1 = '',
    this.buyerAddress2 = '',
    this.buyerAddress3 = '',
    this.buyerGstin = '',
    this.deliveryName = '',
    this.deliveryAddress1 = '',
    this.deliveryAddress2 = '',
    this.deliveryAddress3 = '',
    this.deliveryGstin = '',
    this.lorryNo = '',
    this.placeOfDespatch = 'SY NO.366(P)',
    this.placeOfLoading = 'JAGADEVIPALAYAM',
    this.placeOfDischarge = '',
    this.finalDestination = '',
    this.isIgst = false,
    List<BlockItem>? items,
  }) : invoiceDate = invoiceDate ?? DateTime.now(),
       items = items ?? [BlockItem()];

  double get subTotal => items.fold(0.0, (sum, item) => sum + item.amount);
  double get totalCbm => items.fold(0.0, (sum, item) => sum + item.cbm);
  double get cgst => isIgst ? 0 : double.parse((subTotal * 0.025).toStringAsFixed(1));
  double get sgst => isIgst ? 0 : double.parse((subTotal * 0.025).toStringAsFixed(1));
  double get igst => isIgst ? double.parse((subTotal * 0.05).toStringAsFixed(2)) : 0;
  double get netAmount => subTotal + cgst + sgst + igst;

  void copyBuyerToDelivery() {
    deliveryName = buyerName;
    deliveryAddress1 = buyerAddress1;
    deliveryAddress2 = buyerAddress2;
    deliveryAddress3 = buyerAddress3;
    deliveryGstin = buyerGstin;
  }
}
