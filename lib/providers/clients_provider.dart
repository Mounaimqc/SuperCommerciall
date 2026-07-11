import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../repositories/client_repository.dart';
import '../services/api_service.dart';

/// Available sorting options for clients list
enum ClientSortOption {
  nameAsc,      // Nom (A -> Z)
  nameDesc,     // Nom (Z -> A)
  codeAsc,      // Code Client (A -> Z)
  soldeDesc,    // Solde (Plus élevé d'abord)
  soldeAsc,     // Solde (Plus bas d'abord)
  phoneFirst,   // Avec téléphone en premier
}

/// State Management Provider for Clients Feature
class ClientsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ClientRepository _clientRepository = ClientRepository();

  List<ClientModel> _allClients = [];
  List<ClientModel> _filteredClients = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  ClientSortOption _currentSortOption = ClientSortOption.nameAsc;

  // Getters
  List<ClientModel> get clients => _filteredClients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  String get searchQuery => _searchQuery;
  int get totalClientsCount => _allClients.length;
  ClientSortOption get currentSortOption => _currentSortOption;

  /// Returns the human-readable French label for current sort option
  String get sortOptionLabel {
    switch (_currentSortOption) {
      case ClientSortOption.nameAsc:
        return 'Nom (A -> Z)';
      case ClientSortOption.nameDesc:
        return 'Nom (Z -> A)';
      case ClientSortOption.codeAsc:
        return 'Code Client';
      case ClientSortOption.soldeDesc:
        return 'Solde (Plus élevé)';
      case ClientSortOption.soldeAsc:
        return 'Solde (Plus bas)';
      case ClientSortOption.phoneFirst:
        return 'Avec téléphone d\'abord';
    }
  }

  /// Change active sort criterion and re-apply filter
  void setSortOption(ClientSortOption option) {
    if (_currentSortOption != option) {
      _currentSortOption = option;
      _applyFilter();
      notifyListeners();
    }
  }

  /// Fetch clients from remote API
  Future<void> loadClients({bool isRefresh = false}) async {
    if (_allClients.isNotEmpty && !isRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allClients = await _apiService.fetchClients();
      _applyFilter();
    } catch (e) {
      _errorMessage = e.toString();
      _allClients = [];
      _filteredClients = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filters clients list based on search term
  void searchClients(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  /// Internal filter & sort logic applying case-insensitive matching and sorting
  void _applyFilter() {
    // 1. Filter by search query
    if (_searchQuery.trim().isEmpty) {
      _filteredClients = List.from(_allClients);
    } else {
      final queryLower = _searchQuery.trim().toLowerCase();
      _filteredClients = _allClients.where((client) {
        final matchName = client.name.toLowerCase().contains(queryLower);
        final matchCode = client.code.toLowerCase().contains(queryLower);
        final matchCity = client.city.toLowerCase().contains(queryLower);
        final matchPhone = client.phone.contains(queryLower);
        return matchName || matchCode || matchCity || matchPhone;
      }).toList();
    }

    // 2. Sort results based on current sort option
    switch (_currentSortOption) {
      case ClientSortOption.nameAsc:
        _filteredClients.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ClientSortOption.nameDesc:
        _filteredClients.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case ClientSortOption.codeAsc:
        _filteredClients.sort((a, b) => a.code.compareTo(b.code));
        break;
      case ClientSortOption.soldeDesc:
        _filteredClients.sort((a, b) => b.solde.compareTo(a.solde));
        break;
      case ClientSortOption.soldeAsc:
        _filteredClients.sort((a, b) => a.solde.compareTo(b.solde));
        break;
      case ClientSortOption.phoneFirst:
        _filteredClients.sort((a, b) {
          final aHas = a.phone.isNotEmpty ? 0 : 1;
          final bHas = b.phone.isNotEmpty ? 0 : 1;
          if (aHas != bHas) return aHas.compareTo(bHas);
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
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

  /// Create a new client and refresh list automatically
  Future<void> addClient({
    required String nom,
    required String adresse,
    required String telephone,
    required String nis,
    required String nai,
    required String nif,
    required double solde,
    required String ajoutePar,
    required String nrc,
    required String rib,
    required String note,
    required String facebook,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _clientRepository.addClient(
        nom: nom,
        adresse: adresse,
        telephone: telephone,
        nis: nis,
        nai: nai,
        nif: nif,
        solde: solde,
        ajoutePar: ajoutePar,
        nrc: nrc,
        rib: rib,
        note: note,
        facebook: facebook,
      );
      // Reload clients list automatically on success
      await loadClients(isRefresh: true);
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
    super.dispose();
  }
}
