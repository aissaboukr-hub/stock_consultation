import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class GoogleSheetsService {
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

  /// Tester la connexion et extraire les en-têtes
  static Future<Map<String, dynamic>> testConnectionAndHeaders(
    String spreadsheetId, {
    String sheetName = 'Feuil1',
  }) async {
    try {
      final url = Uri.parse(
        'https://docs.google.com/spreadsheets/d/$spreadsheetId/gviz/tq?'
        'sheet=${Uri.encodeComponent(sheetName)}&tqx=out:json',
      );

      final response =
          await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final parsed = _parseResponse(response.body);
        final rows = parsed['rows'] as List<dynamic>?;

        if (rows == null || rows.isEmpty) {
          return {
            'success': true,
            'message': 'Connexion reussie (sheet vide)',
            'headers': <String>[],
          };
        }

        final firstRowValues = <String>[];
        final headerCells = rows[0]['c'] as List<dynamic>? ?? [];
        for (final cell in headerCells) {
          firstRowValues.add((cell?['v']?.toString() ?? '').trim());
        }

        // Decider automatiquement si ce sont des en-tetes
        final bool looksLikeHeaders = _rowLooksLikeHeaders(firstRowValues);

        String message = 'Connexion reussie';
        if (looksLikeHeaders) {
          message += '\nEn-tetes detectees dans la premiere ligne.';
        } else {
          message +=
              '\nLa premiere ligne semble contenir des donnees (pas des en-tetes).';
        }

        return {
          'success': true,
          'message': message,
          'headers': firstRowValues,
          'hasHeaders': looksLikeHeaders,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message':
              'Le sheet est prive. Rendez-le public :\nPartager > Toute personne avec le lien > Lecteur',
          'headers': <String>[],
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Sheet introuvable. Verifiez l\'ID et le nom de la feuille.',
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

  /// Importer les produits
  static Future<List<Product>> fetchProducts(
    String spreadsheetId, {
    String sheetName = 'Feuil1',
    bool hasHeaders = true,
  }) async {
    final url = Uri.parse(
      'https://docs.google.com/spreadsheets/d/$spreadsheetId/gviz/tq?'
      'sheet=${Uri.encodeComponent(sheetName)}&tqx=out:json',
    );

    final response =
        await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 403) {
      throw Exception(
        'Le sheet est prive. Partager > Toute personne avec le lien > Lecteur',
      );
    }

    if (response.statusCode == 404) {
      throw Exception('Sheet introuvable.');
    }

    if (response.statusCode != 200) {
      throw Exception('Erreur HTTP ${response.statusCode}');
    }

    final parsed = _parseResponse(response.body);
    final List<dynamic>? rows = parsed['rows'];

    if (rows == null || rows.isEmpty) {
      throw Exception('Le sheet est vide.');
    }

    // === VERIFICATION DES EN-TETES ===
    if (hasHeaders) {
      final headerCells = rows[0]['c'] as List<dynamic>? ?? [];
      final firstRowValues = <String>[];
      for (final cell in headerCells) {
        firstRowValues.add((cell?['v']?.toString() ?? '').trim());
      }

      final bool reallyHasHeaders = _rowLooksLikeHeaders(firstRowValues);

      if (!reallyHasHeaders) {
        // Forcer l'option hasHeaders a false
        hasHeaders = false;
      }
    }

    // === DEFINIR LES COLONNES ===
    int dataStartRow;
    List<String> headers;

    if (hasHeaders) {
      dataStartRow = 1;
      headers = [];
      final headerCells = rows[0]['c'] as List<dynamic>? ?? [];
      for (final cell in headerCells) {
        headers.add((cell?['v']?.toString() ?? '').trim().toLowerCase());
      }
    } else {
      dataStartRow = 0;
      headers = [];
    }

    int colBarcode;
    int colDesignation;
    int colPrice;
    int colQuantity;

    if (hasHeaders) {
      colBarcode = _findCol(headers, [
        'codebarre', 'code_barre', 'barcode', 'ean',
        'code-barre', 'code', 'ean13', 'upc',
      ]);
      colDesignation = _findCol(headers, [
        'designation', 'désignation', 'nom', 'name',
        'produit', 'libelle', 'libellé', 'description', 'article',
      ]);
      colPrice = _findCol(headers, [
        'prix', 'price', 'montant', 'tarif', 'unite', 'unité', 'prix_unite',
      ]);
      colQuantity = _findCol(headers, [
        'quantite_disponible', 'quantité_disponible', 'quantite',
        'quantité', 'quantity', 'stock', 'disponible', 'qté', 'qty',
      ]);

      // Si colonne non trouvee avec les noms, essayer l'ordre par index
      if (colBarcode == -1) colBarcode = 0;
      if (colDesignation == -1) colDesignation = 1;
      if (colPrice == -1) colPrice = 2;
      if (colQuantity == -1) colQuantity = 3;
    } else {
      // Pas d'en-tetes : ordre fixe par defaut
      colBarcode = 0;
      colDesignation = 1;
      colPrice = 2;
      colQuantity = 3;
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

  // === UTILITAIRES ===

  /// Decider si une ligne ressemble a des en-tetes
  static bool _rowLooksLikeHeaders(List<String> rowValues) {
    if (rowValues.isEmpty) return false;

    // Verifier si la premiere cellule est un nombre (code-barres)
    final String firstCell = rowValues[0].trim();

    // Code-barres = nombre pur de plus de 8 chiffres
    final RegExp barcodePattern = RegExp(r'^\d{8,20}(\.0)?$');
    if (barcodePattern.hasMatch(firstCell)) {
      return false; // Ce n'est PAS un en-tete, c'est un code-barres
    }

    // Verifier si ca ressemble a des mots-clefs d'en-tetes
    final List<String> headerWords = [
      'codebarre', 'code_barre', 'barcode', 'ean', 'code',
      'designation', 'désignation', 'nom', 'name', 'produit',
      'prix', 'price', 'montant', 'tarif',
      'quantite', 'quantité', 'stock', 'quantity', 'disponible',
      'libelle', 'description', 'article',
    ];

    int matchCount = 0;
    for (final val in rowValues) {
      final lower = val.toLowerCase().trim();
      for (final word in headerWords) {
        if (lower.contains(word)) {
          matchCount++;
          break;
        }
      }
    }

    // Si au moins 50% matchent des mots-clefs = en-tetes
    if (matchCount > 0 && (matchCount / rowValues.length) >= 0.3) {
      return true;
    }

    // Si la premiere cellule est un texte non-numeric, probablement un en-tete
    final bool firstIsText =
        firstCell.isNotEmpty && !RegExp(r'^\d').hasMatch(firstCell);
    return firstIsText;
  }

  /// Parser la reponse JSONP de Google
  static Map<String, dynamic> _parseResponse(String body) {
    final int jsonStart = body.indexOf('{');
    final int jsonEnd = body.lastIndexOf('}');

    if (jsonStart == -1 || jsonEnd == -1) {
      throw Exception('Reponse invalide de Google Sheets.');
    }

    final String jsonString = body.substring(jsonStart, jsonEnd + 1);
    final data = jsonDecode(jsonString);

    return {
      'rows': data['table']?['rows'],
    };
  }

  static int _findCol(List<String> headers, List<String> names) {
    for (int h = 0; h < headers.length; h++) {
      final lowerHeader = headers[h].toLowerCase().trim();
      for (final name in names) {
        if (lowerHeader == name) return h;
      }
    }
    for (int h = 0; h < headers.length; h++) {
      final lowerHeader = headers[h].toLowerCase().trim();
      for (final name in names) {
        if (lowerHeader.contains(name)) return h;
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