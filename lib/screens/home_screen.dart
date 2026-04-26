import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          'Consultation de Stock',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    size: 64,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 28),
                _buildStatusCard(provider),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () => _handleImport(context, provider),
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
                          : 'Importer la base de donnees (.xlsx)',
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: provider.isDatabaseLoaded && !provider.isLoading
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ScannerScreen()),
                            )
                        : null,
                    icon:
                        const Icon(Icons.qr_code_scanner_rounded, size: 24),
                    label: const Text(
                      'Scanner un produit',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: provider.isDatabaseLoaded
                          ? const Color(0xFF43A047)
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: provider.isDatabaseLoaded ? 2 : 0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (provider.isDatabaseLoaded)
                  TextButton.icon(
                    onPressed: () {
                      provider.clearDatabase();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Base de donnees reinitialisee'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon:
                        const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Reinitialiser',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                const Spacer(),
                Text(
                  'v1.0 - Consultation de Stock',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
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

  Widget _buildStatusCard(ProductProvider provider) {
    final Color cardColor;
    final Color iconBg;
    final IconData icon;
    final String title;
    final String subtitle;

    if (provider.isLoading) {
      cardColor = Colors.blue.shade50;
      iconBg = Colors.blue;
      icon = Icons.hourglass_empty_rounded;
      title = 'Chargement...';
      subtitle = 'Lecture du fichier en cours';
    } else if (provider.error != null) {
      cardColor = Colors.red.shade50;
      iconBg = Colors.red;
      icon = Icons.error_outline_rounded;
      title = 'Erreur';
      subtitle = provider.error!;
    } else if (provider.isDatabaseLoaded) {
      cardColor = Colors.green.shade50;
      iconBg = Colors.green;
      icon = Icons.check_circle_outline_rounded;
      title = 'Base de donnees importee';
      subtitle = '${provider.productCount} produits charges';
    } else {
      cardColor = Colors.grey.shade100;
      iconBg = Colors.grey;
      icon = Icons.info_outline_rounded;
      title = 'Aucune donnee importee';
      subtitle = 'Importez un fichier .xlsx pour commencer';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconBg.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconBg, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImport(
      BuildContext context, ProductProvider provider) async {
    final success = await provider.importFromExcel();
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${provider.productCount} produits importes avec succes !'),
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
}