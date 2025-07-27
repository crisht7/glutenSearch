import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../repositories/user_data_repository.dart';
import 'repository_providers.dart'; // Importa el fichero central
import 'auth_provider.dart';

// El StateNotifier que gestiona la lógica de estado del carrito.
class CartNotifier extends StateNotifier<Cart> {
  final UserDataRepository _userDataRepository;
  final String _userId;

  CartNotifier(this._userDataRepository, this._userId)
    : super(Cart.empty(_userId)) {
    // Aquí podrías llamar a un método para cargar el carrito inicial desde Firestore
    // _loadInitialCart();
  }

  void addItem(Product product) {
    final itemIndex = state.items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (itemIndex >= 0) {
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[itemIndex].quantity++;
      state = Cart(
        id: state.id,
        items: updatedItems,
        lastModified: DateTime.now(),
      );
    } else {
      final newItems = [
        ...state.items,
        CartItem(product: product, quantity: 1),
      ];
      state = Cart(id: state.id, items: newItems, lastModified: DateTime.now());
    }

    _userDataRepository.updateCart(_userId, state);
  }

  void removeItem(String productId) {
    final updatedItems = state.items
        .where((item) => item.product.id != productId)
        .toList();
    state = Cart(
      id: state.id,
      items: updatedItems,
      lastModified: DateTime.now(),
    );
    _userDataRepository.updateCart(_userId, state);
  }

  void clearCart() {
    state = Cart.empty(_userId);
    _userDataRepository.updateCart(_userId, state);
  }
}

// El provider final que la UI observará.
final cartNotifierProvider =
    StateNotifierProvider.autoDispose<CartNotifier, Cart>((ref) {
      final authState = ref.watch(authStateChangesProvider);
      final userId = authState.value?.uid;

      if (userId == null) {
        // Esta excepción es importante para asegurar que nunca intentemos
        // manejar un carrito sin un usuario autenticado (incluso anónimo).
        throw Exception("User is not authenticated, cannot manage cart.");
      }

      // Usa el provider de repositorio importado
      return CartNotifier(ref.watch(userDataRepositoryProvider), userId);
    });
