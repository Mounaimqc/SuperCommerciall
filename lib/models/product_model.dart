import '../utils/constants.dart';

/// Product Model representing an inventory item from the SAGE API (liste_stock.php)
class ProductModel {
  final String id;
  final String name;
  final String reference;
  final String barcode;
  final double quantity;
  final double alertQuantity;
  final double sellingPrice;
  final double purchasePrice;
  final String? imageUrl;
  final String category;
  final String unit;
  final String brand;
  final String lastUpdate;
  bool isFavorite;

  ProductModel({
    required this.id,
    required this.name,
    required this.reference,
    required this.barcode,
    required this.quantity,
    required this.alertQuantity,
    required this.sellingPrice,
    required this.purchasePrice,
    this.imageUrl,
    required this.category,
    required this.unit,
    required this.brand,
    required this.lastUpdate,
    this.isFavorite = false,
  });

  /// Helper to safely clean strings
  static String _cleanString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    final str = value.toString().trim();
    return str.isEmpty ? defaultValue : str;
  }

  /// Helper to safely parse double values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    final str = value.toString().trim();
    if (str.isEmpty) return 0.0;
    return double.tryParse(str) ?? 0.0;
  }

  /// Factory method to create a [ProductModel] from a JSON map
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final id = _cleanString(json['IDProduit'], defaultValue: '0');
    final name = _cleanString(json['Libellé'], defaultValue: 'Produit sans nom');
    
    // Reference fallback
    final rawRef = _cleanString(json['Reference']);
    final reference = rawRef.isNotEmpty ? rawRef : 'REF-$id';

    // Barcode fallback (Raccourci, Reference, or generated 12/13 digit code for barcode rendering)
    final rawRaccourci = _cleanString(json['Raccourci']);
    String barcode = rawRaccourci;
    if (barcode.isEmpty) {
      barcode = rawRef;
    }
    if (barcode.isEmpty) {
      // Generate standard EAN numeric string so barcode_widget can render cleanly
      final paddedId = id.padLeft(6, '0');
      barcode = '300000$paddedId';
    }

    final unit = _cleanString(json['Unite'], defaultValue: 'PCS');
    final famId = _cleanString(json['IDFamilleProduit'], defaultValue: 'Général');
    final category = 'Famille $famId ($unit)';
    final brand = _cleanString(json['Marque'], defaultValue: 'SAGE Stock');
    
    final dateModif = _cleanString(json['DateModification']);
    final heureModif = _cleanString(json['HeureModification']);
    final lastUpdate = dateModif.isNotEmpty ? '$dateModif $heureModif'.trim() : 'Récemment';

    final rawImg = _cleanString(json['Image']);
    final imageUrl = (rawImg.isNotEmpty && rawImg != 'null' && rawImg != '0') ? rawImg : null;

    return ProductModel(
      id: id,
      name: name,
      reference: reference,
      barcode: barcode,
      quantity: _parseDouble(json['Qté']),
      alertQuantity: _parseDouble(json['QtéAlerte']),
      sellingPrice: _parseDouble(json['PrixVente']),
      purchasePrice: _parseDouble(json['PrixAchat']),
      imageUrl: imageUrl,
      category: category,
      unit: unit,
      brand: brand,
      lastUpdate: lastUpdate,
      isFavorite: false,
    );
  }

  /// Convert to JSON map for local cache storage
  Map<String, dynamic> toJson() {
    return {
      'IDProduit': id,
      'Libellé': name,
      'Reference': reference,
      'Raccourci': barcode,
      'Qté': quantity.toString(),
      'QtéAlerte': alertQuantity.toString(),
      'PrixVente': sellingPrice.toString(),
      'PrixAchat': purchasePrice.toString(),
      'Image': imageUrl,
      'IDFamilleProduit': category,
      'Unite': unit,
      'Marque': brand,
      'DateModification': lastUpdate,
      'isFavorite': isFavorite,
    };
  }

  /// Check if product is low on stock or out of stock
  bool get isOutOfStock => quantity <= 0;
  bool get isLowStock => quantity > 0 && quantity <= alertQuantity;

  String get formattedSellingPrice => AppConstants.formatMoney(sellingPrice);
  String get formattedPurchasePrice => AppConstants.formatMoney(purchasePrice);
}
