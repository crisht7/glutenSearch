import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_router.dart';
import '../../core/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/app_drawer.dart';
import '../../models/product.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSupermarket = 'mercadona';
  final Set<String> _selectedAllergens = {};
  bool _showResults = false;
  bool _showFilters = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _supermarkets = [
    {'id': 'mercadona', 'name': 'Mercadona', 'icon': Icons.store},
    {'id': 'carrefour', 'name': 'Carrefour', 'icon': Icons.shopping_cart},
    {'id': 'eroski', 'name': 'Eroski', 'icon': Icons.local_grocery_store},
  ];

  final List<Map<String, dynamic>> _allergens = [
    {'id': 'gluten', 'name': 'Gluten', 'icon': Icons.grain},
    {'id': 'lactose', 'name': 'Lactosa', 'icon': Icons.local_drink},
    {'id': 'nuts', 'name': 'Frutos secos', 'icon': Icons.nature},
    {'id': 'eggs', 'name': 'Huevos', 'icon': Icons.egg},
    {'id': 'fish', 'name': 'Pescado', 'icon': Icons.set_meal},
    {'id': 'soy', 'name': 'Soja', 'icon': Icons.eco},
    {'id': 'celery', 'name': 'Apio', 'icon': Icons.grass},
    {'id': 'mustard', 'name': 'Mostaza', 'icon': Icons.local_florist},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _performSearch() {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _showResults = true;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _showResults = false;
      _selectedAllergens.clear();
    });
  }

  List<Product> _filterByAllergens(List<Product> products) {
    if (_selectedAllergens.isEmpty) return products;

    return products.where((product) {
      // Filtrar productos que NO contengan los alérgenos seleccionados
      final productAllergens = product.allergens
          .map((a) => a.toLowerCase())
          .toSet();
      final selectedAllergensLower = _selectedAllergens
          .map((a) => a.toLowerCase())
          .toSet();

      // Si el producto contiene algún alérgeno seleccionado, no lo incluimos
      return !productAllergens.any(
        (allergen) => selectedAllergensLower.contains(allergen),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('GlutenSearch'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.cart);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppRouter.main),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Header con logo/icono
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.search, size: 64, color: AppTheme.primaryGreen),
                  const SizedBox(height: 16),
                  Text(
                    _showResults
                        ? 'Resultados de búsqueda'
                        : '¿Qué producto buscas hoy?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.darkGreen,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!_showResults) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Encuentra productos sin gluten y otros alérgenos',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _performSearch(),
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.primaryGreen,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Selector de supermercado
            Container(
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _supermarkets.length,
                itemBuilder: (context, index) {
                  final supermarket = _supermarkets[index];
                  final isSelected = _selectedSupermarket == supermarket['id'];

                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedSupermarket = supermarket['id'];
                        });
                      },
                      avatar: Icon(
                        supermarket['icon'],
                        color: isSelected
                            ? Colors.white
                            : AppTheme.primaryGreen,
                        size: 20,
                      ),
                      label: Text(supermarket['name']),
                      selectedColor: AppTheme.primaryGreen,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Botón de filtros de alérgenos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                      icon: Icon(_showFilters ? Icons.expand_less : Icons.tune),
                      label: Text(
                        _selectedAllergens.isEmpty
                            ? 'Filtros de alérgenos'
                            : 'Filtros (${_selectedAllergens.length})',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedAllergens.isNotEmpty
                            ? AppTheme.secondaryGreen
                            : Colors.white,
                        foregroundColor: _selectedAllergens.isNotEmpty
                            ? Colors.white
                            : AppTheme.primaryGreen,
                        side: BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _performSearch,
                    child: const Text('Buscar'),
                  ),
                ],
              ),
            ),

            // Panel de filtros de alérgenos (expansible)
            if (_showFilters) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.lightGreen),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Excluir productos con:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allergens.map((allergen) {
                        final isSelected = _selectedAllergens.contains(
                          allergen['id'],
                        );
                        return FilterChip(
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAllergens.add(allergen['id']);
                              } else {
                                _selectedAllergens.remove(allergen['id']);
                              }
                            });
                          },
                          avatar: Icon(
                            allergen['icon'],
                            color: isSelected
                                ? Colors.white
                                : AppTheme.primaryGreen,
                            size: 18,
                          ),
                          label: Text(allergen['name']),
                          selectedColor: AppTheme.errorRed,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.primaryGreen,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Resultados de búsqueda
            if (_showResults)
              Expanded(child: _buildSearchResults())
            else
              Expanded(child: _buildWelcomeMessage()),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Escribe el nombre del producto\nque quieres buscar',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final query = SearchQuery(
      searchTerm: _searchController.text.trim(),
      supermarketId: _selectedSupermarket,
    );

    final searchResults = ref.watch(searchProductsProvider(query));

    return searchResults.when(
      data: (products) {
        final filteredProducts = _filterByAllergens(products);

        if (filteredProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No se encontraron productos',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Intenta con otros términos de búsqueda\no ajusta los filtros',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header con contador de resultados
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${filteredProducts.length} resultado${filteredProducts.length != 1 ? 's' : ''} encontrado${filteredProducts.length != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.darkGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedAllergens.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedAllergens.clear();
                        });
                      },
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Limpiar filtros'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            // Lista de productos
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: filteredProducts[index]);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: LoadingSpinner()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
            const SizedBox(height: 16),
            Text(
              'Error al buscar productos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.errorRed),
            ),
            const SizedBox(height: 8),
            Text(
              'Inténtalo de nuevo más tarde',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(searchProductsProvider);
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
