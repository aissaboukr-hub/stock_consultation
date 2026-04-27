import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/excel_service.dart';
import '../services/storage_service.dart';
import '../services/google_sheets_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  String? _lastImportDate;
  String? _lastSyncDate;
  String? _sourceType; // 'excel' ou 'google_sheets'
  int _syncInterval = 0; // en minutes
  Timer? _syncTimer;
  String? _googleSheetsStatus;

  // Getters
  List<Product> get products => List.unmodifiable(_products);
  bool get isDatabaseLoaded => _products.isNotEmpty;
  int get productCount => _products.length;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastImportDate => _lastImportDate;
  String? get lastSyncDate => _lastSyncDate;
  String? get sourceType => _sourceType;
  int get syncInterval => _syncInterval;
  String? get googleSheetsStatus => _googleSheetsStatus;
  bool get isGoogleSheets =>
      _sourceType == 'google_sheets';

  /// Charger les produits sauvegardes au demarrage
  Future<void> loadSavedProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await StorageService.loadProducts();
      _lastImportDate = await StorageService.getLastImportDate();
      _lastSyncDate = await StorageService.getLastSync();

      final config = await StorageService.getGoogleSheetsConfig();
      if (config != null) {
        _sourceType = 'google_sheets';
        _syncInterval = await StorageService.getSyncInterval();
      } else {
        _sourceType = 'excel';
      }
    } catch (e) {
      _products = [];
      if (kDebugMode) print('Erreur chargement: $e');
    }

    _isLoading = false;
    notifyListeners();

    // Demarrer le timer de sync si Google Sheets + intervalle defini
    _startSyncTimer();
  }

  /// Demarrer le timer de synchronisation
  void _startSyncTimer() {
    _syncTimer?.cancel();

    if (!isGoogleSheets || _syncInterval <= 0) return;

    _syncTimer = Timer.periodic(
      Duration(minutes: _syncInterval),
      (_) => syncFromGoogleSheets(),
    );

    if (kDebugMode) {
      print('Sync timer demarre: chaque $_syncInterval minutes');
    }
  }

  /// Changer l'intervalle de sync
  Future<void> setSyncInterval(int minutes) async {
    _syncInterval = minutes;
    await StorageService.saveSyncInterval(minutes);
    _startSyncTimer();
    notifyListeners();
  }

  /// Synchroniser depuis Google Sheets
  Future<bool> syncFromGoogleSheets({bool isAutoSync = false}) async {
    if (_isLoading) return false;

    try {
      final config = await StorageService.getGoogleSheetsConfig();
      if (config == null) {
        _googleSheetsStatus = 'Pas de configuration Google Sheets';
        notifyListeners();
        return false;
      }

      if (!isAutoSync) {
        _isLoading = true;
        notifyListeners();
      }

      final products = await GoogleSheetsService.fetchProducts(
        config['spreadsheetId'],
        sheetName: config['sheetName'],
        hasHeaders: config['hasHeaders'],
      );

      await StorageService.saveProducts(products);
      await StorageService.saveLastSync();

      _products = products;
      _lastImportDate = await StorageService.getLastImportDate();
      _lastSyncDate = await StorageService.getLastSync();
      _sourceType = 'google_sheets';
      _googleSheetsStatus = 'Synchronise a ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
      _isLoading = false;
      _error = null;
      notifyListeners();

      if (kDebugMode) {
        print('Sync reussie: ${products.length} produits');
      }
      return true;
    } catch (e) {
      _isLoading = false;
      _googleSheetsStatus = 'Echec de sync: ${e.toString()}';
      notifyListeners();

      if (kDebugMode) {
        print('Erreur sync: $e');
      }
      return false;
    }
  }

  /// Importer depuis Excel
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
      await StorageService.saveSource('excel');
      await StorageService.clearGoogleSheetsConfig();

      _products = parsed;
      _lastImportDate = await StorageService.getLastImportDate();
      _sourceType = 'excel';
      _syncTimer?.cancel();
      _syncInterval = 0;
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

  /// Importer depuis Google Sheets (premiere fois)
  Future<bool> importFromGoogleSheets(
    String spreadsheetId, {
    String sheetName = 'Feuil1',
    bool hasHeaders = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final products = await GoogleSheetsService.fetchProducts(
        spreadsheetId,
        sheetName: sheetName,
        hasHeaders: hasHeaders,
      );

      await StorageService.saveProducts(products);
      await StorageService.saveGoogleSheetsConfig(
        spreadsheetId: spreadsheetId,
        sheetName: sheetName,
        hasHeaders: hasHeaders,
      );
      await StorageService.saveLastSync();

      _products = products;
      _lastImportDate = await StorageService.getLastImportDate();
      _lastSyncDate = await StorageService.getLastSync();
      _sourceType = 'google_sheets';
      _isLoading = false;
      _error = null;
      notifyListeners();

      _startSyncTimer();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sauvegarder directement des produits
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

  /// Reinitialiser tout
  Future<void> clearDatabase() async {
    await StorageService.clearProducts();
    await StorageService.clearGoogleSheetsConfig();
    _syncTimer?.cancel();
    _products = [];
    _error = null;
    _lastImportDate = null;
    _lastSyncDate = null;
    _sourceType = null;
    _syncInterval = 0;
    _googleSheetsStatus = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}