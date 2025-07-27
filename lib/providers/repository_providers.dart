import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../repositories/products_repository.dart';
import '../repositories/user_data_repository.dart';

// Provider para el AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Provider para el ProductsRepository
final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository();
});

// Provider para el UserDataRepository
final userDataRepositoryProvider = Provider<UserDataRepository>((ref) {
  return UserDataRepository();
});
