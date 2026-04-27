import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import 'scanner_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les produits sauvegardes au demarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadSavedProducts();
    });
  }

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
        actions: [
          // Icône Paramètres
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
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

                // Bouton Scanner
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
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
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

                // Bouton Rechercher
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: provider.isDatabaseLoaded && !provider.isLoading
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SearchScreen()),
                            )
                        : null,
                    icon: const Icon(Icons.search_rounded, size: 24),
                    label: const Text(
                      'Rechercher un produit',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: provider.isDatabaseLoaded
                          ? const Color(0xFF1565C0)
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

                const Spacer(),

                // Info rapide
                if (!provider.isDatabaseLoaded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Appuyez sur l\'icone parametres en haut a droite pour importer votre fichier Excel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        height: 1.5,
                      ),
                    ),
                  ),

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
      subtitle = 'Lecture des donnees en cours';
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
      title = 'Base de donnees chargee';
      subtitle = provider.lastImportDate != null
          ? '${provider.productCount} produits - Importe le ${provider.lastImportDate}'
          : '${provider.productCount} produits charges';
    } else {
      cardColor = Colors.grey.shade100;
      iconBg = Colors.grey;
      icon = Icons.info_outline_rounded;
      title = 'Aucune donnee importee';
      subtitle = 'Importez un fichier .xlsx depuis les parametres';
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
}