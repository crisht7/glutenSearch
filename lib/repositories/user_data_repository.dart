import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../models/user_registered.dart';

class UserDataRepository {
  final FirebaseFirestore _firestore;

  UserDataRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Obtiene la referencia a la colección de usuarios para no repetirla.
  CollectionReference<Map<String, dynamic>> _usersCollection() =>
      _firestore.collection('users');

  /// Guarda o actualiza el carrito activo del usuario en Firestore.
  Future<void> updateCart(String userId, Cart cart) async {
    await _usersCollection().doc(userId).set(
      {'activeCart': cart.toJson()},
      SetOptions(merge: true), // merge: true para no sobreescribir otros campos
    );
  }

  /// Añade un producto a la sub-colección de favoritos del usuario.
  Future<void> addFavoriteProduct(String userId, Product product) async {
    await _usersCollection()
        .doc(userId)
        .collection('favorites')
        .doc(product.id)
        .set(product.toJson());
  }

  /// Elimina un producto de la sub-colección de favoritos.
  Future<void> removeFavoriteProduct(String userId, String productId) async {
    await _usersCollection()
        .doc(userId)
        .collection('favorites')
        .doc(productId)
        .delete();
  }

  /// Obtiene el perfil completo de un usuario registrado desde Firestore.
  Future<RegisteredUser?> getRegisteredUserProfile(String userId) async {
    try {
      // Si no hay conexión o si la base de datos no existe,
      // creamos un perfil de usuario básico para no bloquear la app
      if (userId.isEmpty) {
        return null;
      }

      try {
        // 1. Obtener el documento principal del usuario
        final userDoc = await _usersCollection().doc(userId).get();
        if (!userDoc.exists || userDoc.data() == null) {
          // Si no existe el documento, crear uno básico
          return RegisteredUser(
            uid: userId,
            email: '', // No tenemos esta información sin Firestore
            name: '', // No tenemos esta información sin Firestore
            cart: Cart.empty(userId),
            favoriteProducts: [],
            savedCarts: [],
          );
        }

        final userData = userDoc.data()!;

        // 2. Obtener los productos favoritos de la sub-colección
        final favoritesSnapshot = await _usersCollection()
            .doc(userId)
            .collection('favorites')
            .get();
        final favoriteProducts = favoritesSnapshot.docs
            .map((doc) => Product.fromJson(doc.data()))
            .toList();

        // 3. Obtener los carritos guardados de la sub-colección
        final savedCartsSnapshot = await _usersCollection()
            .doc(userId)
            .collection('savedCarts')
            .get();
        final savedCarts = savedCartsSnapshot.docs
            .map((doc) => Cart.fromJson(doc.data()))
            .toList();

        // 4. Obtener el carrito activo (si existe)
        final activeCartData = userData['activeCart'];
        final activeCart = activeCartData != null
            ? Cart.fromJson(activeCartData)
            : Cart.empty(userId);

        // 5. Construir y devolver el objeto RegisteredUser completo
        return RegisteredUser(
          uid: userId,
          email:
              userData['email'] ??
              '', // Asumimos que el email se guarda al registrar
          name:
              userData['name'] ??
              '', // Asumimos que el nombre se guarda al registrar
          cart: activeCart,
          favoriteProducts: favoriteProducts,
          savedCarts: savedCarts,
        );
      } catch (e) {
        print('Error getting user profile: $e');
        // Si hay un error con Firestore, creamos un perfil básico
        return RegisteredUser(
          uid: userId,
          email: '',
          name: '',
          cart: Cart.empty(userId),
          favoriteProducts: [],
          savedCarts: [],
        );
      }
    } catch (e) {
      print('Error crítico en getRegisteredUserProfile: $e');
      return null;
    }
  }
}
