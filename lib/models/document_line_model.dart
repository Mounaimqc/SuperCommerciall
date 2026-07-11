/// Model representing a single line item inside a Sale or Purchase Document.
/// Fields mapped from: Liste_LigneDoc.php
/// API fields: ID, IDLigneDocument, Qté, PrixVente, Total, IDDocument,
///             NuméroOrdre, IDProduit, PrixAchat, Désignation, QtéParColis,
///             PrixVenteColis, PrixVenteInitial, IDLot, Colis, Reference,
///             IDTaille_Produit, ColisParPalette, Palette, Unite, rayonnage
class DocumentLineModel {
  final String id;               // ID (primary key returned by API)
  final String idLigneDocument;  // IDLigneDocument
  final String idDocument;       // IDDocument
  final String productId;        // IDProduit
  final String designation;      // Désignation
  final String reference;        // Reference
  final String barcode;          // Barcode (fallback to reference)
  final double quantity;         // Qté
  final double sellingPrice;     // PrixVente
  final double purchasePrice;    // PrixAchat
  final double total;            // Total
  final String unit;             // Unite
  final double discount;         // Remise
  final double vat;              // TVA

  // Package & Storage fields
  final double packageQuantity;   // QtéParColis
  final double sellingPriceColis; // PrixVenteColis
  final double initialSellingPrice; // PrixVenteInitial
  final double colis;             // Colis
  final double colisParPalette;   // ColisParPalette
  final double palette;           // Palette

  // Identification fields
  final String lotNumber;         // IDLot
  final String size;              // IDTaille_Produit
  final String rayonnage;         // rayonnage
  final String numeroOrdre;       // NuméroOrdre
  final String variant;           // Variant / Couleur

  DocumentLineModel({
    required this.id,
    this.idLigneDocument = '0',
    this.idDocument = '0',
    required this.productId,
    required this.designation,
    required this.reference,
    required this.barcode,
    required this.quantity,
    required this.sellingPrice,
    required this.purchasePrice,
    required this.total,
    required this.unit,
    this.discount = 0.0,
    this.vat = 19.0,
    this.packageQuantity = 0.0,
    this.sellingPriceColis = 0.0,
    this.initialSellingPrice = 0.0,
    this.colis = 0.0,
    this.colisParPalette = 0.0,
    this.palette = 0.0,
    this.lotNumber = '',
    this.size = '',
    this.rayonnage = '',
    this.numeroOrdre = '',
    this.variant = '',
  });

  /// Helper to safely clean dynamic values to strings
  static String _cleanString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    String str = value.toString().trim();
    try {
      str = Uri.decodeComponent(str);
    } catch (_) {}
    return str.isEmpty ? defaultValue : str;
  }

  /// Helper to safely parse double values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    final str = value.toString().trim();
    if (str.isEmpty) return 0.0;
    return double.tryParse(str) ?? 0.0;
  }

  /// Helper to clean zero-ish string values
  static String _cleanZero(String val) =>
      (val == '0' || val == '0.0') ? '' : val;

  /// Factory constructor to parse JSON maps from API response
  factory DocumentLineModel.fromJson(Map<String, dynamic> json) {
    final ref = _cleanString(json['Reference']);
    final idProd = _cleanString(json['IDProduit'], defaultValue: '0');

    // Barcode: explicit field or fallback to reference
    final explicitBarcode = _cleanString(
      json['CodeBarre'] ?? json['Code_Barre'] ?? json['Barcode'],
    );
    final barcode = explicitBarcode.isNotEmpty
        ? explicitBarcode
        : (ref.isNotEmpty ? ref : 'PROD-$idProd');

    // Designation — handles both accented and non-accented API keys
    final designation = _cleanString(
      json['Désignation'] ??
          json['Designation'] ??
          json['designation'] ??
          json['Libellé'] ??
          json['NOM'],
      defaultValue: 'Article sans désignation',
    );

    // Quantity — handles both accented and non-accented
    final quantity = _parseDouble(
      json['Qté'] ?? json['Qte'] ?? json['qte'] ?? json['Quantite'],
    );

    // Numéro d'ordre — handles both accented and non-accented
    final numOrdre = _cleanString(
      json['NuméroOrdre'] ?? json['NumeroOrdre'] ?? json['numeroOrdre'],
    );

    // Package quantity — handles both accented and non-accented
    final packageQty = _parseDouble(
      json['QtéParColis'] ?? json['QteParColis'],
    );

    // Lot number
    final lot = _cleanString(json['IDLot'] ?? json['Lot'], defaultValue: '');
    final lotClean = _cleanZero(lot);

    // Size
    final sz = _cleanString(
      json['IDTaille_Produit'] ?? json['Taille'],
      defaultValue: '',
    );
    final szClean = _cleanZero(sz);

    // Variant
    final varStr = _cleanString(
      json['Variant'] ?? json['Couleur'],
      defaultValue: '',
    );
    final varClean = _cleanZero(varStr);

    // Unit
    final rawUnit = _cleanString(json['Unite']);
    final unitClean =
        (rawUnit.isEmpty || rawUnit == '0' || rawUnit == '0.0') ? 'PCS' : rawUnit;

    return DocumentLineModel(
      id: _cleanString(json['ID'] ?? json['IDLigneDocument'], defaultValue: '0'),
      idLigneDocument: _cleanString(json['IDLigneDocument'], defaultValue: '0'),
      idDocument: _cleanString(json['IDDocument'], defaultValue: '0'),
      productId: idProd,
      designation: designation,
      reference: ref,
      barcode: barcode,
      quantity: quantity,
      sellingPrice: _parseDouble(json['PrixVente'] ?? json['prixVente']),
      purchasePrice: _parseDouble(json['PrixAchat'] ?? json['prixAchat']),
      total: _parseDouble(json['Total'] ?? json['total']),
      unit: unitClean,
      discount: _parseDouble(json['Remise']),
      vat: _parseDouble(json['TVA'] ?? 19.0),
      packageQuantity: packageQty,
      sellingPriceColis: _parseDouble(json['PrixVenteColis']),
      initialSellingPrice: _parseDouble(json['PrixVenteInitial']),
      colis: _parseDouble(json['Colis']),
      colisParPalette: _parseDouble(json['ColisParPalette']),
      palette: _parseDouble(json['Palette']),
      lotNumber: lotClean,
      size: szClean,
      rayonnage: _cleanString(json['rayonnage']),
      numeroOrdre: numOrdre,
      variant: varClean,
    );
  }

  /// Formatted prices in DZD
  String get formattedSellingPrice => '${sellingPrice.toStringAsFixed(2)} DZD';
  String get formattedPurchasePrice => '${purchasePrice.toStringAsFixed(2)} DZD';
  String get formattedTotal => '${total.toStringAsFixed(2)} DZD';
  String get formattedInitialSellingPrice => '${initialSellingPrice.toStringAsFixed(2)} DZD';
  String get formattedSellingPriceColis => '${sellingPriceColis.toStringAsFixed(2)} DZD';
}
