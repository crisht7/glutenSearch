import 'cart_item.dart';

class Cart {
  final String id;
  final List<CartItem> items;
  final DateTime lastModified;

  Cart({required this.id, required this.items, required this.lastModified});

  // Constructor para un carrito vacío
  factory Cart.empty(String id) {
    return Cart(id: id, items: [], lastModified: DateTime.now());
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'],
      items: (json['items'] as List)
          .map((itemJson) => CartItem.fromJson(itemJson))
          .toList(),
      lastModified: (json['lastModified']).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'lastModified': lastModified,
    };
  }
}
