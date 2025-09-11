import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';

// Clase para hacer override de la plataforma de Firebase
class TestFirebasePlatform extends FirebasePlatform {
  TestFirebasePlatform() : super();

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return TestFirebaseAppPlatform(
      name ?? 'test-app',
      options ??
          const FirebaseOptions(
            apiKey: 'test-api-key',
            appId: 'test-app-id',
            messagingSenderId: 'test-sender-id',
            projectId: 'test-project',
          ),
    );
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return TestFirebaseAppPlatform(
      name,
      const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'test-project',
      ),
    );
  }
}

// Implementación de la plataforma de la app de Firebase
class TestFirebaseAppPlatform extends FirebaseAppPlatform {
  TestFirebaseAppPlatform(super.name, super.options);
}

// Implementación simplificada para inicializar Firebase Mock en tests
typedef Callback = void Function(MethodCall call);

// Clases y métodos para simular Firebase en tests
class MockFirebaseApp implements FirebaseApp {
  @override
  String get name => 'test-app';

  @override
  FirebaseOptions get options => const FirebaseOptions(
    apiKey: 'test-api-key',
    appId: 'test-app-id',
    messagingSenderId: 'test-sender-id',
    projectId: 'test-project',
  );

  @override
  Future<void> delete() async {}

  @override
  bool get isAutomaticDataCollectionEnabled => false;

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {}
}

// Setup para inicializar Firebase en tests
Future<void> setupFirebaseForTesting() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Crear un mock para el MethodChannel
  setupFirebaseMethodChannel('plugins.flutter.io/firebase_core');
  setupFirebaseAuthMethodChannel();
  setupFirestoreMethodChannel();

  // Reemplazar la implementación de Firebase Platform con nuestra propia versión de test
  FirebasePlatform.instance = TestFirebasePlatform();

  // Ahora aseguramos que Firebase.initializeApp() funcione
  await Firebase.initializeApp(
    name: 'test-app',
    options: const FirebaseOptions(
      apiKey: 'test-api-key',
      appId: 'test-app-id',
      messagingSenderId: 'test-sender-id',
      projectId: 'test-project',
    ),
  );
}

// Mock para el canal de métodos de Firebase Core
void setupFirebaseMethodChannel(String channelName) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(MethodChannel(channelName), (call) async {
        if (call.method == 'Firebase#initializeApp') {
          return {
            'name': 'test-app',
            'options': {
              'apiKey': 'test-api-key',
              'appId': 'test-app-id',
              'messagingSenderId': 'test-sender-id',
              'projectId': 'test-project',
            },
          };
        }

        return null;
      });
}

// Mock para Firebase Auth
void setupFirebaseAuthMethodChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        MethodChannel('plugins.flutter.io/firebase_auth'),
        (call) async {
          if (call.method == 'currentUser') {
            return null; // Simular sin usuario actual
          }
          if (call.method == 'signInAnonymously') {
            return {
              'user': {'uid': 'test-anonymous-user', 'isAnonymous': true},
            };
          }
          return null;
        },
      );
}

// Mock para Firestore
void setupFirestoreMethodChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        MethodChannel('plugins.flutter.io/firebase_firestore'),
        (call) async {
          // Simplemente devolver resultados vacíos para cualquier llamada
          if (call.method.contains('get')) {
            return {'documents': []};
          }
          return null;
        },
      );
}
