import 'package:flutter/material.dart';
import '../models/fournisseur_model.dart';
import '../repositories/supplier_repository.dart';
import '../services/fournisseur_service.dart';

/// Sorting options for suppliers list
enum FournisseurSortOption {
  nameAsc,      // Nom (A -> Z)
  nameDesc,     // Nom (Z -> A)
  soldeDesc,    // Solde / Achats (Plus élevé d'abord)
  soldeAsc,     // Solde / Achats (Plus bas d'abord)
}

/// Provider managing state for SAGE suppliers module
class FournisseurProvider extends ChangeNotifier {
  final FournisseurService _service = FournisseurService();
  final SupplierRepository _supplierRepository = SupplierRepository();

  List<FournisseurModel> _allFournisseurs = [];
  List<FournisseurModel> _filteredFournisseurs = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  FournisseurSortOption _currentSortOption = FournisseurSortOption.nameAsc;

  // Getters
  List<FournisseurModel> get fournisseurs => _filteredFournisseurs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  String get searchQuery => _searchQuery;
  int get totalFournisseursCount => _allFournisseurs.length;
  FournisseurSortOption get currentSortOption => _currentSortOption;

  /// French Label for active sort option
  String get sortOptionLabel {
    switch (_currentSortOption) {
      case FournisseurSortOption.nameAsc:
        return 'Nom (A -> Z)';
      case FournisseurSortOption.nameDesc:
        return 'Nom (Z -> A)';
      case FournisseurSortOption.soldeDesc:
        return 'Achats / Solde (Plus élevé)';
      case FournisseurSortOption.soldeAsc:
        return 'Achats / Solde (Plus bas)';
    }
  }

  /// Change sorting and re-apply filters
  void setSortOption(FournisseurSortOption option) {
    if (_currentSortOption != option) {
      _currentSortOption = option;
      _applyFilter();
      notifyListeners();
    }
  }

  /// Load suppliers from API
  Future<void> loadFournisseurs({bool isRefresh = false}) async {
    if (_allFournisseurs.isNotEmpty && !isRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allFournisseurs = await _service.fetchFournisseurs();
      _applyFilter();
    } catch (e) {
      _errorMessage = e.toString();
      _allFournisseurs = [];
      _filteredFournisseurs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filter suppliers by name
  void searchFournisseurs(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  /// Reset search query
  void clearSearch() {
    _searchQuery = '';
    _applyFilter();
    notifyListeners();
  }

  /// Internal filter and sort implementation
  void _applyFilter() {
    List<FournisseurModel> temp = List.from(_allFournisseurs);

    // Apply Search Query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      temp = temp.where((f) {
        return f.name.toLowerCase().contains(query) ||
            f.city.toLowerCase().contains(query) ||
            f.id.toLowerCase().contains(query);
      }).toList();
    }

    // Apply Sort Criteria
    switch (_currentSortOption) {
      case FournisseurSortOption.nameAsc:
        temp.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case FournisseurSortOption.nameDesc:
        temp.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case FournisseurSortOption.soldeDesc:
        temp.sort((a, b) => b.solde.compareTo(a.solde));
        break;
      case FournisseurSortOption.soldeAsc:
        temp.sort((a, b) => a.solde.compareTo(b.solde));
        break;
    }

    _filteredFournisseurs = temp;
  }

  /// Create a new supplier and refresh list automatically
  Future<void> addSupplier({
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
      await _supplierRepository.addSupplier(
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
      // Reload suppliers list automatically on success
      await loadFournisseurs(isRefresh: true);
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
    _service.dispose();
    super.dispose();
  }
}
