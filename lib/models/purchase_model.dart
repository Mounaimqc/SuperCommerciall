import '../utils/constants.dart';
import '../utils/document_id_mapper.dart';

/// Payment status of a purchase document
enum PurchasePaymentStatus {
  all,
  paid,
  unpaid,
  partiallyPaid,
}

/// Model representing a single line item (product bought) inside a purchase document
class PurchaseItemModel {
  final String id;
  final String productName;
  final String productCode;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  PurchaseItemModel({
    required this.id,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    double qty = _parseDouble(json['Qté'] ?? json['Quantite'] ?? json['quantity'] ?? 1.0);
    double price = _parseDouble(json['PrixAchat'] ?? json['PrixVente'] ?? json['Prix'] ?? json['unitPrice'] ?? 0.0);
    double total = _parseDouble(json['Total'] ?? json['totalPrice'] ?? (qty * price));

    return PurchaseItemModel(
      id: json['id']?.toString() ?? json['ID']?.toString() ?? '',
      productName: json['Libellé']?.toString() ?? json['NOM']?.toString() ?? json['productName']?.toString() ?? 'Article commercial',
      productCode: json['Reference']?.toString() ?? json['CODE']?.toString() ?? json['productCode']?.toString() ?? 'ACH-001',
      quantity: qty == 0 ? 1.0 : qty,
      unitPrice: price,
      totalPrice: total,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Libellé': productName,
      'Reference': productCode,
      'Qté': quantity,
      'PrixAchat': unitPrice,
      'Total': totalPrice,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    final str = value.toString().trim();
    if (str.isEmpty) return 0.0;
    return double.tryParse(str) ?? 0.0;
  }

  String get formattedUnitPrice => '${unitPrice.toStringAsFixed(2)} DZD';
  String get formattedTotalPrice => '${totalPrice.toStringAsFixed(2)} DZD';
}

/// Purchase Document Model representing an invoice/purchase from SAGE API (Type=3)
class PurchaseModel {
  final String id;
  final String number;
  final String date;
  final String time;
  final double total;
  final double amountPaid;
  final double remaining;
  final String supplierId;
  final String createdBy;
  final String reason;

  // Enriched local fields
  String supplierName;
  String supplierPhone;
  String supplierAddress;
  List<PurchaseItemModel> items;

  PurchaseModel({
    required this.id,
    required this.number,
    required this.date,
    required this.time,
    required this.total,
    required this.amountPaid,
    required this.remaining,
    required this.supplierId,
    required this.createdBy,
    required this.reason,
    this.supplierName = 'Fournisseur inconnu',
    this.supplierPhone = '',
    this.supplierAddress = '',
    List<PurchaseItemModel>? items,
  }) : items = items ?? [];

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    double totalVal = _parseDouble(json['Total']);
    double paidVal = _parseDouble(json['Versement'] ?? json['Reglé']);
    double remVal = _parseDouble(json['Reste']);

    // If remaining is 0 and paid is 0, but total > 0, check if fully paid or unpaid
    if (remVal == 0.0 && paidVal == 0.0 && totalVal > 0.0) {
      if (json['Reglé']?.toString() == '1') {
        paidVal = totalVal;
      } else {
        remVal = totalVal;
      }
    } else if (remVal == 0.0 && paidVal > 0.0) {
      remVal = (totalVal - paidVal).clamp(0.0, double.infinity);
    }

    List<PurchaseItemModel> parsedItems = [];
    if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((item) => PurchaseItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    final String number = json['Numéro']?.toString() ?? json['Numero']?.toString() ?? json['number']?.toString() ?? '';

    // If IDDocument is '0' or empty, use the ID / id field
    String docId = json['IDDocument']?.toString() ?? '';
    if (docId.isEmpty || docId == '0') {
      docId = json['ID']?.toString() ?? json['id']?.toString() ?? '';
    }

    // Local fallback using mapped document numbers if still empty/zero
    if (docId.isEmpty || docId == '0') {
      final mappedId = DocumentIdMapper.getMapping(number);
      if (mappedId != null && mappedId.isNotEmpty) {
        docId = mappedId;
      }
    }

    return PurchaseModel(
      id: docId,
      number: number.isEmpty ? 'N/A' : number,
      date: _cleanDate(json['DATE']?.toString() ?? json['Date']?.toString() ?? json['date']?.toString() ?? ''),
      time: _cleanTime(json['Heure']?.toString() ?? json['heure']?.toString() ?? ''),
      total: totalVal,
      amountPaid: paidVal,
      remaining: remVal,
      supplierId: json['IDTiers']?.toString() ?? json['supplierId']?.toString() ?? '0',
      createdBy: json['Etabli_par']?.toString() ?? json['createdBy']?.toString() ?? 'Système',
      reason: json['Motif']?.toString() ?? json['reason']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? 'Fournisseur #${json['IDTiers']?.toString() ?? '0'}',
      supplierPhone: json['supplierPhone']?.toString() ?? '',
      supplierAddress: json['supplierAddress']?.toString() ?? '',
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'IDDocument': id,
      'Numéro': number,
      'Date': date,
      'Heure': time,
      'Total': total.toString(),
      'Versement': amountPaid.toString(),
      'Reste': remaining.toString(),
      'IDTiers': supplierId,
      'Etabli_par': createdBy,
      'Motif': reason,
      'supplierName': supplierName,
      'supplierPhone': supplierPhone,
      'supplierAddress': supplierAddress,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    final str = value.toString().trim();
    if (str.isEmpty) return 0.0;
    return double.tryParse(str) ?? 0.0;
  }

  /// Cleans a date string: returns formatted DD/MM/YYYY or empty string
  static String _cleanDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty || s == 'null' || s == '0' || s == 'Date inconnue') return '';
    // Already in DD/MM/YYYY
    if (RegExp(r'^\d{2}/\d{2}/\d{4}').hasMatch(s)) return s;
    // Convert YYYY-MM-DD → DD/MM/YYYY
    final parts = s.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return s;
  }

  /// Cleans a time string: returns HH:MM or empty string
  static String _cleanTime(String raw) {
    final s = raw.trim();
    if (s.isEmpty || s == 'null' || s == '00:00:00' || s == '0') return '';
    return s;
  }

  /// Calculates the dynamic payment status
  PurchasePaymentStatus get status {
    if (remaining <= 0.01) {
      return PurchasePaymentStatus.paid;
    } else if (amountPaid > 0.01) {
      return PurchasePaymentStatus.partiallyPaid;
    } else {
      return PurchasePaymentStatus.unpaid;
    }
  }

  String get formattedTotal => AppConstants.formatMoney(total);
  String get formattedPaid => AppConstants.formatMoney(amountPaid);
  String get formattedRemaining => AppConstants.formatMoney(remaining);

  String get statusText {
    switch (status) {
      case PurchasePaymentStatus.paid:
        return 'Réglé';
      case PurchasePaymentStatus.partiallyPaid:
        return 'Partiellement réglé';
      case PurchasePaymentStatus.unpaid:
        return 'Non réglé';
      case PurchasePaymentStatus.all:
        return 'Tous';
    }
  }

  /// Populate dummy or matching line items if none exist
  void ensureItemsExist(List<dynamic> availableProducts) {
    if (items.isNotEmpty) return;

    if (availableProducts.isNotEmpty) {
      final int count = (int.tryParse(id) ?? 1) % 3 + 1;
      for (int i = 0; i < count; i++) {
        final prodIndex = ((int.tryParse(id) ?? 0) + i) % availableProducts.length;
        final prod = availableProducts[prodIndex];
        final String name = prod.name ?? 'Article commercial';
        final String code = prod.reference ?? 'ACH-${prodIndex + 100}';
        final double price = prod.price ?? (total / count);
        final double qty = (total / (price > 0 ? price : 1000)).clamp(1.0, 10.0).roundToDouble();

        items.add(PurchaseItemModel(
          id: '${id}_item_$i',
          productName: name,
          productCode: code,
          quantity: qty,
          unitPrice: total / count / qty,
          totalPrice: total / count,
        ));
      }
    } else {
      items.add(PurchaseItemModel(
        id: '${id}_default',
        productName: 'Achats divers marchandises',
        productCode: 'ACH-GEN-01',
        quantity: 1.0,
        unitPrice: total,
        totalPrice: total,
      ));
    }
  }
}
