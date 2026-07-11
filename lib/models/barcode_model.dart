/// Barcode Model representing an individual barcode associated with a product
class BarcodeModel {
  final String id;
  final String productId;
  final String barcode;

  BarcodeModel({
    required this.id,
    required this.productId,
    required this.barcode,
  });

  /// Factory method to create [BarcodeModel] from JSON API response or local cache
  factory BarcodeModel.fromJson(Map<String, dynamic> json) {
    return BarcodeModel(
      id: (json['IDCodeBarre'] ?? json['id'] ?? '0').toString().trim(),
      productId: (json['IDProduit'] ?? json['productId'] ?? '0').toString().trim(),
      barcode: (json['CodeBarre'] ?? json['barcode'] ?? '').toString().trim(),
    );
  }

  /// Convert to JSON map for local caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'barcode': barcode,
    };
  }
}
