import 'package:flutter/foundation.dart' show debugPrint, ChangeNotifier;
import '../models/client_model.dart';
import '../models/product_model.dart';
import '../models/sale_line_model.dart';
import '../services/sale_api_service.dart';
import '../utils/document_id_mapper.dart';
import 'product_provider.dart';
import 'sales_provider.dart';

/// Provider managing state for creating a new sale document (Cart, Client, Totals, Save Transaction).
/// Mirror of PurchaseProvider — only difference: Type=6, stock is DECREASED.
class SaleProvider extends ChangeNotifier {
  final SaleApiService _service = SaleApiService();

  ClientModel? _selectedClient;
  final List<SaleLineModel> _cartLines = [];

  double _paidAmount = 0.0;
  double _discountAmount = 0.0;
  bool _isSaving = false;
  String? _errorMessage;

  // ─── Getters ───────────────────────────────────────────────────────────────

  ClientModel? get selectedClient => _selectedClient;
  List<SaleLineModel> get cartLines => _cartLines;
  double get paidAmount => _paidAmount;
  double get discountAmount => _discountAmount;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  // ─── Client selection ──────────────────────────────────────────────────────

  void selectClient(ClientModel client) {
    _selectedClient = client;
    notifyListeners();
  }

  void clearClient() {
    _selectedClient = null;
    notifyListeners();
  }

  // ─── Cart management ───────────────────────────────────────────────────────

  void addProductToCart(
    ProductModel product, {
    double quantity = 1.0,
    double? purchasePrice,
    double? sellingPrice,
    double discount = 0.0,
  }) {
    final existingIndex =
        _cartLines.indexWhere((line) => line.productId == product.id);

    if (existingIndex >= 0) {
      _cartLines[existingIndex].quantity += quantity;
      if (purchasePrice != null) {
        _cartLines[existingIndex].purchasePrice = purchasePrice;
      }
      if (sellingPrice != null) {
        _cartLines[existingIndex].sellingPrice = sellingPrice;
      }
      _cartLines[existingIndex].discount = discount;
    } else {
      _cartLines.add(SaleLineModel(
        productId: product.id,
        designation: product.name,
        reference: product.reference,
        quantity: quantity,
        purchasePrice: purchasePrice ?? product.purchasePrice,
        sellingPrice: sellingPrice ?? product.sellingPrice,
        discount: discount,
        unit: product.unit,
      ));
    }
    notifyListeners();
  }

  void updateCartLine(
    int index, {
    double? quantity,
    double? purchasePrice,
    double? sellingPrice,
    double? discount,
  }) {
    if (index >= 0 && index < _cartLines.length) {
      if (quantity != null) _cartLines[index].quantity = quantity;
      if (purchasePrice != null) _cartLines[index].purchasePrice = purchasePrice;
      if (sellingPrice != null) _cartLines[index].sellingPrice = sellingPrice;
      if (discount != null) _cartLines[index].discount = discount;
      notifyListeners();
    }
  }

  void removeProductFromCart(int index) {
    if (index >= 0 && index < _cartLines.length) {
      _cartLines.removeAt(index);
      notifyListeners();
    }
  }

  void setPaidAmount(double value) {
    _paidAmount = value;
    notifyListeners();
  }

  void setDiscountAmount(double value) {
    _discountAmount = value;
    notifyListeners();
  }

  void clearForm() {
    _selectedClient = null;
    _cartLines.clear();
    _paidAmount = 0.0;
    _discountAmount = 0.0;
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Automatic calculations ────────────────────────────────────────────────

  double get subtotalHT =>
      _cartLines.fold(0.0, (sum, item) => sum + item.total);

  double get vatAmount => subtotalHT * 0.19;

  double get totalTTC {
    final rawTotal = subtotalHT + vatAmount - _discountAmount;
    return rawTotal.clamp(0.0, double.infinity);
  }

  /// Benefit = Total HT - Sum of (PrixAchat * Qty) for each line
  double get totalBenefit {
    final costTotal =
        _cartLines.fold(0.0, (s, l) => s + l.purchasePrice * l.quantity);
    return subtotalHT - costTotal;
  }

  double get remainingAmount {
    final rawRemaining = totalTTC - _paidAmount;
    return rawRemaining.clamp(0.0, double.infinity);
  }

  // ─── Transaction logic ─────────────────────────────────────────────────────

  /// STEP 1 → STEP 2 → STEP 3 following the same Master-Detail workflow as Purchase
  Future<void> saveSale({
    required ProductProvider productProvider,
    required SalesProvider salesProvider,
    required String docNumber,
  }) async {
    if (_selectedClient == null) {
      throw SaleApiException('Veuillez sélectionner un client.');
    }
    if (_cartLines.isEmpty) {
      throw SaleApiException('Le panier de vente est vide.');
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    String? createdDocId;

    try {
      // ── STEP 1: Create Sale Document (Type=6) ──────────────────────────────
      createdDocId = await _service.insertDocument(
        number: docNumber,
        clientId: _selectedClient!.databaseId.isNotEmpty
            ? _selectedClient!.databaseId
            : _selectedClient!.id,
        total: totalTTC,
        paid: _paidAmount,
        remaining: remainingAmount,
        discount: _discountAmount,
        benefit: totalBenefit,
      );

      if (createdDocId.isEmpty || createdDocId == '0') {
        throw SaleApiException(
          'IDDocument retourné invalide ("$createdDocId").',
        );
      }

      await DocumentIdMapper.saveMapping(docNumber, createdDocId);

      debugPrint('SALE: Document créé IDDocument=$createdDocId');
      debugPrint('SALE: Insertion de ${_cartLines.length} ligne(s)...');

      // ── STEP 2: Insert all lines sequentially ──────────────────────────────
      for (int i = 0; i < _cartLines.length; i++) {
        final line = _cartLines[i];
        debugPrint(
          'SALE: Ligne ${i + 1}/${_cartLines.length}: ${line.designation} IDDocument=$createdDocId',
        );
        await _service.insertDocumentLine(
          documentId: createdDocId,
          orderIndex: i + 1,
          line: line,
        );
      }

      debugPrint('SALE: Toutes les lignes insérées. Mise à jour du stock...');

      // ── STEP 3: Decrease stock for each sold product ───────────────────────
      for (final line in _cartLines) {
        double currentStock = 0.0;
        try {
          final prod = productProvider.allProducts
              .firstWhere((p) => p.id == line.productId);
          currentStock = prod.quantity;
        } catch (_) {}

        // Sales DECREASE stock
        final double newStock =
            (currentStock - line.quantity).clamp(0.0, double.infinity);

        await _service.updateStockAndProduct(
          idProduit: line.productId,
          libelle: line.designation,
          newStockQte: newStock,
          prixVente: line.sellingPrice,
          prixAchat: line.purchasePrice,
          reference: line.reference,
        );
      }

      debugPrint('SALE: ✅ Vente enregistrée avec succès.');

      // ── STEP 4: Refresh app state ──────────────────────────────────────────
      clearForm();
      await salesProvider.loadSales(forceRefresh: true);
      await productProvider.loadProducts(isRefresh: true);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
