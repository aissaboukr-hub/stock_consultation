import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/excel_service.dart';
import '../services/storage_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  String? _lastImportDate;

  List<Product> get products => List.unmodifiable(_products);
  bool get isDatabaseLoaded => _products.isNotEmpty;
  int get productCount => _products.length;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastImportDate => _lastImportDate;

  Future<void> loadSavedProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await StorageService.loadProducts();
      _lastImportDate = await StorageService.getLastImportDate();
    } catch (e) {
      _products = [];
      if (kDebugMode) print('Erreur chargement: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

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

      final List<Product> parsed = await ExcelService.parseExcelFile(file);

      await StorageService.saveProducts(parsed);

      _products = parsed;
      _lastImportDate = await StorageService.getLastImportDate();
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sauvegarder directement des produits (Google Sheets)
  Future<void> saveProductsDirectly(List<Product> products) async {
    await StorageService.saveProducts(products);
    _products = products;
    _lastImportDate = await StorageService.getLastImportDate();
    _isLoading = false;
    _error = null;
    notifyListeners();
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

  List<Product> searchProducts(String query) {
    if (query.trim().isEmpty) return [];
    final String searchTerm = query.trim().toLowerCase();

    return _products.where((product) {
      return product.designation.toLowerCase().contains(searchTerm) ||
          product.barcode.toLowerCase().contains(searchTerm);
    }).toList();
  }

  Future<void> clearDatabase() async {
    await StorageService.clearProducts();
    _products = [];
    _error = null;
    _lastImportDate = null;
    notifyListeners();
  }
}