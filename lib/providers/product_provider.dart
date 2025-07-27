import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import 'repository_providers.dart'; // Importa el fichero central

// El FutureProvider que obtiene los productos y que será usado por la UI.
final productsProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, supermarketId) {
      // Usa el provider importado
      final repository = ref.watch(productsRepositoryProvider);

      return repository.getGlutenFreeProducts(supermarketId);
    });
