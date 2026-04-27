import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import 'google_sheets_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          'Parametres',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre section
                Text(
                  'BASE DE DONNEES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Carte info BDD
                _buildDatabaseCard(provider),
                const SizedBox(height: 28),

                // Titre section Sources
                Text(
                  'SOURCES D\'IMPORT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Bouton Importer Excel
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () => _handleImportExcel(context, provider),
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.file_upload_outlined, size: 24),
                    label: Text(
                      provider.isLoading
                          ? 'Importation en cours...'
                          : 'Importer depuis Excel (.xlsx)',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Bouton Google Sheets
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GoogleSheetsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.cloud_download_outlined,
                        color: Color(0xFF1A237E)),
                    label: const Text(
                      'Importer depuis Google Sheets',
                      style:
                          TextStyle(color: Color(0xFF1A237E), fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1A237E)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bouton Reinitialiser
                if (provider.isDatabaseLoaded) ...[
                  const SizedBox(height: 8),
                  Text(
                    'GESTION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmReset(context, provider),
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red),
                      label: const Text(
                        'Reinitialiser la base de donnees',
                        style:
                            TextStyle(color: Colors.red, fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                Center(
                  child: Text(
                    'v1.0 - Consultation de Stock',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDatabaseCard(ProductProvider provider) {
    final Color cardColor;
    final Color iconBg;
    final IconData icon;
    final String title;
    final String subtitle;

    if (provider.isLoading) {
      cardColor = Colors.blue.shade50;
      iconBg = Colors.blue;
      icon = Icons.hourglass_empty_rounded;
      title = 'Importation en cours';
      subtitle = 'Lecture du fichier...';
    } else if (provider.error != null) {
      cardColor = Colors.red.shade50;
      iconBg = Colors.red;
      icon = Icons.error_outline_rounded;
      title = 'Erreur';
      subtitle = provider.error!;
    } else if (provider.isDatabaseLoaded) {
      cardColor = Colors.green.shade50;
      iconBg = Colors.green;
      icon = Icons.storage_rounded;
      title =
          '${provider.productCount} produit${provider.productCount > 1 ? 's' : ''} enregistre${provider.productCount > 1 ? 's' : ''}';
      subtitle = provider.lastImportDate != null
          ? 'Importe le ${provider.lastImportDate}'
          : 'Base de donnees disponible';
    } else {
      cardColor = Colors.grey.shade100;
      iconBg = Colors.grey;
      icon = Icons.cloud_off_rounded;
      title = 'Aucune donnee';
      subtitle = 'Importez un fichier pour commencer';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconBg.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconBg, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: iconBg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: iconBg.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImportExcel(
      BuildContext context, ProductProvider provider) async {
    final success = await provider.importFromExcel();
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${provider.productCount} produits importes et sauvegardes !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${provider.error}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _confirmReset(
      BuildContext context, ProductProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reinitialiser ?'),
        content: const Text(
            'Toutes les donnees importees seront supprimees. Cette action est irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.clearDatabase();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Base de donnees reinitialisee'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}