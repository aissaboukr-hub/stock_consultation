import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';

class StorageService {
  static const String _boxName = 'products';
  static const String _keyProducts = 'product_list';
  static const String _keyTimestamp = 'import_timestamp';

  /// Initialiser Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  /// Sauvegarder la liste de produits
  static Future<void> saveProducts(List<Product> products) async {
    final box = Hive.box(_boxName);

    final List<Map<String, dynamic>> productList =
        products.map((p) => p.toMap()).toList();

    await box.put(_keyProducts, productList);
    await box.put(_keyTimestamp, DateTime.now().toIso8601String());
  }

  /// Charger la liste de produits sauvegardée
  static Future<List<Product>> loadProducts() async {
    final box = Hive.box(_boxName);

    final dynamic rawData = box.get(_keyProducts);

    if (rawData == null) return [];

    try {
      final List<dynamic> productList = rawData as List<dynamic>;

      return productList.map((item) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(item);
        return Product.fromMap(map);
      }).toList();
    } catch (e) {
      // Données corrompues, on efface
      await clearProducts();
      return [];
    }
  }

  /// Vérifier si des produits sont sauvegardés
  static bool hasProducts() {
    final box = Hive.box(_boxName);
    return box.get(_keyProducts) != null;
  }

  /// Obtenir le nombre de produits sauvegardés
  static int getProductCount() {
    final box = Hive.box(_boxName);
    final dynamic rawData = box.get(_keyProducts);
    if (rawData == null) return 0;
    return (rawData as List).length;
  }

  /// Obtenir la date du dernier import
  static String? getLastImportDate() {
    final box = Hive.box(_boxName);
    final String? timestamp = box.get(_keyTimestamp);
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

  /// Effacer tous les produits sauvegardés
  static Future<void> clearProducts() async {
    final box = Hive.box(_boxName);
    await box.delete(_keyProducts);
    await box.delete(_keyTimestamp);
  }
}