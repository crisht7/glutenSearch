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
    try {
      await _usersCollection().doc(userId).set(
        {'activeCart': cart.toJson()},
        SetOptions(
          merge: true,
        ), // merge: true para no sobreescribir otros campos
      );
    } catch (e) {
      // Manejar errores de Firestore sin interrumpir el flujo
      print('Error al actualizar el carrito: $e');
      // No lanzamos excepción para permitir que la app funcione sin Firestore
    }
  }

  /// Añade un producto a la sub-colección de favoritos del usuario.
  Future<void> addFavoriteProduct(String userId, Product product) async {
    try {
      await _usersCollection()
          .doc(userId)
          .collection('favorites')
          .doc(product.id)
          .set(product.toJson());
    } catch (e) {
      // Manejar errores de Firestore sin interrumpir el flujo
      print('Error al añadir producto a favoritos: $e');
      // No lanzamos excepción para permitir que la app funcione sin Firestore
    }
  }

  /// Elimina un producto de la sub-colección de favoritos.
  Future<void> removeFavoriteProduct(String userId, String productId) async {
    try {
      await _usersCollection()
          .doc(userId)
          .collection('favorites')
          .doc(productId)
          .delete();
    } catch (e) {
      // Manejar errores de Firestore sin interrumpir el flujo
      print('Error al eliminar producto de favoritos: $e');
      // No lanzamos excepción para permitir que la app funcione sin Firestore
    }
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

        final userData = userDoc.data() ?? {};

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
        Cart activeCart;

        try {
          activeCart = activeCartData != null
              ? Cart.fromJson(activeCartData as Map<String, dynamic>)
              : Cart.empty(userId);
        } catch (e) {
          print('Error al procesar el carrito activo: $e');
          activeCart = Cart.empty(userId);
        }

        // 5. Construir y devolver el objeto RegisteredUser completo
        return RegisteredUser(
          uid: userId,
          email:
              userData['email']?.toString() ??
              '', // Asegurar conversión a String
          name:
              userData['name']?.toString() ??
              '', // Asegurar conversión a String
          cart: activeCart,
          favoriteProducts: favoriteProducts,
          savedCarts: savedCarts,
        );
      } catch (e) {
        // Verificar específicamente si es un error de "database does not exist"
        if (e.toString().contains('does not exist for project') ||
            e.toString().contains('NOT_FOUND')) {
          print('Error: La base de datos de Firestore no está configurada: $e');
          // Crear un perfil básico para que la app siga funcionando sin Firestore
        } else {
          print('Error getting user profile: $e');
        }

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

  /// Actualiza o crea el perfil de un usuario en Firestore.
  /// Se usa después del registro para guardar información adicional como el nombre.
  Future<void> updateUserProfile({
    required String userId,
    required String email,
    required String name,
  }) async {
    try {
      // Crear una estructura de datos segura para el carrito
      final Map<String, dynamic> cartData = {
        'userId': userId,
        'items': <Map<String, dynamic>>[],
        'lastModified': DateTime.now()
            .toIso8601String(), // Formato ISO para fechas
      };

      // Preparamos los datos en un formato seguro
      final Map<String, dynamic> userData = {
        'email': email,
        'name': name,
        // Inicializa el carrito vacío si no existe, con estructura correcta
        'activeCart': cartData,
      };

      // Uso de try-catch específico para operaciones de Firestore
      try {
        await _usersCollection()
            .doc(userId)
            .set(
              userData,
              SetOptions(merge: true),
            ); // merge: true para no sobreescribir otros campos
      } catch (firestoreError) {
        // Verificar específicamente si es un error de "database does not exist"
        if (firestoreError.toString().contains('does not exist for project') ||
            firestoreError.toString().contains('NOT_FOUND')) {
          print(
            'Error: La base de datos de Firestore no está configurada: $firestoreError',
          );
          // No lanzamos excepción para que la app siga funcionando sin Firestore
          return;
        }

        print('Error específico de Firestore: $firestoreError');
        // No lanzamos excepción para permitir que el usuario use la aplicación
        // incluso si hay problemas con Firestore
      }
    } catch (e) {
      // Capturar y manejar específicamente errores de tipo
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('not a subtype')) {
        print('Error de tipo detectado durante actualización de perfil: $e');
        // No lanzamos excepción para no bloquear el registro
      } else {
        print('Error general al actualizar perfil: $e');
        // No lanzamos excepción para permitir que la aplicación siga funcionando
      }
    }
  }
}
