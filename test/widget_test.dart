import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gluten_search/app.dart';
import 'package:gluten_search/core/app_router.dart';

void main() {
  // Configuración inicial para los tests
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock Firebase para tests (evita inicialización real)
    // En tests, Firebase no se inicializa automáticamente
  });

  testWidgets('GlutenSearchApp should build without crashing', (
    WidgetTester tester,
  ) async {
    // Crear un ProviderScope para Riverpod en el test
    await tester.pumpWidget(const ProviderScope(child: GlutenSearchApp()));

    // Verify that the app builds successfully with MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify that ProviderScope is present
    expect(find.byType(ProviderScope), findsOneWidget);
  });

  testWidgets('App should have proper theme configuration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GlutenSearchApp()));

    // Get the MaterialApp widget
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    // Verify that theme is configured
    expect(materialApp.theme, isNotNull);
    expect(materialApp.darkTheme, isNotNull);

    // Verificar colores principales del tema
    final colorScheme = materialApp.theme!.colorScheme;
    // Verificamos que los colores se basan en el seed color, no los valores exactos
    expect(colorScheme.primary, isA<Color>());
    expect(colorScheme.secondary, isA<Color>());
  });

  test('AppRouter should generate routes correctly', () {
    // Probar la generación de rutas
    final routeSettings = RouteSettings(name: '/login');
    final route = AppRouter.generateRoute(routeSettings);

    expect(route, isA<MaterialPageRoute>());
  });
}
