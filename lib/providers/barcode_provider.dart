import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/barcode_model.dart';
import '../models/product_model.dart';
import '../services/barcode_service.dart';

/// Provider managing multi-barcode mapping and caching for SAGE products
class BarcodeProvider with ChangeNotifier {
  final BarcodeService _service = BarcodeService();

  // Fast O(1) lookup map: Barcode String -> Product ID String
  final Map<String, String> _barcodeToProductMap = {};
  
  // Product ID -> List of associated BarcodeModel objects
  final Map<String, List<BarcodeModel>> _productBarcodesMap = {};
  
  bool _isLoading = false;
  bool _hasPreloaded = false;

  bool get isLoading => _isLoading;
  Map<String, String> get barcodeToProductMap => _barcodeToProductMap;

  BarcodeProvider() {
    _loadFromCache();
  }

  /// Load cached barcodes from SharedPreferences on app launch
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString('cached_barcodes_list');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> list = json.decode(cachedJson);
        for (final item in list) {
          final bm = BarcodeModel.fromJson(item);
          if (bm.barcode.isNotEmpty && bm.productId.isNotEmpty) {
            _barcodeToProductMap[bm.barcode.toLowerCase()] = bm.productId;
            _productBarcodesMap.putIfAbsent(bm.productId, () => []);
            if (!_productBarcodesMap[bm.productId]!.any((b) => b.barcode.toLowerCase() == bm.barcode.toLowerCase())) {
              _productBarcodesMap[bm.productId]!.add(bm);
            }
          }
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Save preloaded barcodes list to SharedPreferences
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> allList = [];
      for (final list in _productBarcodesMap.values) {
        allList.addAll(list.map((b) => b.toJson()));
      }
      await prefs.setString('cached_barcodes_list', json.encode(allList));
    } catch (_) {}
  }

  /// Initialize barcodes from loaded products and preload API in background
  Future<void> loadBarcodes(List<ProductModel> products, {bool forceRefresh = false}) async {
    if (_isLoading || (_hasPreloaded && !forceRefresh)) return;

    // 1. Immediately register all primary product barcodes & references into lookup map
    for (final p in products) {
      if (p.barcode.isNotEmpty) {
        _barcodeToProductMap[p.barcode.toLowerCase()] = p.id;
        final list = _productBarcodesMap.putIfAbsent(p.id, () => []);
        if (!list.any((b) => b.barcode.toLowerCase() == p.barcode.toLowerCase())) {
          list.insert(0, BarcodeModel(id: 'primary_${p.id}', productId: p.id, barcode: p.barcode));
        }
      }
      if (p.reference.isNotEmpty && p.reference != p.barcode) {
        _barcodeToProductMap[p.reference.toLowerCase()] = p.id;
      }
    }
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    try {
      // 2. Preload extra barcodes from SAGE server concurrently
      final List<BarcodeModel> fetched = await _service.preloadAllBarcodes(products);
      for (final bm in fetched) {
        if (bm.barcode.isNotEmpty && bm.productId.isNotEmpty) {
          _barcodeToProductMap[bm.barcode.toLowerCase()] = bm.productId;
          final list = _productBarcodesMap.putIfAbsent(bm.productId, () => []);
          if (!list.any((b) => b.barcode.toLowerCase() == bm.barcode.toLowerCase())) {
            list.add(bm);
          }
        }
      }
      _hasPreloaded = true;
      await _saveToCache();
    } catch (e) {
      debugPrint('Error loading barcodes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retrieve all barcodes for a specific product when opening ProductDetailsScreen
  Future<List<BarcodeModel>> getBarcodesForProduct(ProductModel product) async {
    List<BarcodeModel> list = List.from(_productBarcodesMap[product.id] ?? []);

    // Ensure primary product barcode is always included first
    if (product.barcode.isNotEmpty && !list.any((b) => b.barcode.toLowerCase() == product.barcode.toLowerCase())) {
      list.insert(0, BarcodeModel(id: 'primary_${product.id}', productId: product.id, barcode: product.barcode));
    }

    // Fetch live from API for this specific product to guarantee full completeness
    try {
      final live = await _service.getBarcodesByProductId(product.id);
      bool modified = false;
      for (final bm in live) {
        if (bm.barcode.isNotEmpty && !list.any((existing) => existing.barcode.toLowerCase() == bm.barcode.toLowerCase())) {
          list.add(bm);
          _barcodeToProductMap[bm.barcode.toLowerCase()] = product.id;
          modified = true;
        }
      }
      if (modified || list.length != (_productBarcodesMap[product.id]?.length ?? 0)) {
        _productBarcodesMap[product.id] = list;
        _saveToCache();
        notifyListeners();
      }
    } catch (_) {}

    return list;
  }

  /// Associate/add a new barcode to a product
  Future<bool> addBarcodeToProduct(ProductModel product, String barcode, {int colis = 0}) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return false;

    // Call API
    final bool success = await _service.addBarcode(product.id, cleanBarcode, colis: colis);
    if (success) {
      // Add to local state mapping
      _barcodeToProductMap[cleanBarcode.toLowerCase()] = product.id;
      final list = _productBarcodesMap.putIfAbsent(product.id, () => []);
      if (!list.any((b) => b.barcode.toLowerCase() == cleanBarcode.toLowerCase())) {
        list.add(BarcodeModel(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          productId: product.id,
          barcode: cleanBarcode,
        ));
      }
      await _saveToCache();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Fast O(1) Lookup: find Product ID matching any scanned barcode or numeric code
  String? getProductIdByBarcode(String scannedBarcode) {
    final clean = scannedBarcode.trim().toLowerCase();
    if (clean.isEmpty) return null;
    return _barcodeToProductMap[clean];
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
