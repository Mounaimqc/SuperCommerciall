import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client_model.dart';
import '../models/sale_model.dart';
import '../services/sales_service.dart';

import '../utils/constants.dart';

/// State Management Provider for Sales Module
class SalesProvider extends ChangeNotifier {
  final SalesService _salesService = SalesService();

  List<SaleModel> _allSales = [];
  List<SaleModel> _filteredSales = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  PaymentStatus _currentFilter = PaymentStatus.all;
  String _startDate = '';
  String _endDate = '';

  SalesProvider() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _startDate = todayStr;
    _endDate = todayStr;
  }

  // Getters
  List<SaleModel> get sales => _filteredSales;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  String get searchQuery => _searchQuery;
  PaymentStatus get currentFilter => _currentFilter;
  String get startDate => _startDate;
  String get endDate => _endDate;

  // Statistics Getters based on currently displayed/filtered sales
  int get totalSalesCount => _filteredSales.length;

  double get totalSalesAmount {
    return _filteredSales.fold(0.0, (sum, item) => sum + item.total);
  }

  double get totalRemainingAmount {
    return _filteredSales.fold(0.0, (sum, item) => sum + item.remaining);
  }

  String get formattedTotalSalesAmount => AppConstants.formatMoney(totalSalesAmount);
  String get formattedTotalRemainingAmount => AppConstants.formatMoney(totalRemainingAmount);

  /// Load sales from API or SharedPreferences cache
  Future<void> loadSales({
    bool forceRefresh = false,
    List<ClientModel>? availableClients,
    List<dynamic>? availableProducts,
  }) async {
    if (_allSales.isNotEmpty && !forceRefresh) {
      _enrichSalesData(availableClients, availableProducts);
      _applyFilters();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedSales = await _salesService.fetchSales(
        startDate: _startDate,
        endDate: _endDate,
      );

      _allSales = fetchedSales;
      _enrichSalesData(availableClients, availableProducts);
      _saveToCache();
      _errorMessage = null;
    } catch (e) {
      // If network fails, attempt to load from local SharedPreferences cache
      final loadedFromCache = await _loadFromCache();
      if (!loadedFromCache || _allSales.isEmpty) {
        _errorMessage = e.toString();
      } else {
        _enrichSalesData(availableClients, availableProducts);
      }
    } finally {
      _isLoading = false;
      _applyFilters();
    }
  }

  /// Enrich sale models with Client information and line items
  void _enrichSalesData(List<ClientModel>? availableClients, List<dynamic>? availableProducts) {
    if (availableClients != null && availableClients.isNotEmpty) {
      final Map<String, ClientModel> clientMap = {};
      for (var c in availableClients) {
        if (c.databaseId.isNotEmpty) clientMap[c.databaseId] = c;
        if (c.id.isNotEmpty) clientMap[c.id] = c;
        if (c.code.isNotEmpty) {
          clientMap[c.code] = c;
          // Extract numeric digits without leading zeroes (e.g., CL001066 -> 1066)
          final digits = c.code.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^0+'), '');
          if (digits.isNotEmpty) clientMap[digits] = c;
        }
      }

      for (var sale in _allSales) {
        final cleanId = sale.clientId.trim().replaceFirst(RegExp(r'^0+'), '');
        final client = clientMap[sale.clientId] ??
            clientMap[cleanId] ??
            clientMap['CL00$cleanId'] ??
            clientMap['CL0$cleanId'] ??
            clientMap['CL$cleanId'];

        if (client != null) {
          sale.clientName = client.name.isNotEmpty ? client.name : 'Client #${sale.clientId}';
          sale.clientPhone = client.phone;
          sale.clientAddress = '${client.address}, ${client.city}';
        } else if (sale.clientName == 'Client inconnu') {
          // Attempt a reverse search on client code endsWith
          try {
            final match = availableClients.firstWhere(
              (c) => c.code.endsWith(cleanId) || c.databaseId == cleanId || c.id == cleanId,
            );
            sale.clientName = match.name.isNotEmpty ? match.name : 'Client #${sale.clientId}';
            sale.clientPhone = match.phone;
            sale.clientAddress = '${match.address}, ${match.city}';
          } catch (_) {
            sale.clientName = 'Client #${sale.clientId}';
          }
        }
      }
    }

    for (var sale in _allSales) {
      sale.ensureItemsExist(availableProducts ?? []);
    }
  }

  /// Update search filter query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Update payment status filter
  void setPaymentFilter(PaymentStatus status) {
    _currentFilter = status;
    _applyFilters();
  }

  /// Update date range filter
  void setDateRange(String start, String end) {
    _startDate = start;
    _endDate = end;
    loadSales(forceRefresh: true);
  }

  /// Apply active filters (search query and status)
  void _applyFilters() {
    _filteredSales = _allSales.where((sale) {
      // Status filter
      if (_currentFilter != PaymentStatus.all && sale.status != _currentFilter) {
        return false;
      }

      // Search query filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchNum = sale.number.toLowerCase().contains(q);
        final matchClient = sale.clientName.toLowerCase().contains(q);
        final matchId = sale.clientId.toLowerCase().contains(q);
        final matchTotal = sale.total.toStringAsFixed(2).contains(q);

        if (!matchNum && !matchClient && !matchId && !matchTotal) {
          return false;
        }
      }

      return true;
    }).toList();

    notifyListeners();
  }

  /// Find a specific sale by its ID or document number
  SaleModel? getSaleById(String idOrNumber) {
    try {
      return _allSales.firstWhere(
        (s) => s.id == idOrNumber || s.number == idOrNumber,
      );
    } catch (_) {
      return null;
    }
  }

  /// Save sales to local SharedPreferences JSON cache
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _allSales.map((s) => s.toJson()).toList();
      await prefs.setString('cached_sales_data', jsonEncode(jsonList));
    } catch (_) {
      // Ignore cache storage errors
    }
  }

  /// Load sales from local SharedPreferences JSON cache
  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString('cached_sales_data');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        _allSales = jsonList
            .map((item) => SaleModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return true;
      }
    } catch (_) {
      // Ignore cache read errors
    }
    return false;
  }
}
