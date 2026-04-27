import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class StorageService {
  static const String _keyProducts = 'product_list';
  static const String _keyTimestamp = 'import_timestamp';
  static const String _keySource = 'import_source';
  static const String _keySpreadsheetId = 'spreadsheet_id';
  static const String _keySheetName = 'sheet_name';
  static const String _keyHasHeaders = 'has_headers';
  static const String _keySyncInterval = 'sync_interval';
  static const String _keyLastSync = 'last_sync';

  /// Sauvegarder la liste de produits
  static Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();

    final List<Map<String, dynamic>> productList =
        products.map((p) => p.toMap()).toList();

    await prefs.setString(_keyProducts, jsonEncode(productList));
    await prefs.setString(_keyTimestamp, DateTime.now().toIso8601String());
  }

  /// Charger la liste de produits sauvegardee
  static Future<List<Product>> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();

    final String? jsonString = prefs.getString(_keyProducts);

    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);

      return decoded.map((item) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(item);
        return Product.fromMap(map);
      }).toList();
    } catch (e) {
      await clearProducts();
      return [];
    }
  }

  /// Obtenir la date du dernier import
  static Future<String?> getLastImportDate() async {
    final prefs = await SharedPreferences.getInstance();
    final String? timestamp = prefs.getString(_keyTimestamp);
    if (timestamp == null) return null;

    try {
      final DateTime date = DateTime.parse(timestamp);
      final String day = date.day.toString().padLeft(2, '0');
      final String month = date.month.toString().padLeft(2, '0');
      final String hour = date.hour.toString().padLeft(2, '0');
      final String minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/${date.year} a $hour:$minute';
    } catch (_) {
      return null;
    }
  }

  /// Effacer tous les produits sauvegardes
  static Future<void> clearProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProducts);
    await prefs.remove(_keyTimestamp);
  }

  // ========================
  // GOOGLE SHEETS CONFIG
  // ========================

  /// Sauvegarder la source (excel ou google_sheets)
  static Future<void> saveSource(String source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySource, source);
  }

  /// Sauvegarder les infos de la source Google Sheets
  static Future<void> saveGoogleSheetsConfig({
    required String spreadsheetId,
    required String sheetName,
    required bool hasHeaders,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySource, 'google_sheets');
    await prefs.setString(_keySpreadsheetId, spreadsheetId);
    await prefs.setString(_keySheetName, sheetName);
    await prefs.setBool(_keyHasHeaders, hasHeaders);
  }

  /// Recuperer la config Google Sheets sauvegardee
  static Future<Map<String, dynamic>?> getGoogleSheetsConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final String? source = prefs.getString(_keySource);
    if (source != 'google_sheets') return null;

    final String? spreadsheetId = prefs.getString(_keySpreadsheetId);
    final String? sheetName = prefs.getString(_keySheetName);
    final bool hasHeaders = prefs.getBool(_keyHasHeaders) ?? true;

    if (spreadsheetId == null) return null;

    return {
      'spreadsheetId': spreadsheetId,
      'sheetName': sheetName ?? 'Feuil1',
      'hasHeaders': hasHeaders,
    };
  }

  /// Verifier si la source est Google Sheets
  static Future<bool> isGoogleSheetsSource() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySource) == 'google_sheets';
  }

  /// Sauvegarder l'intervalle de sync (en minutes)
  static Future<void> saveSyncInterval(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySyncInterval, minutes);
  }

  /// Recuperer l'intervalle de sync
  static Future<int> getSyncInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySyncInterval) ?? 0;
  }

  /// Sauvegarder la date de la derniere sync
  static Future<void> saveLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSync, DateTime.now().toIso8601String());
  }

  /// Recuperer la date de la derniere sync
  static Future<String?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final String? timestamp = prefs.getString(_keyLastSync);
    if (timestamp == null) return null;

    try {
      final DateTime date = DateTime.parse(timestamp);
      final String day = date.day.toString().padLeft(2, '0');
      final String month = date.month.toString().padLeft(2, '0');
      final String hour = date.hour.toString().padLeft(2, '0');
      final String minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/${date.year} a $hour:$minute';
    } catch (_) {
      return null;
    }
  }

  /// Effacer la config Google Sheets
  static Future<void> clearGoogleSheetsConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySource);
    await prefs.remove(_keySpreadsheetId);
    await prefs.remove(_keySheetName);
    await prefs.remove(_keyHasHeaders);
    await prefs.remove(_keySyncInterval);
    await prefs.remove(_keyLastSync);
  }
}