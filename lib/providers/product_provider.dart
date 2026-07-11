import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';
import '../services/api_service.dart';
import '../services/product_service.dart';

/// State Management Provider for Products Feature
class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ProductService _productService = ProductService();
  final ProductRepository _productRepository = ProductRepository();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  Set<String> _favoriteIds = {};

  // Getters
  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get allProducts => _allProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  String get searchQuery => _searchQuery;
  int get totalProductsCount => _allProducts.length;

  ProductProvider() {
    _loadFavoritesFromPrefs();
  }

  /// Load favorites from local SharedPreferences
  Future<void> _loadFavoritesFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? favs = prefs.getStringList('favorite_products');
      if (favs != null) {
        _favoriteIds = favs.toSet();
        _updateFavoritesInList();
        notifyListeners();
      }
    } catch (_) {
      // Ignore prefs errors
    }
  }

  /// Save favorites to SharedPreferences
  Future<void> _saveFavoritesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_products', _favoriteIds.toList());
    } catch (_) {
      // Ignore prefs errors
    }
  }

  void _updateFavoritesInList() {
    for (var p in _allProducts) {
      p.isFavorite = _favoriteIds.contains(p.id);
    }
  }

  /// Toggle favorite status for a product
  void toggleFavorite(String productId) {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    _updateFavoritesInList();
    _saveFavoritesToPrefs();
    notifyListeners();
  }

  /// Fetch products from remote API
  Future<void> loadProducts({bool isRefresh = false}) async {
    if (_allProducts.isNotEmpty && !isRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allProducts = await _apiService.fetchProducts();
      _updateFavoritesInList();
      _applyFilter();
    } catch (e) {
      _errorMessage = e.toString();
      _allProducts = [];
      _filteredProducts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filters products list based on search term (name or reference)
  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  /// Search a specific product by scanned barcode / reference / ID
  ProductModel? searchByBarcode(String code) {
    final cleanCode = code.trim().toLowerCase();
    if (cleanCode.isEmpty) return null;

    try {
      return _allProducts.firstWhere((p) {
        return p.barcode.toLowerCase() == cleanCode ||
               p.reference.toLowerCase() == cleanCode ||
               p.id.toLowerCase() == cleanCode ||
               p.name.toLowerCase().contains(cleanCode);
      });
    } catch (_) {
      return null;
    }
  }

  /// Internal filter logic applying case-insensitive matching on Name and Reference
  void _applyFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredProducts = List.from(_allProducts);
    } else {
      final queryLower = _searchQuery.trim().toLowerCase();
      _filteredProducts = _allProducts.where((product) {
        final matchName = product.name.toLowerCase().contains(queryLower);
        final matchRef = product.reference.toLowerCase().contains(queryLower);
        final matchBarcode = product.barcode.toLowerCase().contains(queryLower);
        return matchName || matchRef || matchBarcode;
      }).toList();
    }
  }

  /// Clears active search filter
  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      _applyFilter();
      notifyListeners();
    }
  }

  /// Update product on remote API and refresh locally
  Future<void> updateProduct({
    required String id,
    required String libelle,
    required double qte,
    required double prixVente,
    required double prixAchat,
    required String reference,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _productService.updateProduit(
        idProduit: id,
        libelle: libelle,
        qte: qte,
        prixVente: prixVente,
        prixAchat: prixAchat,
        reference: reference,
      );
      // Reload products list to be offline-safe and keep everything synced
      await loadProducts(isRefresh: true);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new product and automatically refresh list on success
  Future<void> addProduct({
    required String libelle,
    required double qte,
    required double prixVente,
    required double prixAchat,
    required String reference,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _productRepository.addProduct(
        libelle: libelle,
        qte: qte,
        prixVente: prixVente,
        prixAchat: prixAchat,
        reference: reference,
      );
      // Reload products catalog automatically
      await loadProducts(isRefresh: true);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    _productService.dispose();
    super.dispose();
  }
}
