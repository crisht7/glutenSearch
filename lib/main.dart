import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Generado por FlutterFire CLI
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/repository_providers.dart';

Future<void> main() async {
  // PASO 1: Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // PASO 2: Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // PASO 3: Crear un contenedor de Riverpod para hacer pruebas en la consola
  // Esto nos permite interactuar con nuestros providers antes de que la UI exista.
  final container = ProviderContainer();

  // -- INICIO DE LA PRUEBA DE HUMO EN CONSOLA --

  print('--- INICIANDO PRUEBA DE LÓGICA ---');
  try {
    // Prueba de Autenticación Anónima
    final authRepo = container.read(authRepositoryProvider);
    await authRepo.signInAnonymouslyIfNeeded();
    final userId = authRepo.currentUser?.uid;
    print('✅ [AUTH] Sesión iniciada. UID: $userId');

    // Prueba de obtención de productos
    print('🔄 [API] Obteniendo productos de Mercadona...');
    final products = await container.read(productsProvider('mercadona').future);
    print('✅ [API] Se encontraron ${products.length} productos.');
    if (products.isNotEmpty) {
      print('    -> Primer producto: ${products.first.name}');
    }
  } catch (e) {
    print('❌ [ERROR] Ocurrió un error durante la prueba: $e');
  }
  print('--- FIN DE LA PRUEBA DE LÓGICA ---');

  // -- FIN DE LA PRUEBA --

  // PASO 4: Ejecutar la aplicación de Flutter
  // Envolvemos la app en el ProviderScope para que todos los widgets
  // puedan acceder a los providers.
  runApp(
    ProviderScope(
      parent:
          container, // Usamos el mismo container para no perder el estado inicial
      child: const MyApp(),
    ),
  );
}

// Una App mínima para tener una base sobre la que construir la UI
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos el estado de la autenticación para mostrar una UI u otra.
    // Este es el punto de partida para tu router.
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      title: 'Gluten Free App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          // .when() es perfecto para manejar los estados de un provider asíncrono
          child: authState.when(
            data: (user) {
              if (user != null) {
                return Text('Sesión iniciada como: ${user.uid}');
              } else {
                return const Text('No hay sesión iniciada.');
              }
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, stackTrace) => Text('Error: $error'),
          ),
        ),
      ),
    );
  }
}
