import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../services/google_sheets_service.dart';

class GoogleSheetsScreen extends StatefulWidget {
  const GoogleSheetsScreen({super.key});

  @override
  State<GoogleSheetsScreen> createState() => _GoogleSheetsScreenState();
}

class _GoogleSheetsScreenState extends State<GoogleSheetsScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _sheetNameController =
      TextEditingController(text: 'Feuil1');
  
  String? _spreadsheetId;
  bool _hasHeaders = true; // Option explicite pour les en-têtes
  bool _isChecking = false;
  bool _isImporting = false;
  String? _statusMessage;
  bool _isStatusError = false;
  List<String>? _detectedHeaders; // Pour afficher à l'utilisateur

  @override
  void dispose() {
    _urlController.dispose();
    _sheetNameController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final String input = _urlController.text.trim();
    if (input.isEmpty) {
      _showStatus('Veuillez entrer un ID ou une URL.', true);
      return;
    }

    final String? id = GoogleSheetsService.extractSpreadsheetId(input);
    if (id == null) {
      _showStatus('Format invalide.', true);
      return;
    }

    setState(() {
      _isChecking = true;
      _spreadsheetId = id;
      _statusMessage = null;
      _detectedHeaders = null;
    });

    try {
      final result = await GoogleSheetsService.testConnectionAndHeaders(
        id,
        sheetName: _sheetNameController.text.trim(),
      );

      // Decider automatiquement si cocher ou non
      final bool autoDetectHasHeaders = result['hasHeaders'] ?? false;

      setState(() {
        _isChecking = false;
        _isStatusError = !result['success'];
        _statusMessage = result['message'];
        _detectedHeaders = result['headers'] as List<String>?;
        _hasHeaders = autoDetectHasHeaders;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _isStatusError = true;
        _statusMessage = 'Erreur : $e';
      });
    }
  }

  Future<void> _importFromGoogleSheets() async {
    if (_spreadsheetId == null) {
      _showStatus('Vérifiez d\'abord la connexion.', true);
      return;
    }

    final String sheetName = _sheetNameController.text.trim();
    if (sheetName.isEmpty) {
      _showStatus('Indiquez le nom de la feuille.', true);
      return;
    }

    setState(() {
      _isImporting = true;
      _statusMessage = null;
    });

    try {
      final products = await GoogleSheetsService.fetchProducts(
        _spreadsheetId!,
        sheetName: sheetName,
        hasHeaders: _hasHeaders,
      );

      final provider = context.read<ProductProvider>();
      await provider.saveProductsDirectly(products);

      if (!mounted) return;

      setState(() {
        _isImporting = false;
        _isStatusError = false;
        _statusMessage = '${products.length} produits importés avec succès !';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${products.length} produits importés depuis Google Sheets !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      setState(() {
        _isImporting = false;
        _isStatusError = true;
        _statusMessage = e.toString();
      });
    }
  }

  void _showStatus(String message, bool isError) {
    setState(() {
      _statusMessage = message;
      _isStatusError = isError;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          'Google Sheets',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explication conditions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Champ URL / ID
            Text(
              'URL ou ID du Google Sheet',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://docs.google.com/spreadsheets/d/XXXXX/edit',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.link, color: Color(0xFF1A237E)),
                suffixIcon: _urlController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _urlController.clear();
                          setState(() {
                            _spreadsheetId = null;
                            _statusMessage = null;
                            _detectedHeaders = null;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Nom de la feuille
            Text(
              'Nom de la feuille',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sheetNameController,
              decoration: InputDecoration(
                hintText: 'Feuil1',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.table_chart, color: Color(0xFF1A237E)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Toggle En-têtes
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _hasHeaders,
                        onChanged: (value) {
                          setState(() => _hasHeaders = value ?? false);
                        },
                        activeColor: const Color(0xFF1A237E),
                      ),
                      
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Si coché : CodeBarre | Designation | Prix | Quantite\n'
                    'Si décoché : Colonne 1=CodeBarre, 2=Désignation, 3=Prix, 4=Quantité',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bouton Vérifier
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _isChecking ? null : _checkConnection,
                icon: _isChecking
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.wifi_find_rounded),
                label: Text(
                  _isChecking ? 'Vérification...' : 'Tester la connexion',
                  style: const TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A237E),
                  side: const BorderSide(color: Color(0xFF1A237E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            // Affichage des en-têtes détectées
            if (_detectedHeaders != null && _detectedHeaders!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.yellow.shade300),
                ),
                
              ),
            ],

            // Statut
            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isStatusError ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isStatusError ? Colors.red.shade300 : Colors.green.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isStatusError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: _isStatusError ? Colors.red.shade600 : Colors.green.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: _isStatusError ? Colors.red.shade700 : Colors.green.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Bouton Importer
            if (_spreadsheetId != null && !_isStatusError)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isImporting ? null : _importFromGoogleSheets,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_download_rounded, size: 24),
                  label: Text(
                    _isImporting ? 'Importation en cours...' : 'Importer depuis Google Sheets',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43A047),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}