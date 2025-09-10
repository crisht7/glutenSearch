import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import 'repository_providers.dart';

// Define SearchQuery if it doesn't exist elsewhere
class SearchQuery {
  final String searchTerm;
  final String supermarketId;

  SearchQuery({required this.searchTerm, required this.supermarketId});
}

// Clase para los parámetros de filtrado
class FilterParams {
  final String supermarketId;
  final String searchQuery;

  FilterParams({required this.supermarketId, required this.searchQuery});
}

// Provider principal para obtener productos por supermercado
final productsProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, supermarketId) {
      final repository = ref.watch(productsRepositoryProvider);
      return repository.getGlutenFreeProducts(supermarketId);
    });

// Provider para búsqueda específica de productos
final searchProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, SearchQuery>((ref, query) {
      final repository = ref.watch(productsRepositoryProvider);
      return repository.searchProductsByName(
        query.searchTerm,
        supermarketId: query.supermarketId,
      );
    });

// Provider para productos filtrados localmente (para búsqueda rápida)
final filteredProductsProvider = Provider.autoDispose
    .family<AsyncValue<List<Product>>, FilterParams>((ref, params) {
      final productsAsync = ref.watch(productsProvider(params.supermarketId));

      return productsAsync.when(
        data: (products) {
          if (params.searchQuery.isEmpty) {
            return AsyncValue.data(products);
          }

          final query = params.searchQuery;

          final filtered = products
              .where((product) => product.matchesQuery(query))
              .toList();

          // Ordenar por puntuación de relevancia descendente
          filtered.sort(
            (a, b) =>
                b.relevanceScore(query).compareTo(a.relevanceScore(query)),
          );

          return AsyncValue.data(filtered);
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
    });

// Provider para estadísticas de productos
final productStatsProvider = Provider.autoDispose
    .family<AsyncValue<ProductStats>, String>((ref, supermarketId) {
      final productsAsync = ref.watch(productsProvider(supermarketId));

      return productsAsync.when(
        data: (products) {
          final ratedProducts = products
              .where((p) => p.rating != null)
              .map((p) => p.rating!)
              .toList();

          final stats = ProductStats(
            totalProducts: products.length,
            withImages: products.where((p) => p.imageUrl != null).length,
            withBrands: products.where((p) => p.brands != null).length,
            withIngredients: products
                .where((p) => p.ingredients != null)
                .length,
            categoriesCount: products.map((p) => p.safeCategory).toSet().length,
            averageRating: ratedProducts.isNotEmpty
                ? ratedProducts.reduce((a, b) => a + b) / ratedProducts.length
                : 0.0,
          );

          return AsyncValue.data(stats);
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
    });

// Clase para estadísticas de productos
class ProductStats {
  final int totalProducts;
  final int withImages;
  final int withBrands;
  final int withIngredients;
  final int categoriesCount;
  final double averageRating;

  ProductStats({
    required this.totalProducts,
    required this.withImages,
    required this.withBrands,
    required this.withIngredients,
    required this.categoriesCount,
    required this.averageRating,
  });
}

// Provider para limpiar caché
final clearCacheProvider = Provider<void Function()>((ref) {
  return () {
    final repository = ref.read(productsRepositoryProvider);
    repository.clearCache();

    ref.invalidateSelf();
    ref.container.invalidate(productsProvider);
    ref.container.invalidate(searchProductsProvider);
    ref.container.invalidate(filteredProductsProvider);
    ref.container.invalidate(productStatsProvider);
  };
});
