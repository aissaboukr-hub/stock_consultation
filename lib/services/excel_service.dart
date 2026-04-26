import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import '../models/product.dart';

class ExcelService {
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

  static Future<List<Product>> parseExcelFile(File file) async {
    final Uint8List bytes = await file.readAsBytes();
    final Excel? excel = Excel.decodeBytes(bytes);

    if (excel == null || excel.tables.isEmpty) {
      throw Exception('Le fichier Excel est vide ou illisible.');
    }

    final String sheetName = excel.tables.keys.first;
    final Sheet sheet = excel.tables[sheetName]!;

    if (sheet.maxRows == 0) {
      throw Exception('La feuille est vide.');
    }

    final List<String> headers = [];
    final List<Data?>? headerRow =
        sheet.rows.isNotEmpty ? sheet.rows.first : null;

    if (headerRow == null || headerRow.isEmpty) {
      throw Exception('Aucun en-tete trouve dans le fichier.');
    }

    for (final cell in headerRow) {
      final String header =
          cell?.value?.toString().trim().toLowerCase() ?? '';
      headers.add(header);
    }

    final int colBarcode = _findColumnIndex(headers, [
      'codebarre', 'code_barre', 'barcode', 'ean', 'code-barre', 'code',
    ]);
    final int colDesignation = _findColumnIndex(headers, [
      'designation', 'dÃ©signation', 'nom', 'name',
      'produit', 'libelle', 'libellÃ©',
    ]);
    final int colPrice = _findColumnIndex(headers, [
      'prix', 'price', 'montant', 'tarif',
    ]);
    final int colQuantity = _findColumnIndex(headers, [
      'quantite_disponible', 'quantitÃ©_disponible', 'quantite',
      'quantitÃ©', 'quantity', 'stock', 'disponible',
    ]);

    if (colBarcode == -1) {
      throw Exception(
        "Colonne 'CodeBarre' introuvable.\n"
        "Entetes trouves : ${headers.join(', ')}\n"
        "Colonnes attendues : CodeBarre | Designation | Prix | Quantite_Disponible",
      );
    }

    final List<Product> products = [];

    for (int i = 1; i < sheet.maxRows; i++) {
      final List<Data?> row = sheet.rows[i];
      if (row.isEmpty) continue;

      final String barcode = _getCellValue(row, colBarcode);
      if (barcode.isEmpty) continue;

      final String designation = _getCellValue(row, colDesignation);
      final double price = _getNumericValue(row, colPrice);
      final int quantity = _getNumericValue(row, colQuantity).toInt();

      products.add(Product(
        barcode: barcode,
        designation: designation.isNotEmpty ? designation : '---',
        price: price,
        quantityAvailable: quantity,
      ));
    }

    if (products.isEmpty) {
      throw Exception('Aucun produit valide trouve dans le fichier.');
    }

    return products;
  }

  static int _findColumnIndex(
      List<String> headers, List<String> possibleNames) {
    for (final name in possibleNames) {
      final index = headers.indexOf(name);
      if (index != -1) return index;
    }
    return -1;
  }

  static String _getCellValue(List<Data?> row, int colIndex) {
    if (colIndex < 0 || colIndex >= row.length) return '';
    final Data? cell = row[colIndex];
    if (cell == null || cell.value == null) return '';
    return cell.value.toString().trim();
  }

  static double _getNumericValue(List<Data?> row, int colIndex) {
    if (colIndex < 0 || colIndex >= row.length) return 0.0;
    final Data? cell = row[colIndex];
    if (cell == null || cell.value == null) return 0.0;
    final dynamic value = cell.value;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return double.tryParse(value.toString()) ?? 0.0;
  }
}