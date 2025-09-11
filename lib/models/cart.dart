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
    try {
      // Manejar el caso cuando los datos no son del tipo esperado
      String id = json['id']?.toString() ?? '';
      List<CartItem> itemsList = [];

      // Verificar si 'items' existe y es una lista
      if (json['items'] != null && json['items'] is List) {
        final items = json['items'] as List;
        itemsList = items
            .where(
              (itemJson) =>
                  itemJson is Map<String, dynamic> &&
                  itemJson['product'] is Map<String, dynamic>,
            )
            .map(
              (itemJson) => CartItem.fromJson(itemJson as Map<String, dynamic>),
            )
            .toList();
      }

      // Manejar el campo lastModified
      DateTime lastMod;
      try {
        if (json['lastModified'] != null) {
          // Si es un Timestamp de Firestore
          if (json['lastModified'].runtimeType.toString().contains(
            'Timestamp',
          )) {
            lastMod = json['lastModified'].toDate();
          } else {
            // Si es un string o un número
            lastMod =
                DateTime.tryParse(json['lastModified'].toString()) ??
                DateTime.now();
          }
        } else {
          lastMod = DateTime.now();
        }
      } catch (e) {
        print('Error al procesar lastModified: $e');
        lastMod = DateTime.now();
      }

      return Cart(id: id, items: itemsList, lastModified: lastMod);
    } catch (e) {
      print('Error al crear Cart desde JSON: $e');
      return Cart.empty('error');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'lastModified': lastModified,
    };
  }
}
