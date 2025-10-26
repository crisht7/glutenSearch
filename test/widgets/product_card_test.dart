import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:gluten_search/models/product.dart';
import 'package:gluten_search/widgets/product_card.dart';
import 'package:gluten_search/repositories/auth_repository.dart';
import 'package:gluten_search/providers/repository_providers.dart';

class MockAuthRepository extends AuthRepository {
  final bool isAnonymous;

  MockAuthRepository({required this.isAnonymous})
    : super(firebaseAuth: MockFirebaseAuth(signedIn: true));

  @override
  Stream<MockUser?> authStateChanges() {
    final user = MockUser(
      isAnonymous: isAnonymous,
      uid: 'test-user-id',
      email: isAnonymous ? null : 'test@example.com',
    );
    return Stream.value(user);
  }
}

void main() {
  testWidgets('ProductCard displays product information correctly', (
    WidgetTester tester,
  ) async {
    // Crear un producto de prueba
    final testProduct = Product(
      id: 'test-1',
      name: 'Test Product',
      brands: 'Test Brand',
      imageUrl: 'https://example.com/image.jpg',
      allergens: ['none'],
      stores: ['Test Store'],
      labels: ['sin gluten'],
    );

    // Envolver el widget en un ProviderScope para proporcionar los providers necesarios
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Proporcionar un repositorio de autenticación que simule un usuario anónimo
          authRepositoryProvider.overrideWithValue(
            MockAuthRepository(isAnonymous: true),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: ProductCard(product: testProduct)),
        ),
      ),
    );

    // Esperar a que todas las animaciones terminen
    await tester.pumpAndSettle();

    // Verificar que la información del producto se muestra correctamente
    expect(find.text('Test Product'), findsOneWidget);
    expect(find.text('Test Brand'), findsOneWidget);

    // Verificar que hay una imagen
    expect(find.byType(Image), findsOneWidget);

    // Verificar que se muestra la etiqueta "SIN GLUTEN"
    expect(find.text('SIN GLUTEN'), findsOneWidget);
  });

  testWidgets('ProductCard shows add to cart button for registered users', (
    WidgetTester tester,
  ) async {
    // Crear un producto de prueba
    final testProduct = Product(
      id: 'test-1',
      name: 'Test Product',
      brands: 'Test Brand',
      imageUrl: 'https://example.com/image.jpg',
      allergens: ['none'],
      stores: ['Test Store'],
      labels: ['sin gluten'],
    );

    // Envolver el widget en un ProviderScope simulando un usuario registrado
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Proporcionar un repositorio de autenticación que simule un usuario registrado
          authRepositoryProvider.overrideWithValue(
            MockAuthRepository(isAnonymous: false),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: ProductCard(product: testProduct)),
        ),
      ),
    );

    // Esperar a que todas las animaciones terminen
    await tester.pumpAndSettle();

    // Verificar que el botón de agregar al carrito está visible
    expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);
  });
}
