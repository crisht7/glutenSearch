import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:gluten_search/app.dart';

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
  });
}
