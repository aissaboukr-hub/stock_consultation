import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class GoogleSheetsService {
  /// Extraire l'ID du spreadsheet
  static String? extractSpreadsheetId(String input) {
    final String trimmed = input.trim();

    if (!trimmed.contains('/') && trimmed.length > 20) {
      return trimmed;
    }

    final RegExp regExp = RegExp(r'spreadsheets/d/([a-zA-Z0-9_-]+)');
    final Match? match = regExp.firstMatch(trimmed);

    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return null;
  }

  /// Tester la connexion ET extraire les en-têtes
  static Future<Map<String, dynamic>> testConnectionAndHeaders(
    String spreadsheetId, {
    String sheetName = 'Feuil1',
  }) async {
    try {
      final url = Uri.parse(
        'https://docs.google.com/spreadsheets/d/$spreadsheetId/gviz/tq?'
        'sheet=${Uri.encodeComponent(sheetName)}&tqx=out:json',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final String body = response.body;
        final int jsonStart = body.indexOf('{');
        final int jsonEnd = body.lastIndexOf('}');

        if (jsonStart == -1 || jsonEnd == -1) {
          return {
            'success': true,
            'message': 'Connexion reussie',
            'headers': <String>[],
          };
        }

        final String jsonString = body.substring(jsonStart, jsonEnd + 1);
        final Map<String, dynamic> data = jsonDecode(jsonString);

        final List<dynamic>? rows = data['table']?['rows'];

        if (rows == null || rows.isEmpty) {
          return {
            'success': true,
            'message': 'Connexion reussie (sheet vide)',
            'headers': <String>[],
          };
        }

        // Extraire les en-tetes de la premiere ligne
        final List<String> headers = [];
        final headerCells = rows[0]['c'] as List<dynamic>? ?? [];

        for (final cell in headerCells) {
          headers.add((cell?['v']?.toString() ?? '').trim().toLowerCase());
        }

        return {
          'success': true,
          'message': 'Connexion reussie',
          'headers': headers,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Le sheet est prive. Rendez-le public.',
          'headers': <String>[],
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Sheet introuvable. Verifiez l\'ID.',
          'headers': <String>[],
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur HTTP ${response.statusCode}',
          'headers': <String>[],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion : $e',
        'headers': <String>[],
      };
    }
  }

  /// Importer les produits depuis Google Sheets
  static Future<List<Product>> fetchProducts(
    String spreadsheetId, {
    String sheetName = 'Feuil1',
    required bool hasHeaders,
  }) async {
    final url = Uri.parse(
      'https://docs.google.com/spreadsheets/d/$spreadsheetId/gviz/tq?'
      'sheet=${Uri.encodeComponent(sheetName)}&tqx=out:json',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 403) {
      throw Exception(
        'Le sheet est prive. Allez dans Google Sheets > Partager > Toute personne avec le lien > Lecteur',
      );
    }

    if (response.statusCode == 404) {
      throw Exception('Sheet introuvable. Verifiez l\'ID et le nom de la feuille.');
    }

    if (response.statusCode != 200) {
      throw Exception('Erreur HTTP ${response.statusCode}');
    }

    final String body = response.body;
    final int jsonStart = body.indexOf('{');
    final int jsonEnd = body.lastIndexOf('}');

    if (jsonStart == -1 || jsonEnd == -1) {
      throw Exception('Reponse invalide de Google Sheets.');
    }

    final String jsonString = body.substring(jsonStart, jsonEnd + 1);
    final Map<String, dynamic> data = jsonDecode(jsonString);

    final List<dynamic>? rows = data['table']?['rows'];

    if (rows == null || rows.length < 1) {
      throw Exception('Le sheet est vide.');
    }

    // Determiner les en-tetes
    int dataStartRow;
    final List<String> headers;

    if (hasHeaders) {
      dataStartRow = 1;
      headers = [];
      final headerCells = rows[0]['c'] as List<dynamic>? ?? [];
      for (final cell in headerCells) {
        headers.add((cell?['v']?.toString() ?? '').trim().toLowerCase());
      }
    } else {
      dataStartRow = 0;
      headers = ['codebarre', 'designation', 'prix', 'quantite'];
    }

    // Trouver les colonnes avec variables non-final
    int colBarcode = _findCol(headers, [
      'codebarre', 'code_barre', 'barcode', 'ean', 'code-barre', 'code',
    ]);
    int colDesignation = _findCol(headers, [
      'designation', 'désignation', 'nom', 'name',
      'produit', 'libelle', 'libellé', 'description',
    ]);
    int colPrice = _findCol(headers, [
      'prix', 'price', 'montant', 'tarif', 'unite', 'unité',
    ]);
    int colQuantity = _findCol(headers, [
      'quantite_disponible', 'quantité_disponible', 'quantite',
      'quantité', 'quantity', 'stock', 'disponible',
    ]);

    // Ordre par defaut si pas d'en-tetes
    if (!hasHeaders) {
      if (colBarcode == -1) colBarcode = 0;
      if (colDesignation == -1) colDesignation = 1;
      if (colPrice == -1) colPrice = 2;
      if (colQuantity == -1) colQuantity = 3;
    }

    if (colBarcode == -1 && hasHeaders) {
      throw Exception(
        "Colonne 'CodeBarre' introuvable.\n"
        "En-tetes trouvees : ${headers.join(', ')}\n"
        "Attendu : CodeBarre | Designation | Prix | Quantite_Disponible",
      );
    }

    // Parser les donnees
    final List<Product> products = [];

    for (int i = dataStartRow; i < rows.length; i++) {
      final cells = rows[i]['c'] as List<dynamic>? ?? [];
      if (cells.isEmpty) continue;

      final String barcode = _getCellStr(cells, colBarcode);
      if (barcode.isEmpty) continue;

      try {
        products.add(Product(
          barcode: barcode,
          designation: _getCellStr(cells, colDesignation).isNotEmpty
              ? _getCellStr(cells, colDesignation)
              : '---',
          price: _getCellNum(cells, colPrice),
          quantityAvailable: _getCellNum(cells, colQuantity).toInt(),
        ));
      } catch (_) {
        continue;
      }
    }

    if (products.isEmpty) {
      throw Exception('Aucun produit valide trouve dans le sheet.');
    }

    return products;
  }

  static int _findCol(List<String> headers, List<String> names) {
    for (final name in names) {
      final index = headers.indexOf(name);
      if (index != -1) return index;
    }
    for (int h = 0; h < headers.length; h++) {
      for (final n in names) {
        if (headers[h].contains(n)) return h;
      }
    }
    return -1;
  }

  static String _getCellStr(List<dynamic> cells, int col) {
    if (col < 0 || col >= cells.length) return '';
    final val = cells[col]?['v'];
    return val?.toString().trim() ?? '';
  }

  static double _getCellNum(List<dynamic> cells, int col) {
    if (col < 0 || col >= cells.length) return 0.0;
    final val = cells[col]?['v'];
    if (val == null) return 0.0;
    if (val is int) return val.toDouble();
    if (val is double) return val;
    if (val is String) {
      return double.tryParse(val.replaceAll(',', '.').trim()) ?? 0.0;
    }
    return double.tryParse(val.toString()) ?? 0.0;
  }
}