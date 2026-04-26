import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/excel_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => List.unmodifiable(_products);
  bool get isDatabaseLoaded => _products.isNotEmpty;
  int get productCount => _products.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> importFromExcel() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final File? file = await ExcelService.pickExcelFile();
      if (file == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final stopwatch = Stopwatch()..start();
      final List<Product> parsed = await ExcelService.parseExcelFile(file);
      stopwatch.stop();

      _products = parsed;
      _isLoading = false;
      _error = null;
      notifyListeners();

      if (kDebugMode) {
        print('${parsed.length} produits en ${stopwatch.elapsedMilliseconds}ms');
      }
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      _products = [];
      notifyListeners();

      if (kDebugMode) {
        print('Erreur: $e');
      }
      return false;
    }
  }

  Product? findProductByBarcode(String barcode) {
    final String bc = barcode.trim().toLowerCase();
    for (int i = 0; i < _products.length; i++) {
      if (_products[i].barcode.trim().toLowerCase() == bc) {
        return _products[i];
      }
    }
    return null;
  }

  /// Recherche par designation ou code-barres
  List<Product> searchProducts(String query) {
    if (query.trim().isEmpty) return [];

    final String searchTerm = query.trim().toLowerCase();

    return _products.where((product) {
      return product.designation.toLowerCase().contains(searchTerm) ||
             product.barcode.toLowerCase().contains(searchTerm);
    }).toList();
  }

  void clearDatabase() {
    _products = [];
    _error = null;
    notifyListeners();
  }
}