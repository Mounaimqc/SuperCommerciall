import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/charge_model.dart';
import '../services/charge_service.dart';

class ChargeProvider with ChangeNotifier {
  final ChargeService _chargeService = ChargeService();

  List<ChargeModel> _charges = [];
  List<ChargeModel> _filteredCharges = [];
  bool _isLoading = false;
  String? _error;

  String _searchQuery = '';
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  List<ChargeModel> get charges => _filteredCharges;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  String get searchQuery => _searchQuery;

  // Calculs statistiques
  double get totalMontant => _filteredCharges.fold(0.0, (sum, item) => sum + item.montant);
  int get countCharges => _filteredCharges.length;

  Future<void> loadCharges() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final String dateDebut = DateFormat('yyyy-MM-dd').format(_startDate);
      final String dateFin = DateFormat('yyyy-MM-dd').format(_endDate);
      
      final fetched = await _chargeService.fetchCharges(dateDebut, dateFin);
      
      // Sort by date descending
      fetched.sort((a, b) => b.date.compareTo(a.date));
      
      _charges = fetched;
      _applySearch();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCharge(ChargeModel charge) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _chargeService.insertCharge(charge);
      // Refresh list to fetch from SAGE
      await loadCharges();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void updateDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    loadCharges();
  }

  void search(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.trim().isEmpty) {
      _filteredCharges = List.from(_charges);
    } else {
      _filteredCharges = _charges.where((charge) => charge.matchesSearch(_searchQuery)).toList();
    }
  }
}
