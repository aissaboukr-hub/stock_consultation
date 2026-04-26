import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import 'result_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Product> _filteredProducts = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search(String query, List<Product> allProducts) {
    final String searchTerm = query.trim().toLowerCase();

    setState(() {
      _hasSearched = searchTerm.isNotEmpty;

      if (searchTerm.isEmpty) {
        _filteredProducts = [];
        return;
      }

      _filteredProducts = allProducts.where((product) {
        final designation = product.designation.toLowerCase();
        final barcode = product.barcode.toLowerCase();

        // Recherche dans designation ET code-barres
        return designation.contains(searchTerm) ||
            barcode.contains(searchTerm);
      }).toList();

      // Trier par pertinence (commence par > contient)
      _filteredProducts.sort((a, b) {
        final aStartsWith =
            a.designation.toLowerCase().startsWith(searchTerm) ? 0 : 1;
        final bStartsWith =
            b.designation.toLowerCase().startsWith(searchTerm) ? 0 : 1;
        return aStartsWith.compareTo(bStartsWith);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final allProducts = provider.products;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          'Rechercher un produit',
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
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A237E),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: (value) => _search(value, allProducts),
                decoration: InputDecoration(
                  hintText: 'Nom du produit ou code-barres...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1A237E)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _search('', allProducts);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                textInputAction: TextInputAction.search,
              ),
            ),
          ),

          // Compteur de résultats
          if (_hasSearched)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey.shade100,
              child: Text(
                _filteredProducts.isEmpty
                    ? 'Aucun resultat trouve'
                    : '${_filteredProducts.length} resultat${_filteredProducts.length > 1 ? 's' : ''} trouve${_filteredProducts.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Liste des résultats
          Expanded(
            child: _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Tapez pour rechercher',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recherchez par nom ou code-barres',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Colors.orange.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun produit trouve',
              style: TextStyle(
                fontSize: 18,
                color: Colors.orange.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez un autre terme de recherche',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _ProductCard(
          product: product,
          searchTerm: _searchController.text,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ResultScreen(barcodeScanned: product.barcode),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final String searchTerm;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.searchTerm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône stock
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: product.isInStock
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  product.isInStock
                      ? Icons.inventory_rounded
                      : Icons.remove_shopping_cart_rounded,
                  color: product.isInStock
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Infos produit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Désignation avec highlight
                    _HighlightedText(
                      text: product.designation,
                      highlight: searchTerm,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                      highlightStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                        backgroundColor: Color(0xFFFFEB3B),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Code-barres
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _HighlightedText(
                            text: product.barcode,
                            highlight: searchTerm,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontFamily: 'monospace',
                            ),
                            highlightStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontFamily: 'monospace',
                              backgroundColor: const Color(0xFFFFEB3B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Prix et stock
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A237E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.formattedPrice,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: product.isInStock
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.isInStock
                                ? 'Stock: ${product.quantityAvailable}'
                                : 'Rupture',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: product.isInStock
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Flèche
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget pour surligner le terme recherché
class _HighlightedText extends StatelessWidget {
  final String text;
  final String highlight;
  final TextStyle style;
  final TextStyle highlightStyle;

  const _HighlightedText({
    required this.text,
    required this.highlight,
    required this.style,
    required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty) {
      return Text(text, style: style, maxLines: 2, overflow: TextOverflow.ellipsis);
    }

    final String lowerText = text.toLowerCase();
    final String lowerHighlight = highlight.toLowerCase().trim();
    final int index = lowerText.indexOf(lowerHighlight);

    if (index == -1) {
      return Text(text, style: style, maxLines: 2, overflow: TextOverflow.ellipsis);
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, index),
            style: style,
          ),
          TextSpan(
            text: text.substring(index, index + highlight.length),
            style: highlightStyle,
          ),
          TextSpan(
            text: text.substring(index + highlight.length),
            style: style,
          ),
        ],
      ),
    );
  }
}