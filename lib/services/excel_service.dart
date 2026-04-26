import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../models/product.dart';

class ExcelService {
  /// Sélection du fichier Excel
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

  /// Parse le fichier dans un Isolate (ne bloque pas l'UI)
  static Future<List<Product>> parseExcelFile(File file) async {
    final Uint8List bytes = await file.readAsBytes();

    return Isolate.run(() => _parseInBackground(bytes));
  }

  /// Fonction exécutée en arrière-plan
  static List<Product> _parseInBackground(Uint8List bytes) {
    final Excel? excel = Excel.decodeBytes(bytes);

    if (excel == null || excel.tables.isEmpty) {
      throw Exception('Le fichier Excel est vide ou illisible.');
    }

    final String sheetName = excel.tables.keys.first;
    final Sheet sheet = excel.tables[sheetName]!;

    if (sheet.maxRows < 2) {
      throw Exception('Le fichier ne contient aucune donnée valide.');
    }

    // Lecture des en-têtes
    final List<String> headers = [];
    for (final cell in sheet.rows[0]) {
      headers.add((cell?.value?.toString() ?? '').trim().toLowerCase());
    }

    // Détection des colonnes
    final int colBarcode = _findColumn(headers, ['codebarre', 'code_barre', 'barcode', 'ean', 'code']);
    final int colDesignation = _findColumn(headers, ['designation', 'désignation', 'nom', 'name', 'produit', 'libelle']);
    final int colPrice = _findColumn(headers, ['prix', 'price', 'montant', 'tarif']);
    final int colQuantity = _findColumn(headers, ['quantite', 'quantité', 'quantity', 'stock', 'disponible']);

    if (colBarcode == -1) {
      throw Exception("Colonne 'CodeBarre' introuvable.\nEn-têtes trouvés : ${headers.join(', ')}");
    }

    final List<Product> products = [];
    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;

      final String barcode = _getString(row, colBarcode);
      if (barcode.isEmpty) continue;

      products.add(Product(
        barcode: barcode,
        designation: _getString(row, colDesignation).isNotEmpty
            ? _getString(row, colDesignation)
            : '---',
        price: _getDouble(row, colPrice),
        quantityAvailable: _getDouble(row, colQuantity).toInt(),
      ));
    }

    if (products.isEmpty) {
      throw Exception('Aucun produit valide trouvé dans le fichier.');
    }

    return products;
  }

  static int _findColumn(List<String> headers, List<String> possibleNames) {
    for (final name in possibleNames) {
      final index = headers.indexOf(name);
      if (index != -1) return index;
    }
    return -1;
  }

  /// Récupère une valeur texte (compatible excel 4.0+)
  static String _getString(List<Data?> row, int col) {
    if (col < 0 || col >= row.length) return '';
    final CellValue? cellValue = row[col]?.value;
    if (cellValue == null) return '';
    return cellValue.toString().trim();
  }

  /// Récupère une valeur numérique (compatible excel 4.0+)
  static double _getDouble(List<Data?> row, int col) {
    if (col < 0 || col >= row.length) return 0.0;
    final CellValue? cellValue = row[col]?.value;
    if (cellValue == null) return 0.0;

    if (cellValue is IntCellValue) return cellValue.value.toDouble();
    if (cellValue is DoubleCellValue) return cellValue.value;
    if (cellValue is StringCellValue) {
      final str = cellValue.value.replaceAll(',', '.').trim();
      return double.tryParse(str) ?? 0.0;
    }

    // Fallback
    final str = cellValue.toString().replaceAll(',', '.').trim();
    return double.tryParse(str) ?? 0.0;
  }
}