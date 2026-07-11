/// Model representing a single item line to be purchased and inserted into a SAGE document
class PurchaseLineModel {
  final String productId; // IDProduit
  final String designation; // Designation
  final String reference; // Reference
  double quantity; // Qte
  double purchasePrice; // PrixAchat
  double sellingPrice; // PrixVente
  double discount; // Remise in percentage (%)
  final String unit; // Unite

  PurchaseLineModel({
    required this.productId,
    required this.designation,
    required this.reference,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
    this.discount = 0.0,
    this.unit = 'PCS',
  });

  /// Total amount for this line (Purchase Price * Qty, discounted)
  double get total => quantity * purchasePrice * (1 - discount / 100);

  /// Formatted total price in DZD
  String get formattedTotal => '${total.toStringAsFixed(2)} DZD';

  String _sanitize(String val) {
    String decoded = val;
    try {
      decoded = Uri.decodeComponent(val);
    } catch (_) {
      try {
        decoded = Uri.decodeFull(val);
      } catch (_) {}
    }

    // Convert accents and non-ASCII chars
    decoded = decoded
        .replaceAll('²', '2')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('ù', 'u')
        .replaceAll('ô', 'o')
        .replaceAll('î', 'i')
        .replaceAll('É', 'E')
        .replaceAll('È', 'E')
        .replaceAll('À', 'A')
        .replaceAll('Ç', 'C')
        .replaceAll('\'', ' ') // Replace single quotes with space (prevents SQL break)
        .replaceAll('"', ' '); // Replace double quotes with space

    // Keep only alphanumeric and safe commercial punctuation/symbols
    final RegExp safeChars = RegExp(r'[^A-Za-z0-9\s\-\/\(\)\.\,]');
    decoded = decoded.replaceAll(safeChars, ' ');

    // Normalize multiple spaces
    decoded = decoded.replaceAll(RegExp(r'\s+'), ' ');

    return decoded.trim();
  }

  /// Convert to JSON parameter map for Insert_LigneDocument.php
  Map<String, String> toParamMap({
    required String documentId,
    required int orderIndex,
  }) {
    final desClean = _sanitize(designation);
    final refClean = _sanitize(reference);
    final double dbLineTotal = quantity * purchasePrice * (1 - discount / 100);

    return {
      'IDLigneDocument': '0', // Server generates if 0
      'Qte': (quantity <= 0 ? 1.0 : quantity).toStringAsFixed(2),
      'Designation': desClean.isEmpty ? 'Article commercial' : desClean,
      'PrixVente': sellingPrice.toStringAsFixed(2),
      'Total': dbLineTotal.toStringAsFixed(2),
      'IDDocument': documentId.trim().isEmpty ? '0' : documentId.trim(),
      'NumeroOrdre': (orderIndex <= 0 ? 1 : orderIndex).toString(),
      'IDProduit': productId.trim().isEmpty ? '0' : productId.trim(),
      'PrixAchat': purchasePrice.toStringAsFixed(2),
      'QteParColis': '0',
      'QtéParColis': '0',
      'PrixVenteColis': '0.00',
      'PrixVenteInitial': sellingPrice.toStringAsFixed(2),
      'IDLot': '0',
      'Colis': '0',
      'Reference': refClean.isEmpty ? 'REF-001' : refClean,
      'IDTaille_Produit': '0',
      'ColisParPalette': '0',
      'Palette': '0',
      'Unite': unit.trim().isEmpty ? 'PCS' : unit.trim(),
    };
  }
}
