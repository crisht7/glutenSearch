import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../core/app_theme.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';

class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    final isRegisteredUser =
        authState.value != null && !authState.value!.isAnonymous;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showProductDetails(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.safeImageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 32,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (product.brands != null) ...[
                      Text(
                        product.safeBrands,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Etiqueta sin gluten
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SIN GLUTEN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Botones de acción
                    Row(
                      children: [
                        // Botón agregar al carrito
                        ElevatedButton.icon(
                          onPressed: () => _addToCart(ref),
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Botón favorito (solo para usuarios registrados)
                        if (isRegisteredUser)
                          IconButton(
                            onPressed: () => _toggleFavorite(ref),
                            icon: const Icon(Icons.favorite_border),
                            iconSize: 20,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            color: AppTheme.errorRed,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart(WidgetRef ref) {
    try {
      ref.read(cartNotifierProvider.notifier).addItem(product);
      // Mostrar snackbar de éxito
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('${product.name} agregado al carrito'),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Mostrar snackbar de error
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar al carrito: $e'),
          backgroundColor: AppTheme.errorRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _toggleFavorite(WidgetRef ref) {
    try {
      ref.read(userProfileProvider.notifier).addFavorite(product);
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('${product.name} agregado a favoritos'),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar a favoritos: $e'),
          backgroundColor: AppTheme.errorRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showProductDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductDetailsModal(product: product),
    );
  }
}

class _ProductDetailsModal extends StatelessWidget {
  final Product product;

  const _ProductDetailsModal({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Contenido
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.safeImageUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 64,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Nombre
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Marca
                  if (product.brands != null) ...[
                    Text(
                      product.safeBrands,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Etiqueta sin gluten
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PRODUCTO SIN GLUTEN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Ingredientes
                  if (product.ingredients != null) ...[
                    const Text(
                      'Ingredientes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.ingredients!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Alérgenos
                  if (product.allergens.isNotEmpty) ...[
                    const Text(
                      'Alérgenos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.allergens.map((allergen) {
                        return Chip(
                          label: Text(
                            allergen.replaceAll('en:', ''),
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: AppTheme.warningOrange.withOpacity(
                            0.2,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Tiendas
                  if (product.stores.isNotEmpty) ...[
                    const Text(
                      'Disponible en',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.stores.map((store) {
                        return Chip(
                          label: Text(
                            store.replaceAll('en:', ''),
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: AppTheme.lightGreen,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Botón cerrar
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
