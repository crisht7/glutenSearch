// lib/providers/auth_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart'; // Importa el fichero central

// El StreamProvider que expone el estado de autenticación en tiempo real.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  // Usa el provider importado
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});
