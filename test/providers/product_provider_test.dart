import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gluten_search/models/product.dart';
import 'package:gluten_search/providers/product_provider.dart';
import 'package:gluten_search/providers/repository_providers.dart';
import 'package:gluten_search/repositories/products_repository.dart';

class MockProductsRepository extends ProductsRepository {
  final List<Product> mockProducts;
  final String? searchTerm;

  MockProductsRepository({required this.mockProducts, this.searchTerm});

  @override
  Future<List<Product>> getGlutenFreeProducts(String supermarketId) async {
    return mockProducts;
  }

  @override
  Future<List<Product>> searchProductsByName(
    String query, {
    String? supermarketId,
  }) async {
    if (searchTerm != null && query == searchTerm) {
      return mockProducts;
    }
    return [];
  }
}

void main() {
  group('ProductProviders', () {
    final mockProducts = [
      Product(
        id: 'test-1',
        name: 'Test Product 1',
        allergens: ['none'],
        stores: ['Test Store'],
        labels: ['sin gluten'],
      ),
      Product(
        id: 'test-2',
        name: 'Test Product 2',
        allergens: ['none'],
        stores: ['Test Store'],
        labels: ['sin gluten', 'bio'],
      ),
    ];

    test('productsProvider returns products from repository', () async {
      final container = ProviderContainer(
        overrides: [
          productsRepositoryProvider.overrideWithValue(
            MockProductsRepository(mockProducts: mockProducts),
          ),
        ],
      );

      // Limpiar para evitar memory leaks
      addTearDown(container.dispose);

      final asyncValue = container.read(productsProvider('test-store'));
      expect(asyncValue, isA<AsyncLoading<List<Product>>>());

      // Esperar a que la carga termine
      await container.read(productsProvider('test-store').future);

      // Verificar el valor final
      final finalValue = container.read(productsProvider('test-store'));
      expect(finalValue, isA<AsyncData<List<Product>>>());
      expect(finalValue.value, mockProducts);
      expect(finalValue.value!.length, 2);
    });

    test('searchProductsProvider returns filtered products', () async {
      final container = ProviderContainer(
        overrides: [
          productsRepositoryProvider.overrideWithValue(
            MockProductsRepository(
              mockProducts: mockProducts,
              searchTerm: 'Test',
            ),
          ),
        ],
      );

      addTearDown(container.dispose);

      // Realizar búsqueda
      final query = SearchQuery(
        searchTerm: 'Test',
        supermarketId: 'test-store',
      );
      final asyncValue = container.read(searchProductsProvider(query));
      expect(asyncValue, isA<AsyncLoading<List<Product>>>());

      // Esperar a que la búsqueda termine
      await container.read(searchProductsProvider(query).future);

      // Verificar el resultado de la búsqueda
      final finalValue = container.read(searchProductsProvider(query));
      expect(finalValue, isA<AsyncData<List<Product>>>());
      expect(finalValue.value, mockProducts);
      expect(finalValue.value!.length, 2);
    });

    test('filteredProductsProvider filters products locally', () async {
      final container = ProviderContainer(
        overrides: [
          productsRepositoryProvider.overrideWithValue(
            MockProductsRepository(mockProducts: mockProducts),
          ),
        ],
      );

      addTearDown(container.dispose);

      // Primero cargar los productos
      await container.read(productsProvider('test-store').future);

      // Luego filtrar con un parámetro que coincida con el primer producto
      final filterParams = FilterParams(
        supermarketId: 'test-store',
        searchQuery: 'Product 1',
      );

      final filteredResult = container.read(
        filteredProductsProvider(filterParams),
      );

      // Esperar a que el filtrado esté completo si es asíncrono
      if (filteredResult is AsyncLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final finalFilteredValue = container.read(
        filteredProductsProvider(filterParams),
      );

      expect(finalFilteredValue.value?.length, 1);
      expect(finalFilteredValue.value?[0].id, 'test-1');
    });
  });
}
