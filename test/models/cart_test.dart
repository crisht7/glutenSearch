import 'package:flutter_test/flutter_test.dart';
import 'package:gluten_search/models/cart.dart';
import 'package:gluten_search/models/cart_item.dart';
import 'package:gluten_search/models/product.dart';

// Mock para simular el Timestamp de Firestore
class FakeTimestamp {
  final DateTime _dateTime;

  FakeTimestamp(this._dateTime);

  DateTime toDate() => _dateTime;
}

void main() {
  group('Cart', () {
    test('Cart.empty crea un carrito vacío con el id correcto', () {
      final cart = Cart.empty('user-123');

      expect(cart.id, 'user-123');
      expect(cart.items, isEmpty);
      expect(cart.lastModified, isA<DateTime>());
    });

    test('fromJson crea un carrito correctamente', () {
      final now = DateTime.now();
      final fakeTimestamp = FakeTimestamp(now);

      final productJson = {
        'code': 'product-1', // Cambiado de 'id' a 'code'
        'product_name': 'Test Product',
        'allergens_tags': ['none'], // Cambiado para usar el formato correcto
        'stores': 'Mercadona',
        'labels': 'sin gluten',
      };

      final cartItemJson = {'product': productJson, 'quantity': 2};

      final cartJson = {
        'id': 'cart-123',
        'items': [cartItemJson],
        'lastModified': fakeTimestamp,
      };

      final cart = Cart.fromJson(cartJson);

      expect(cart.id, 'cart-123');
      expect(cart.items.length, 1);
      expect(cart.items[0].product.id, 'product-1');
      expect(cart.items[0].quantity, 2);
      expect(cart.lastModified, now);
    });

    test('toJson serializa correctamente el carrito', () {
      final product = Product(
        id: 'product-1',
        name: 'Test Product',
        allergens: [],
        stores: ['Mercadona'],
        labels: ['sin gluten'],
      );

      final cartItem = CartItem(product: product, quantity: 3);
      final now = DateTime.now();
      final cart = Cart(id: 'cart-123', items: [cartItem], lastModified: now);

      final json = cart.toJson();

      expect(json['id'], 'cart-123');
      expect(json['items'], isA<List>());
      expect(json['items'].length, 1);
      expect(json['lastModified'], now);
    });
  });

  group('CartItem', () {
    test('copyWith crea una copia con valores actualizados', () {
      final product = Product(
        id: 'product-1',
        name: 'Test Product',
        allergens: [],
        stores: [],
        labels: [],
      );

      final cartItem = CartItem(product: product, quantity: 1);

      final updatedCartItem = cartItem.copyWith(quantity: 5);

      expect(updatedCartItem.product, same(product));
      expect(updatedCartItem.quantity, 5);
    });

    test('toJson serializa correctamente el CartItem', () {
      final product = Product(
        id: 'product-1',
        name: 'Test Product',
        allergens: [],
        stores: [],
        labels: [],
      );

      final cartItem = CartItem(product: product, quantity: 2);

      final json = cartItem.toJson();

      expect(json['quantity'], 2);
      expect(json['product'], isA<Map<String, dynamic>>());
    });
  });
}
