import 'package:flutter/material.dart';

import '../models/fournisseur_model.dart';
import '../models/product_model.dart';
import '../models/purchase_line_model.dart';
import '../services/purchase_service.dart';
import '../utils/document_id_mapper.dart';
import 'product_provider.dart';
import 'purchases_provider.dart';

/// Provider managing state for creating a new purchase document (Cart, Supplier, Totals, Save Transaction)
class PurchaseProvider extends ChangeNotifier {
  final PurchaseService _service = PurchaseService();

  FournisseurModel? _selectedSupplier;
  final List<PurchaseLineModel> _cartLines = [];
  
  double _paidAmount = 0.0;
  double _discountAmount = 0.0;
  bool _isSaving = false;
  String? _errorMessage;

  // Getters
  FournisseurModel? get selectedSupplier => _selectedSupplier;
  List<PurchaseLineModel> get cartLines => _cartLines;
  double get paidAmount => _paidAmount;
  double get discountAmount => _discountAmount;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// Select a supplier for the purchase
  void selectSupplier(FournisseurModel supplier) {
    _selectedSupplier = supplier;
    notifyListeners();
  }

  /// Remove active supplier selection
  void clearSupplier() {
    _selectedSupplier = null;
    notifyListeners();
  }

  /// Add product to cart, or increment quantity if already in cart
  void addProductToCart(
    ProductModel product, {
    double quantity = 1.0,
    double? purchasePrice,
    double? sellingPrice,
    double discount = 0.0,
  }) {
    final existingIndex = _cartLines.indexWhere((line) => line.productId == product.id);

    if (existingIndex >= 0) {
      _cartLines[existingIndex].quantity += quantity;
      if (purchasePrice != null) _cartLines[existingIndex].purchasePrice = purchasePrice;
      if (sellingPrice != null) _cartLines[existingIndex].sellingPrice = sellingPrice;
      _cartLines[existingIndex].discount = discount;
    } else {
      _cartLines.add(PurchaseLineModel(
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

  /// Edit quantities or prices of a line in the cart
  void updateCartLine(int index, {double? quantity, double? purchasePrice, double? sellingPrice, double? discount}) {
    if (index >= 0 && index < _cartLines.length) {
      if (quantity != null) {
        _cartLines[index].quantity = quantity;
      }
      if (purchasePrice != null) {
        _cartLines[index].purchasePrice = purchasePrice;
      }
      if (sellingPrice != null) {
        _cartLines[index].sellingPrice = sellingPrice;
      }
      if (discount != null) {
        _cartLines[index].discount = discount;
      }
      notifyListeners();
    }
  }

  /// Remove item from cart
  void removeProductFromCart(int index) {
    if (index >= 0 && index < _cartLines.length) {
      _cartLines.removeAt(index);
      notifyListeners();
    }
  }

  /// Set user paid amount input
  void setPaidAmount(double value) {
    _paidAmount = value;
    notifyListeners();
  }

  /// Set discount amount input
  void setDiscountAmount(double value) {
    _discountAmount = value;
    notifyListeners();
  }

  /// Clear the entire form (supplier, cart lines, paid, discount)
  void clearForm() {
    _selectedSupplier = null;
    _cartLines.clear();
    _paidAmount = 0.0;
    _discountAmount = 0.0;
    _errorMessage = null;
    notifyListeners();
  }

  // ----------------------------------------------------
  // AUTOMATIC CALCULATIONS
  // ----------------------------------------------------
  
  double get subtotalHT {
    return _cartLines.fold(0.0, (sum, item) => sum + item.total);
  }

  double get vatAmount {
    // 19% SAGE TVA
    return subtotalHT * 0.19;
  }

  double get totalTTC {
    final rawTotal = subtotalHT + vatAmount - _discountAmount;
    return rawTotal.clamp(0.0, double.infinity);
  }

  double get remainingAmount {
    final rawRemaining = totalTTC - _paidAmount;
    return rawRemaining.clamp(0.0, double.infinity);
  }

  // ----------------------------------------------------
  // TRANSACTION LOGIC (SAVE DOCUMENT -> SAVE LINES -> UPDATE STOCKS)
  // ----------------------------------------------------

  Future<void> savePurchase({
    required ProductProvider productProvider,
    required PurchasesProvider purchasesProvider,
    required String docNumber,
  }) async {
    if (_selectedSupplier == null) {
      throw PurchaseApiException('Veuillez sélectionner un fournisseur.');
    }
    if (_cartLines.isEmpty) {
      throw PurchaseApiException('Le panier d\'achat est vide.');
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    String? createdDocId;

    try {
      // 1. Create Document
      createdDocId = await _service.insertDocument(
        number: docNumber,
        supplierId: _selectedSupplier!.id,
        total: totalTTC,
        paid: _paidAmount,
        remaining: remainingAmount,
        discount: _discountAmount,
      );

      if (createdDocId.isEmpty || createdDocId == '0') {
        throw PurchaseApiException('Échec STEP 4: IDDocument retourné invalide ("$createdDocId").');
      }

      await DocumentIdMapper.saveMapping(docNumber, createdDocId);

      debugPrint('==================================================');
      debugPrint('STEP 4: STARTING MASTER-DETAIL LINE INSERTION');
      debugPrint('Master IDDocument = $createdDocId');
      debugPrint('Total Cart Lines = ${_cartLines.length}');
      debugPrint('==================================================');

      // STEP 6: Insert every line sequentially. Wait until one request finishes before sending the next one.
      // STEP 7: If one insertion fails, stop the process and display exact server response.
      for (int i = 0; i < _cartLines.length; i++) {
        final line = _cartLines[i];
        debugPrint('Inserting Line ${i + 1}/${_cartLines.length}: ${line.designation} with IDDocument=$createdDocId');
        await _service.insertDocumentLine(
          documentId: createdDocId,
          orderIndex: i + 1,
          line: line,
        );
      }

      debugPrint('==================================================');
      debugPrint('STEP 8: ALL LINES INSERTED SUCCESSFULLY. NOW UPDATING STOCKS.');
      debugPrint('==================================================');

      // 3. Update stock (Only after all lines have been inserted successfully)
      for (final line in _cartLines) {
        // Find existing product to calculate NewStock
        double currentStock = 0.0;
        try {
          final prod = productProvider.allProducts.firstWhere((p) => p.id == line.productId);
          currentStock = prod.quantity;
        } catch (_) {}

        final double newStock = currentStock + line.quantity;

        await _service.updateStockAndProduct(
          idProduit: line.productId,
          libelle: line.designation,
          newStockQte: newStock,
          prixVente: line.sellingPrice,
          prixAchat: line.purchasePrice,
          reference: line.reference,
        );
      }

      // 4. Refresh other states inside app
      // Clear form
      clearForm();

      // Trigger automatic refreshes
      await purchasesProvider.fetchPurchases(forceRefresh: true);
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
