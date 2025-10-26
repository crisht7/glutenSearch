import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/app_router.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/app_drawer.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  int _currentIndex = 0;
  String _selectedSupermarket = 'mercadona';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _supermarkets = [
    {'id': 'mercadona', 'name': 'Mercadona', 'icon': Icons.store},
    {'id': 'carrefour', 'name': 'Carrefour', 'icon': Icons.shopping_cart},
    {'id': 'eroski', 'name': 'Eroski', 'icon': Icons.local_grocery_store},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.cart);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppRouter.catalog),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildCatalogTab(),
          const CartScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Catálogo'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildCatalogTab() {
    return Column(
      children: [
        // Barra de búsqueda
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.lightGreen,
          child: Column(
            children: [
              TextField(
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  // Log de escritura en el buscador (evita logs cuando está vacío)
                  if (value.trim().isNotEmpty) {
                    debugPrint('[SEARCH_UI] typing query="$value"');
                  }
                },
                onSubmitted: (value) {
                  // El usuario pulsa el botón "Buscar" del teclado
                  debugPrint('[SEARCH_UI] submitted query="$value"');
                  setState(() {
                    _searchQuery = value;
                  });
                  FocusScope.of(context).unfocus();
                },
                decoration: const InputDecoration(
                  hintText: 'Buscar productos...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Selector de supermercado
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _supermarkets.length,
                  itemBuilder: (context, index) {
                    final supermarket = _supermarkets[index];
                    final isSelected =
                        _selectedSupermarket == supermarket['id'];

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FilterChip(
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedSupermarket = supermarket['id'];
                          });
                          debugPrint(
                            '[SEARCH_SUPERMARKET] selected id="${supermarket['id']}" name="${supermarket['name']}"',
                          );
                        },
                        avatar: Icon(
                          supermarket['icon'],
                          color: isSelected
                              ? Colors.white
                              : AppTheme.primaryGreen,
                        ),
                        label: Text(supermarket['name']),
                        selectedColor: AppTheme.primaryGreen,
                        checkmarkColor: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Lista de productos
        Expanded(child: _buildProductsList()),
      ],
    );
  }

  Widget _buildProductsList() {
    final productsAsync = ref.watch(productsProvider(_selectedSupermarket));

    return productsAsync.when(
      data: (products) {
        // Filtrar productos según la búsqueda
        final filteredProducts = products.where((product) {
          return _searchQuery.isEmpty ||
              product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (product.brands?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false);
        }).toList();

        if (filteredProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isNotEmpty
                      ? Icons.search_off
                      : Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No se encontraron productos'
                      : 'No hay productos disponibles',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Intenta con otros términos de búsqueda',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            debugPrint(
              '[REFRESH] manually refreshing products for supermarket="$_selectedSupermarket"',
            );
            ref.invalidate(productsProvider(_selectedSupermarket));
          },
          child: ListView.builder(
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return ProductCard(product: product);
            },
          ),
        );
      },
      loading: () => const Center(child: LoadingSpinner()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar productos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(productsProvider(_selectedSupermarket));
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
