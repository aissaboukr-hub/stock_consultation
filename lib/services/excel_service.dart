import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import '../models/product.dart';

class ExcelService {
  /// Ouvre le picker de fichiers
  static Future<File?> pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: false,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// Parse le fichier Excel dans un Isolate séparé (ne bloque pas l'UI)
  static Future<List<Product>> parseExcelFile(File file) async {
    final Uint8List bytes = await file.readAsBytes();

    // Lancer le parsing dans un thread séparé
    final List<Product> products = await Isolate.run(
      () => _parseInBackground(bytes),
    );

    return products;
  }

  /// Fonction exécutée dans l'Isolate
  static List<Product> _parseInBackground(Uint8List bytes) {
    final Excel? excel = Excel.decodeBytes(bytes);

    if (excel == null || excel.tables.isEmpty) {
      throw Exception('Le fichier Excel est vide ou illisible.');
    }

    final String sheetName = excel.tables.keys.first;
    final Sheet sheet = excel.tables[sheetName]!;

    if (sheet.maxRows < 2) {
      throw Exception('Le fichier ne contient aucune donnee.');
    }

    // Lire les en-tetes (ligne 0)
    final List<String> headers = [];
    final headerRow = sheet.rows[0];

    for (final cell in headerRow) {
      headers.add(cell?.value?.toString().trim().toLowerCase() ?? '');
    }

    // Trouver les colonnes
    final int colBarcode = _findCol(headers, [
      'codebarre', 'code_barre', 'barcode', 'ean', 'code-barre', 'code',
    ]);
    final int colDesignation = _findCol(headers, [
      'designation', 'désignation', 'nom', 'name',
      'produit', 'libelle', 'libellé',
    ]);
    final int colPrice = _findCol(headers, [
      'prix', 'price', 'montant', 'tarif',
    ]);
    final int colQuantity = _findCol(headers, [
      'quantite_disponible', 'quantité_disponible', 'quantite',
      'quantité', 'quantity', 'stock', 'disponible',
    ]);

    if (colBarcode == -1) {
      throw Exception(
        "Colonne 'CodeBarre' introuvable.\n"
        "Entetes: ${headers.join(', ')}",
      );
    }

    // Pre-allocation de la liste pour la performance
    final int estimatedRows = sheet.maxRows - 1;
    final List<Product> products = [];
    products.length = estimatedRows; // pre-allocation
    int validCount = 0;

    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.rows[i];

      if (row.isEmpty || row.length <= colBarcode) {
        products.length = products.length - 1;
        continue;
      }

      final String barcode = _cellStr(row, colBarcode);
      if (barcode.isEmpty) {
        products.length = products.length - 1;
        continue;
      }

      products[validCount] = Product(
        barcode: barcode,
        designation: _cellStr(row, colDesignation).isNotEmpty
            ? _cellStr(row, colDesignation)
            : '---',
        price: _cellNum(row, colPrice),
        quantityAvailable: _cellNum(row, colQuantity).toInt(),
      );
      validCount++;
    }

    // Redimensionner à la taille réelle
    products.length = validCount;

    if (products.isEmpty) {
      throw Exception('Aucun produit valide trouve.');
    }

    return products;
  }

  static int _findCol(List<String> headers, List<String> names) {
    for (int j = 0; j < names.length; j++) {
      final idx = headers.indexOf(names[j]);
      if (idx != -1) return idx;
    }
    return -1;
  }

  static String _cellStr(List<Data?> row, int col) {
    if (col < 0 || col >= row.length) return '';
    final v = row[col]?.value;
    return v?.toString().trim() ?? '';
  }

  static double _cellNum(List<Data?> row, int col) {
    if (col < 0 || col >= row.length) return 0.0;
    final v = row[col]?.value;
    if (v == null) return 0.0;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    if (v is String) {
      return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
    }
    return double.tryParse(v.toString()) ?? 0.0;
  }
}