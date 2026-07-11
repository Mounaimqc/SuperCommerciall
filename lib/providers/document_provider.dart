import 'package:flutter/material.dart';
import '../models/document_line_model.dart';
import '../services/document_service.dart';

/// Provider managing state for SAGE document details and lines with caching and ERP summary calculations
class DocumentProvider extends ChangeNotifier {
  final DocumentService _service = DocumentService();

  // Cache document lines while the app is running to avoid duplicate API calls
  final Map<String, List<DocumentLineModel>> _linesCache = {};

  List<DocumentLineModel> _lines = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentDocumentId;

  // Getters
  List<DocumentLineModel> get lines => _lines;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  String? get currentDocumentId => _currentDocumentId;

  /// Load document line items from remote API with in-memory caching
  Future<void> loadDocumentLines(String documentId, {bool forceRefresh = false}) async {
    _currentDocumentId = documentId;

    if (!forceRefresh && _linesCache.containsKey(documentId)) {
      _lines = _linesCache[documentId]!;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _lines = [];
    notifyListeners();

    try {
      final fetched = await _service.fetchDocumentLines(documentId);
      _lines = fetched;
      _linesCache[documentId] = fetched;
    } catch (e) {
      _errorMessage = e.toString();
      _lines = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculations for SUMMARY section
  int get numberOfProducts => _lines.length;

  double get totalQuantity {
    return _lines.fold(0.0, (sum, item) => sum + item.quantity);
  }

  double get totalHT {
    return _lines.fold(0.0, (sum, item) => sum + item.total);
  }

  double get tvaAmount {
    return _lines.fold(0.0, (sum, item) => sum + (item.total * (item.vat / 100)));
  }

  double get discountAmount {
    return _lines.fold(0.0, (sum, item) => sum + item.discount);
  }

  double get grandTotal {
    return totalHT + tvaAmount - discountAmount;
  }
}
