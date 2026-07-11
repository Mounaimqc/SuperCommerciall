import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client_model.dart';
import '../models/purchase_model.dart';
import '../services/purchases_service.dart';
import '../services/api_service.dart' show ApiException;

import '../utils/constants.dart';

/// Provider managing Purchases module state, filtering, stats, caching and creation
class PurchasesProvider with ChangeNotifier {
  final PurchasesService _service = PurchasesService();
  static const String _cacheKey = 'cached_sage_purchases_list_v1';

  List<PurchaseModel> _allPurchases = [];
  List<PurchaseModel> _filteredPurchases = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filters
  String _searchQuery = '';
  PurchasePaymentStatus _currentFilter = PurchasePaymentStatus.all;
  String _startDate = '';
  String _endDate = '';

  // Getters
  List<PurchaseModel> get purchases => _filteredPurchases;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  PurchasePaymentStatus get currentFilter => _currentFilter;
  String get startDate => _startDate;
  String get endDate => _endDate;

  // Statistics Getters
  int get totalPurchasesCount => _allPurchases.length;
  
  double get totalPurchasesAmount => _allPurchases.fold(0.0, (sum, item) => sum + item.total);
  
  double get totalPaidAmount => _allPurchases.fold(0.0, (sum, item) => sum + item.amountPaid);
  
  double get totalRemainingAmount => _allPurchases.fold(0.0, (sum, item) => sum + item.remaining);

  String get formattedTotalPurchases => AppConstants.formatMoney(totalPurchasesAmount);
  String get formattedTotalPaid => AppConstants.formatMoney(totalPaidAmount);
  String get formattedTotalRemaining => AppConstants.formatMoney(totalRemainingAmount);

  PurchasesProvider() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _startDate = todayStr;
    _endDate = todayStr;
    _loadFromCache();
  }

  /// Load cached purchases from SharedPreferences
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(cachedJson);
        _allPurchases = decoded.map((item) => PurchaseModel.fromJson(item as Map<String, dynamic>)).toList();
        _applyFilters();
        notifyListeners();
      }
    } catch (_) {
      // Ignore cache loading errors
    }
  }

  /// Save current purchases list to SharedPreferences
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(_allPurchases.map((item) => item.toJson()).toList());
      await prefs.setString(_cacheKey, encoded);
    } catch (_) {
      // Ignore cache saving errors
    }
  }

  /// Fetch remote purchases from SAGE API
  Future<void> fetchPurchases({
    bool forceRefresh = false,
    List<ClientModel>? availableClients,
    List<dynamic>? availableProducts,
  }) async {
    if (_isLoading) return;
    if (!forceRefresh && _allPurchases.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedList = await _service.fetchPurchases(
        startDate: _startDate,
        endDate: _endDate,
      );
      _allPurchases = fetchedList;
      _enrichPurchasesData(availableClients, availableProducts);
      _applyFilters();
      await _saveToCache();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (_allPurchases.isEmpty) {
        await _loadFromCache();
      }
    } catch (e) {
      _errorMessage = 'Une erreur est survenue lors du chargement des achats.';
      if (_allPurchases.isEmpty) {
        await _loadFromCache();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Enrich purchase models with Supplier/Tiers information and line items
  void _enrichPurchasesData(List<ClientModel>? availableClients, List<dynamic>? availableProducts) {
    if (availableClients != null && availableClients.isNotEmpty) {
      final Map<String, ClientModel> clientMap = {};
      for (var c in availableClients) {
        if (c.databaseId.isNotEmpty) clientMap[c.databaseId] = c;
        if (c.id.isNotEmpty) clientMap[c.id] = c;
        if (c.code.isNotEmpty) {
          clientMap[c.code] = c;
          final digits = c.code.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^0+'), '');
          if (digits.isNotEmpty) clientMap[digits] = c;
        }
      }

      for (var purchase in _allPurchases) {
        final cleanId = purchase.supplierId.trim().replaceFirst(RegExp(r'^0+'), '');
        final match = clientMap[purchase.supplierId] ??
            clientMap[cleanId] ??
            clientMap['CL00$cleanId'] ??
            clientMap['CL0$cleanId'] ??
            clientMap['CL$cleanId'];

        if (match != null) {
          purchase.supplierName = match.name.isNotEmpty ? match.name : 'Fournisseur #${purchase.supplierId}';
          purchase.supplierPhone = match.phone;
          purchase.supplierAddress = '${match.address}, ${match.city}';
        } else if (purchase.supplierName.startsWith('Fournisseur #') || purchase.supplierName == 'Fournisseur inconnu') {
          try {
            final fallback = availableClients.firstWhere(
              (c) => c.code.endsWith(cleanId) || c.databaseId == cleanId || c.id == cleanId,
            );
            purchase.supplierName = fallback.name.isNotEmpty ? fallback.name : 'Fournisseur #${purchase.supplierId}';
            purchase.supplierPhone = fallback.phone;
            purchase.supplierAddress = '${fallback.address}, ${fallback.city}';
          } catch (_) {
            if (purchase.supplierName == 'Fournisseur inconnu') {
              purchase.supplierName = 'Fournisseur #${purchase.supplierId}';
            }
          }
        }
      }
    }

    for (var purchase in _allPurchases) {
      purchase.ensureItemsExist(availableProducts ?? []);
    }
  }

  /// Add a new purchase locally (User request: "donner la main pour ajouter un achat")
  Future<void> addPurchase(PurchaseModel newPurchase) async {
    _allPurchases.insert(0, newPurchase);
    _applyFilters();
    await _saveToCache();
    notifyListeners();
  }

  /// Update search filter query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Update payment status filter
  void setPaymentFilter(PurchasePaymentStatus status) {
    _currentFilter = status;
    _applyFilters();
  }

  /// Update date range filter
  void setDateRange(String start, String end) {
    _startDate = start;
    _endDate = end;
    fetchPurchases(forceRefresh: true);
  }

  /// Apply active filters (search query + status) to _allPurchases
  void _applyFilters() {
    _filteredPurchases = _allPurchases.where((item) {
      // 1. Status Filter
      if (_currentFilter != PurchasePaymentStatus.all && item.status != _currentFilter) {
        return false;
      }

      // 2. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchNumber = item.number.toLowerCase().contains(q) || 'ach #${item.number}'.toLowerCase().contains(q);
        final matchSupplier = item.supplierName.toLowerCase().contains(q);
        final matchId = item.supplierId.contains(q);
        return matchNumber || matchSupplier || matchId;
      }

      return true;
    }).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
