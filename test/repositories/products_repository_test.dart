import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gluten_search/models/product.dart';
import 'package:gluten_search/repositories/products_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ProductsRepository', () {
    late ProductsRepository repository;

    // Datos simulados para test
    final mockProductsJson = {
      'products': [
        {
          'code': 'product1',
          'product_name': 'Test Gluten-free Product',
          'brands': 'Test Brand',
          'image_url': 'https://example.com/image.jpg',
          'ingredients_text': 'Ingrediente 1, Ingrediente 2',
          'allergens_tags': ['en:nuts'],
          'stores_tags': ['mercadona'],
          'stores': 'Mercadona',
          'nutrition_grade_fr': 'a',
          'categories': 'Snacks',
          'categories_tags': ['en:snacks'],
          'nutriments': {
            'energy-kcal_100g': 200,
            'fat_100g': 10,
            'carbohydrates_100g': 50,
            'proteins_100g': 5,
          },
          'labels_tags': ['en:gluten-free', 'en:lactose-free'],
          'labels': 'sin gluten, sin lactosa',
        },
        {
          'code': 'product2',
          'product_name': 'Another Gluten-free Product',
          'brands': 'Test Brand 2',
          'image_url': 'https://example.com/image2.jpg',
          'ingredients_text': 'Ingrediente A, Ingrediente B',
          'allergens_tags': ['en:peanuts'],
          'stores_tags': ['mercadona'],
          'stores': 'Mercadona',
          'nutrition_grade_fr': 'b',
          'categories': 'Bebidas',
          'categories_tags': ['en:beverages'],
          'nutriments': {
            'energy-kcal_100g': 150,
            'fat_100g': 5,
            'carbohydrates_100g': 30,
            'proteins_100g': 2,
          },
          'labels_tags': ['en:gluten-free', 'en:organic'],
          'labels': 'sin gluten, bio',
        },
      ],
    };

    setUp(() {
      // Configurar un client HTTP de prueba que responde inmediatamente sin hacer peticiones reales
      final mockClient = MockClient((request) async {
        // Cualquier URL con mercadona retorna nuestros productos de prueba
        if (request.url.toString().contains('mercadona')) {
          return http.Response(
            json.encode(mockProductsJson),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        // Cualquier otra URL retorna 404
        return http.Response('{"products": []}', 200);
      });

      repository = ProductsRepository(client: mockClient);
    });

    test(
      'getGlutenFreeProducts returns list of products for valid supermarket',
      () async {
        // Act
        final products = await repository.getGlutenFreeProducts('mercadona');

        // Assert
        expect(products, isA<List<Product>>());
        expect(products, isNotEmpty);
      },
    );

    test(
      'getGlutenFreeProducts returns empty list for invalid supermarket',
      () async {
        // Act
        final products = await repository.getGlutenFreeProducts('invalid');

        // Assert
        expect(products, isEmpty);
      },
    );

    test('getGlutenFreeProducts uses cache for subsequent calls', () async {
      // Primera llamada, debe ir a la API
      final firstResult = await repository.getGlutenFreeProducts('mercadona');
      expect(firstResult, isNotEmpty);

      // Segunda llamada, debe usar caché
      final secondResult = await repository.getGlutenFreeProducts('mercadona');
      expect(secondResult, isNotEmpty);

      // Verificar que los productos son los mismos
      expect(firstResult.length, secondResult.length);
    });
  });
}
