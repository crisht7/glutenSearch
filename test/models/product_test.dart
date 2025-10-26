import 'package:flutter_test/flutter_test.dart';
import 'package:gluten_search/models/product.dart';

void main() {
  group('Product', () {
    test('safeImageUrl devuelve URL proporcionada cuando es válida', () {
      final product = Product(
        id: 'test-1',
        name: 'Test Product',
        imageUrl: 'https://example.com/image.jpg',
        allergens: [],
        stores: [],
        labels: [],
      );

      expect(product.safeImageUrl, 'https://example.com/image.jpg');
    });

    test('safeImageUrl devuelve URL por defecto cuando imageUrl es null', () {
      final product = Product(
        id: 'test-1',
        name: 'Test Product',
        imageUrl: null,
        allergens: [],
        stores: [],
        labels: [],
      );

      expect(
        product.safeImageUrl,
        'https://images.openfoodfacts.org/images/icons/uploads-big-icon.svg',
      );
    });

    test(
      'safeImageUrl devuelve URL por defecto cuando imageUrl está vacío',
      () {
        final product = Product(
          id: 'test-1',
          name: 'Test Product',
          imageUrl: '',
          allergens: [],
          stores: [],
          labels: [],
        );

        expect(
          product.safeImageUrl,
          'https://images.openfoodfacts.org/images/icons/uploads-big-icon.svg',
        );
      },
    );

    test(
      'safeImageUrl devuelve URL por defecto cuando imageUrl contiene placeholder',
      () {
        final product = Product(
          id: 'test-1',
          name: 'Test Product',
          imageUrl: 'some_placeholder_image.jpg',
          allergens: [],
          stores: [],
          labels: [],
        );

        expect(
          product.safeImageUrl,
          'https://images.openfoodfacts.org/images/icons/uploads-big-icon.svg',
        );
      },
    );

    test('fromJson crea un producto correctamente', () {
      final json = {
        'code': 'test-1',
        'product_name': 'Test Product',
        'brands': 'Test Brand',
        'image_url': 'https://example.com/image.jpg',
        'ingredients_text': 'Ingrediente 1, Ingrediente 2',
        'allergens_tags': [
          'en:nuts',
          'en:soy',
        ], // Cambiado de 'allergens' a 'allergens_tags'
        'stores': 'Mercadona',
        'nutrition_grades': 'a',
        'categories': 'Snacks',
        'nutriments': {
          'energy-kcal_100g': 200,
          'fat_100g': 10,
          'carbohydrates_100g': 50,
          'proteins_100g': 5,
        },
        'labels': 'sin gluten, bio',
      };

      final product = Product.fromJson(json);

      expect(product.id, 'test-1');
      expect(product.name, 'Test Product');
      expect(product.brands, 'Test Brand');
      expect(product.imageUrl, 'https://example.com/image.jpg');
      expect(product.ingredients, 'Ingrediente 1, Ingrediente 2');
      expect(product.allergens, contains('nuts'));
      expect(product.allergens, contains('soy'));
      expect(product.stores, contains('Mercadona'));
      expect(product.nutritionGrade, isNull);
      expect(product.category, 'Snacks');
      expect(product.labels, contains('sin gluten'));
      expect(product.labels, contains('bio'));
    });

    test('fromJson maneja campos opcionales correctamente', () {
      final json = {
        'code': 'test-1', // Cambiado de 'id' a 'code'
        'product_name': 'Test Product',
        'allergens': '',
        'stores': '',
        'labels': '',
      };

      final product = Product.fromJson(json);

      expect(product.id, 'test-1');
      expect(product.name, 'Test Product');
      expect(product.brands, isNull);
      expect(product.imageUrl, isNull);
      expect(product.ingredients, isNull);
      expect(product.allergens, isEmpty);
      expect(product.stores, isEmpty);
      expect(product.nutritionGrade, isNull);
      expect(product.category, isNull);
      expect(product.labels, isEmpty);
    });
  });
}
