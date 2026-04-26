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

      final List<Product> parsed =
          await ExcelService.parseExcelFile(file);

      _products = parsed;
      _isLoading = false;
      _error = null;
      notifyListeners();

      if (kDebugMode) {
        print('${_products.length} produits importes avec succes.');
      }
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      _products = [];
      notifyListeners();

      if (kDebugMode) {
        print('Erreur import: $e');
      }
      return false;
    }
  }

  Product? findProductByBarcode(String barcode) {
    try {
      return _products.firstWhere(
        (product) =>
            product.barcode.trim().toLowerCase() ==
            barcode.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  void clearDatabase() {
    _products = [];
    _error = null;
    notifyListeners();
  }
}