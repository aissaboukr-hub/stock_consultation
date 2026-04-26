class Product {
  final String barcode;
  final String designation;
  final double price;
  final int quantityAvailable;

  const Product({
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

  factory Product.empty() => const Product(
        barcode: '',
        designation: '',
        price: 0.0,
        quantityAvailable: 0,
      );
}