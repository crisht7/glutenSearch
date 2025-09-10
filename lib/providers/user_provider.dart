import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../models/user_registered.dart';
import 'repository_providers.dart'; // Importa el fichero central
import 'auth_provider.dart';

// El AsyncNotifier que gestiona el estado asíncrono del perfil del usuario.
class UserProfileNotifier extends AsyncNotifier<RegisteredUser?> {
  @override
  FutureOr<RegisteredUser?> build() {
    final authState = ref.watch(authStateChangesProvider);
    final userId = authState.value?.uid;

    if (userId == null) {
      return null;
    }

    // Si el usuario es anónimo, creamos un usuario anónimo en lugar de intentar obtenerlo de Firestore
    if (authState.value!.isAnonymous) {
      return RegisteredUser(
        uid: userId,
        email: '',
        name: 'Usuario Invitado',
        cart: Cart.empty(userId),
        favoriteProducts: [],
        savedCarts: [],
      );
    }

    // Para usuarios registrados, intentamos obtener su perfil de Firestore
    try {
      final userDataRepository = ref.watch(userDataRepositoryProvider);
      return userDataRepository.getRegisteredUserProfile(userId);
    } catch (e) {
      // Si hay algún error con Firestore, creamos un perfil básico
      print('Error al obtener perfil de usuario: $e');
      return RegisteredUser(
        uid: userId,
        email: authState.value?.email ?? '',
        name: '',
        cart: Cart.empty(userId),
        favoriteProducts: [],
        savedCarts: [],
      );
    }
  }

  Future<void> addFavorite(Product product) async {
    final userId = ref.read(authStateChangesProvider).value?.uid;
    if (userId == null) return;

    final repository = ref.read(userDataRepositoryProvider);

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await repository.addFavoriteProduct(userId, product);
      // Vuelve a obtener el perfil para que la UI se actualice con los nuevos datos.
      return repository.getRegisteredUserProfile(userId);
    });
  }

  // Aquí podrías añadir otros métodos como removeFavorite, saveCart, etc.
}

// El provider final que la UI observará.
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, RegisteredUser?>(() {
      return UserProfileNotifier();
    });
