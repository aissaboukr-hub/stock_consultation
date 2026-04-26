import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

class ResultScreen extends StatelessWidget {
  final String barcodeScanned;
  const ResultScreen({super.key, required this.barcodeScanned});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProductProvider>();
    final Product? product =
        provider.findProductByBarcode(barcodeScanned);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          'Resultat du scan',
          style:
              TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: product != null
            ? _buildProductFound(context, product)
            : _buildProductNotFound(context),
      ),
    );
  }

  Widget _buildProductFound(BuildContext context, Product product) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle_rounded,
              size: 72, color: Colors.green.shade600),
        ),
        const SizedBox(height: 12),
        Text(
          'Produit trouve !',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Code-barres : $barcodeScanned',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDetailRow(
                icon: Icons.label_outline_rounded,
                label: 'Designation',
                value: product.designation,
              ),
              const Divider(height: 32),
              _buildDetailRow(
                icon: Icons.euro_rounded,
                label: 'Prix',
                value: product.formattedPrice,
              ),
              const Divider(height: 32),
              _buildDetailRow(
                icon: product.isInStock
                    ? Icons.inventory_rounded
                    : Icons.remove_shopping_cart_rounded,
                label: 'Disponibilite',
                value: product.availabilityStatus,
                valueColor: product.isInStock
                    ? (product.quantityAvailable <= 5
                        ? Colors.orange.shade700
                        : Colors.green.shade700)
                    : Colors.red.shade700,
              ),
              const Divider(height: 32),
              _buildDetailRow(
                icon: Icons.format_list_numbered_rounded,
                label: 'Quantite exacte',
                value: '${product.quantityAvailable} unites',
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon:
                const Icon(Icons.qr_code_scanner_rounded, size: 22),
            label: const Text(
              'Scanner un autre produit',
              style: TextStyle(fontSize: 16),
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
        const SizedBox(height: 12),
        TextButton(
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
          child: const Text("Retour a l'accueil"),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProductNotFound(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.search_off_rounded,
              size: 72, color: Colors.orange.shade600),
        ),
        const SizedBox(height: 12),
        Text(
          'Produit non trouve',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Code-barres : $barcodeScanned',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Colors.orange.shade400, size: 36),
              const SizedBox(height: 14),
              const Text(
                "Ce code-barres n'existe pas dans la base de donnees importee.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Verifiez que votre fichier Excel contient bien ce produit.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon:
                const Icon(Icons.qr_code_scanner_rounded, size: 22),
            label: const Text(
              'Scanner un autre produit',
              style: TextStyle(fontSize: 16),
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
        const SizedBox(height: 12),
        TextButton(
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
          child: const Text("Retour a l'accueil"),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              Icon(icon, color: const Color(0xFF1A237E), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}