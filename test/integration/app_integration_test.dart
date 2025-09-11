import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:gluten_search/app.dart';
import 'package:gluten_search/models/cart.dart';
import 'package:gluten_search/models/product.dart';
import 'package:gluten_search/models/user_registered.dart';
import 'package:gluten_search/providers/repository_providers.dart';
import 'package:gluten_search/providers/auth_provider.dart';
import 'package:gluten_search/repositories/auth_repository.dart';
import 'package:gluten_search/repositories/products_repository.dart';
import 'package:gluten_search/repositories/user_data_repository.dart';
import '../helpers/firebase_test_helper.dart';

// Mock para repositorios
class MockAuthRepository extends AuthRepository {
  final MockFirebaseAuth mockAuth = MockFirebaseAuth();

  MockAuthRepository() : super(firebaseAuth: MockFirebaseAuth());

  @override
  Future<void> signInAnonymouslyIfNeeded() async {
    // No hacer nada en el test
  }
}

class MockProductsRepository extends ProductsRepository {
  @override
  Future<List<Product>> getGlutenFreeProducts(String supermarketId) async {
    // Devolver productos de prueba
    return [
      Product(
        id: 'test-1',
        name: 'Test Gluten-free Product',
        brands: 'Test Brand',
        imageUrl: 'https://example.com/image.jpg',
        allergens: ['none'],
        stores: ['Mercadona'],
        labels: ['sin gluten'],
      ),
      Product(
        id: 'test-2',
        name: 'Another Gluten-free Product',
        brands: 'Test Brand 2',
        imageUrl: 'https://example.com/image2.jpg',
        allergens: ['none'],
        stores: ['Mercadona'],
        labels: ['sin gluten', 'bio'],
      ),
    ];
  }
}

class MockUserDataRepository extends UserDataRepository {
  MockUserDataRepository() : super(firestore: null);

  @override
  Future<void> updateCart(String userId, Cart cart) async {
    // No hacer nada en el test
  }

  @override
  Future<void> addFavoriteProduct(String userId, Product product) async {
    // No hacer nada en el test
  }

  @override
  Future<void> removeFavoriteProduct(String userId, String productId) async {
    // No hacer nada en el test
  }

  @override
  Future<RegisteredUser?> getRegisteredUserProfile(String userId) async {
    return null;
  }
}

void main() {
  setUpAll(() async {
    // Inicializar Firebase antes de todas las pruebas
    await setupFirebaseForTesting();
  });

  testWidgets('App loads and navigates correctly', (WidgetTester tester) async {
    final mockAuthRepo = MockAuthRepository();

    // Configurar el widget y los mocks
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Sobrescribir los providers con nuestros mocks
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
          productsRepositoryProvider.overrideWithValue(
            MockProductsRepository(),
          ),
          userDataRepositoryProvider.overrideWithValue(
            MockUserDataRepository(),
          ),
        ],
        child: const GlutenSearchApp(),
      ),
    );

    // Esperar a que se complete la autenticación inicial
    await tester.pumpAndSettle();

    // Verificar que estamos en la pantalla de login
    expect(find.text('Iniciar Sesión'), findsOneWidget);

    // También probar que el botón de registro está presente
    expect(find.text('¿No tienes cuenta? Regístrate'), findsOneWidget);
  });

  testWidgets('Login form validation works correctly', (
    WidgetTester tester,
  ) async {
    final mockAuthRepo = MockAuthRepository();

    // Configurar el widget y los mocks
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Sobrescribir los providers con nuestros mocks
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
          productsRepositoryProvider.overrideWithValue(
            MockProductsRepository(),
          ),
          userDataRepositoryProvider.overrideWithValue(
            MockUserDataRepository(),
          ),
        ],
        child: const GlutenSearchApp(),
      ),
    );

    // Esperar a que se complete la autenticación inicial
    await tester.pumpAndSettle();

    // Intentar iniciar sesión sin introducir credenciales
    final loginButton = find.text('Iniciar Sesión').last;
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Verificar que se muestran mensajes de validación
    expect(find.text('Por favor, introduce un email válido'), findsOneWidget);
    expect(
      find.text('La contraseña debe tener al menos 6 caracteres'),
      findsOneWidget,
    );
  });

  testWidgets('App theme is correctly applied', (WidgetTester tester) async {
    final mockAuthRepo = MockAuthRepository();

    // Configurar el widget y los mocks
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Sobrescribir los providers con nuestros mocks
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
          productsRepositoryProvider.overrideWithValue(
            MockProductsRepository(),
          ),
          userDataRepositoryProvider.overrideWithValue(
            MockUserDataRepository(),
          ),
        ],
        child: const GlutenSearchApp(),
      ),
    );

    // Verificar que se usa el tema correcto
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme, isNotNull);
    expect(materialApp.darkTheme, isNotNull);
    expect(materialApp.themeMode, ThemeMode.system);
  });
}
