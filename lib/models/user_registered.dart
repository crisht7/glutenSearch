import 'user.dart';
import 'cart.dart';
import 'product.dart';

class RegisteredUser extends User {
  final String email;
  final String name; // Es obligatorio
  final List<Product> favoriteProducts;
  final List<Cart> savedCarts;

  RegisteredUser({
    required super.uid,
    required super.cart, // El carrito activo
    required this.email,
    required this.name,
    required this.favoriteProducts,
    required this.savedCarts,
  });
}
