import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  final String barcode;

  @HiveField(1)
  final String designation;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final int quantityAvailable;

  Product({
    required this.barcode,
    required this.designation,
    required this.price,
    required this.quantityAvailable,
  });

  String get formattedPrice => '${price.toStringAsFixed(2)} EUR';

  bool get isInStock => quantityAvailable > 0;

  String get availabilityStatus {
    if (quantityAvailable <= 0) return 'Rupture de stock';
    if (quantityAvailable <= 5) {
      return 'Stock faible ($quantityAvailable restant)';
    }
    return 'En stock ($quantityAvailable disponibles)';
  }

  @override
  String toString() =>
      'Product(barcode: $barcode, name: $designation, price: $price, qty: $quantityAvailable)';

  /// Conversion vers Map (pour le stockage)
  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'designation': designation,
      'price': price,
      'quantityAvailable': quantityAvailable,
    };
  }

  /// Conversion depuis Map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      barcode: map['barcode'] ?? '',
      designation: map['designation'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantityAvailable: (map['quantityAvailable'] ?? 0).toInt(),
    );
  }
}