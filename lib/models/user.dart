import 'cart.dart';

abstract class User {
  final String uid;
  final Cart cart;

  User({required this.uid, required this.cart});
}
