/// Model representing a single item line to be sold and inserted into a SAGE document.
/// Mirror of PurchaseLineModel — only difference is price used for Total (PrixVente vs PrixAchat).
class SaleLineModel {
  final String productId;   // IDProduit
  final String designation; // Designation
  final String reference;   // Reference
  double quantity;          // Qte
  double purchasePrice;     // PrixAchat
  double sellingPrice;      // PrixVente (used for total in sales)
  double discount;          // Remise in percentage (%)
  final String unit;        // Unite

  SaleLineModel({
    required this.productId,
    required this.designation,
    required this.reference,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
    this.discount = 0.0,
    this.unit = 'PCS',
  });

  /// Total amount for this line (Selling Price * Qty, discounted)
  double get total => quantity * sellingPrice * (1 - discount / 100);

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
        .replaceAll('\'', ' ')
        .replaceAll('"', ' ');

    final RegExp safeChars = RegExp(r'[^A-Za-z0-9\s\-\/\(\)\.,]');
    decoded = decoded.replaceAll(safeChars, ' ');
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
    final double lineTotal = quantity * sellingPrice * (1 - discount / 100);

    return {
      'IDLigneDocument': '0',
      'Qte': (quantity <= 0 ? 1.0 : quantity).toStringAsFixed(2),
      'Designation': desClean.isEmpty ? 'Article commercial' : desClean,
      'PrixVente': sellingPrice.toStringAsFixed(2),
      'Total': lineTotal.toStringAsFixed(2),
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
