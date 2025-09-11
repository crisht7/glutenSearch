import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    try {
      // Verificar que product exista y sea un Map
      if (json['product'] == null ||
          !(json['product'] is Map<String, dynamic>)) {
        throw Exception('El campo product es nulo o no es un Map');
      }

      final product = Product.fromJson(json['product'] as Map<String, dynamic>);
      final quantity = json['quantity'] is int ? json['quantity'] : 1;

      return CartItem(product: product, quantity: quantity);
    } catch (e) {
      print('Error al crear CartItem desde JSON: $e');
      // Crear un producto por defecto para evitar errores
      final defaultProduct = Product(
        id: 'error',
        name: 'Producto Error',
        allergens: [],
        stores: [],
        labels: [],
      );

      return CartItem(product: defaultProduct, quantity: 1);
    }
  }

  Map<String, dynamic> toJson() {
    return {'product': (product as dynamic).toJson(), 'quantity': quantity};
  }

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
