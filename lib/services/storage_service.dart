import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class StorageService {
  static const String _keyProducts = 'product_list';
  static const String _keyTimestamp = 'import_timestamp';

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
      // Donnees corrompues, on efface
      await clearProducts();
      return [];
    }
  }

  /// Verifier si des produits sont sauvegardes
  static Future<bool> hasProducts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProducts) != null;
  }

  /// Obtenir le nombre de produits sauvegardes
  static Future<int> getProductCount() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyProducts);
    if (jsonString == null || jsonString.isEmpty) return 0;

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.length;
    } catch (_) {
      return 0;
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
}