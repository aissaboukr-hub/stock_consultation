import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class GoogleSheetsService {
  /// Extraire l'ID du spreadsheet depuis une URL ou un ID brut
  static String? extractSpreadsheetId(String input) {
    final String trimmed = input.trim();

    // Si c'est un ID brut (pas de /)
    if (!trimmed.contains('/') && trimmed.length > 20) {
      return trimmed;
    }

    // Formats d'URL supportes :
    // https://docs.google.com/spreadsheets/d/SPREADSHEET_ID/edit
    // https://docs.google.com/spreadsheets/d/SPREADSHEET_ID/edit#gid=0
    final RegExp regExp = RegExp(
      r'spreadsheets/d/([a-zA-Z0-9_-]+)',
    );
    final Match? match = regExp.firstMatch(trimmed);

    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return null;
  }

  /// Verifier si le sheet est public (pas besoin d'auth)
  static Future<Map<String, dynamic>> testConnection(
      String spreadsheetId) async {
    try {
      final url = Uri.parse(
        'https://docs.google.com/spreadsheets/d/$spreadsheetId/gviz/tq?tqx=out:json',
      );

      final response = await http.get(url).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Connexion reussie'};
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Le sheet est prive. Rendez-le public (Partager > Toute personne avec le lien)',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Sheet introuvable. Verifiez l\'ID.',
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion : $e',
      };
    }
  }

  // Ajout après testConnection()
  /// Tester la connexion ET extraire les en-têtes pour vérification
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
            'message': 'Connexion réussie',
            'headers': [],
          };
        }

        final String jsonString = body.substring(jsonStart, jsonEnd + 1);
        final Map<String, dynamic> data = jsonDecode(jsonString);

        final List<dynamic>? rows = data['table']?['rows'];

        if (rows == null || rows.isEmpty) {
          return {
            'success': true,
            'message': 'Connexion réussie (mais le sheet semble vide)',
            'headers': [],
          };
        }

        // Extraire les en-têtes de la première ligne
        final List<String> headers = [];
        final headerCells = rows[0]['c'] as List<dynamic>? ?? [];

        for (final cell in headerCells) {
          final String header = (cell?['v']?.toString() ?? '').trim().toLowerCase();
          headers.add(header);
        }

        return {
          'success': true,
          'message': 'Connexion réussie',
          'headers': headers,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Le sheet est privé. Rendez-le public.',
          'headers': [],
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Sheet introuvable. Vérifiez l\'ID.',
          'headers': [],
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur HTTP ${response.statusCode}',
          'headers': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion : $e',
        'headers': [],
      };
    }
  }

  /// Importer avec contrôle manuel sur les en-têtes
  static Future<List<Product>> fetchProducts(
    String spreadsheetId, {
    String sheetName = 'Feuil1',
    required bool hasHeaders, // Paramètre explicite
  }) async {
    final url = Uri.parse(
      'https://docs.google.com/spreadsheets/d/$spreadsheetId/gviz/tq?'
      'sheet=${Uri.encodeComponent(sheetName)}&tqx=out:json',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 403) {
      throw Exception(
        'Le sheet est privé. Allez dans Google Sheets > Partager > Toute personne avec le lien > Lecteur',
      );
    }

    if (response.statusCode == 404) {
      throw Exception('Sheet introuvable. Vérifiez l\'ID et le nom de la feuille.');
    }

    if (response.statusCode != 200) {
      throw Exception('Erreur HTTP ${response.statusCode}');
    }

    final String body = response.body;
    final int jsonStart = body.indexOf('{');
    final int jsonEnd = body.lastIndexOf('}');

    if (jsonStart == -1 || jsonEnd == -1) {
      throw Exception('Réponse invalide de Google Sheets.');
    }

    final String jsonString = body.substring(jsonStart, jsonEnd + 1);
    final Map<String, dynamic> data = jsonDecode(jsonString);

    final List<dynamic>? rows = data['table']?['rows'];

    if (rows == null || rows.length < 1) {
      throw Exception('Le sheet est vide.');
    }

    // Utiliser l'option utilisateur directement
    int headersStartRow = hasHeaders ? 0 : -1;
    int dataStartRow = hasHeaders ? 1 : 0;

    final List<String> headers;
    if (hasHeaders) {
      headers = [];
      final headerCells = rows[headersStartRow]['c'] as List<dynamic>? ?? [];
      for (final cell in headerCells) {
        final String header = (cell?['v']?.toString() ?? '').trim().toLowerCase();
        headers.add(header);
      }
    } else {
      headers = ['codebarre', 'designation', 'prix', 'quantite'];
    }

    final int colBarcode = _findCol(headers, ['codebarre', 'code_barre', 'barcode', 'ean', 'code-barre', 'code']);
    final int colDesignation = _findCol(headers, ['designation', 'désignation', 'nom', 'name', 'produit', 'libelle', 'libellé', 'description']);
    final int colPrice = _findCol(headers, ['prix', 'price', 'montant', 'tarif', 'unite', 'unité']);
    final int colQuantity = _findCol(headers, ['quantite_disponible', 'quantité_disponible', 'quantite', 'quantité', 'quantity', 'stock', 'disponible']);

    // Ordre par défaut si pas d'en-têtes
    if (!hasHeaders) {
      if (colBarcode == -1) colBarcode = 0;
      if (colDesignation == -1) colDesignation = 1;
      if (colPrice == -1) colPrice = 2;
      if (colQuantity == -1) colQuantity = 3;
    }

    if (colBarcode == -1 && hasHeaders) {
      throw Exception(
        "Colonne 'CodeBarre' introuvable.\n"
        "En-têtes trouvées : ${headers.join(', ')}",
      );
    }

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
      throw Exception('Aucun produit valide trouvé dans le sheet.');
    }

    return products;
  }

  /// Recuperer la liste des feuilles du spreadsheet
  static Future<List<String>> getSheetNames(String spreadsheetId) async {
    try {
      final url = Uri.parse(
        'https://docs.google.com/spreadsheets/d/$spreadsheetId/gviz/tq?tqx=out:json',
      );

      final response = await http.get(url).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) return [];

      // Extraire le JSON du callback
      final String body = response.body;
      final int jsonStart = body.indexOf('{');
      final int jsonEnd = body.lastIndexOf('}');

      if (jsonStart == -1 || jsonEnd == -1) return [];

      final String jsonString = body.substring(jsonStart, jsonEnd + 1);
      final Map<String, dynamic> data = jsonDecode(jsonString);

      final List<String> names = [];

      if (data.containsKey('table')) {
        // Le nom de la feuille est dans le titre
        final String? title = data['table']?['name'];
        if (title != null && title.isNotEmpty) {
          names.add(title);
        }
      }

      return names;
    } catch (_) {
      return [];
    }
  }

  /// Importer les produits depuis Google Sheets
  static Future<List<Product>> fetchProducts(
    String spreadsheetId, {
    String sheetName = 'Feuil1',
  }) async {
    final String encodedSheetName = Uri.encodeComponent(sheetName);

    final url = Uri.parse(
      'https://docs.google.com/spreadsheets/d/$spreadsheetId/gviz/tq?'
      'sheet=$encodedSheetName'
      '&tqx=out:json',
    );

    final response = await http.get(url).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode == 403) {
      throw Exception(
        'Le sheet est prive. Allez dans Google Sheets > '
        'Partager > Toute personne avec le lien > Lecteur',
      );
    }

    if (response.statusCode == 404) {
      throw Exception('Sheet introuvable. Verifiez l\'ID et le nom de la feuille.');
    }

    if (response.statusCode != 200) {
      throw Exception('Erreur HTTP ${response.statusCode}');
    }

    // Parser la reponse JSON (Google renvoie du JSONP)
    final String body = response.body;
    final int jsonStart = body.indexOf('{');
    final int jsonEnd = body.lastIndexOf('}');

    if (jsonStart == -1 || jsonEnd == -1) {
      throw Exception('Reponse invalide de Google Sheets.');
    }

    final String jsonString = body.substring(jsonStart, jsonEnd + 1);
    final Map<String, dynamic> data = jsonDecode(jsonString);

    final List<dynamic>? rows = data['table']?['rows'];

    if (rows == null || rows.length < 2) {
      throw Exception('Le sheet est vide ou contient seulement les en-tetes.');
    }

    // Lire les en-tetes (ligne 0)
    final List<String> headers = [];
    final headerCells = rows[0]['c'] as List<dynamic>? ?? [];

    for (final cell in headerCells) {
      final String header =
          (cell?['v']?.toString() ?? '').trim().toLowerCase();
      headers.add(header);
    }

    // Detecter les colonnes
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
        "En-tetes trouves : ${headers.join(', ')}\n"
        "Attendu : CodeBarre | Designation | Prix | Quantite_Disponible",
      );
    }

    // Parser les donnees
    final List<Product> products = [];

    for (int i = 1; i < rows.length; i++) {
      final cells = rows[i]['c'] as List<dynamic>? ?? [];
      if (cells.isEmpty) continue;

      final String barcode = _getCellStr(cells, colBarcode);
      if (barcode.isEmpty) continue;

      products.add(Product(
        barcode: barcode,
        designation: _getCellStr(cells, colDesignation).isNotEmpty
            ? _getCellStr(cells, colDesignation)
            : '---',
        price: _getCellNum(cells, colPrice),
        quantityAvailable: _getCellNum(cells, colQuantity).toInt(),
      ));
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