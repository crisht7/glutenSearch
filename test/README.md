# Tests para Gluten Search

Este directorio contiene los tests automatizados para validar el correcto funcionamiento de la aplicación Gluten Search.

## Estructura de los Tests

- **models/**: Tests unitarios para los modelos de datos.
  - `product_test.dart`: Prueba las funcionalidades del modelo `Product`.
  - `cart_test.dart`: Prueba los modelos `Cart` y `CartItem`.

- **providers/**: Tests para los providers de Riverpod.
  - `product_provider_test.dart`: Verifica el funcionamiento de los providers relacionados con productos.

- **repositories/**: Tests para los repositorios de datos.
  - `auth_repository_test.dart`: Prueba las funcionalidades de autenticación.
  - `products_repository_test.dart`: Prueba las operaciones con productos.

- **widgets/**: Tests para widgets individuales.
  - `product_card_test.dart`: Prueba el comportamiento del widget ProductCard.

- **integration/**: Tests de integración.
  - `app_integration_test.dart`: Prueba la interacción entre distintos componentes de la app.

- **widget_test.dart**: Test principal para comprobar la construcción y configuración base de la aplicación.

## Cómo ejecutar los tests

### Ejecutar todos los tests

```bash
flutter test
```

### Ejecutar un test específico

```bash
flutter test test/models/product_test.dart
```

### Ejecutar tests con cobertura

```bash
flutter test --coverage
```

Para visualizar el reporte de cobertura (requiere lcov):

```bash
genhtml coverage/lcov.info -o coverage/html
```

## Informe de Estado Actual

### Resumen

- **Tests Unitarios y de Widgets**: 22 tests pasando correctamente
- **Tests de Integración**: 3 tests pendientes (requieren configuración adicional de Firebase)

### Tests Pasando Correctamente

#### Models
1. **Product**
   - Deserialización desde JSON funciona correctamente
   - Serialización a JSON funciona correctamente
   - El método safeImageUrl devuelve la URL correcta

2. **Cart**
   - Creación de carrito vacío funciona correctamente
   - Añadir items al carrito funciona correctamente
   - Eliminar items del carrito funciona correctamente
   - Serialización y deserialización funcionan correctamente

#### Repositories
1. **AuthRepository**
   - Inicio de sesión anónimo funciona correctamente
   - Inicio de sesión con email y contraseña funciona correctamente
   - Registro con email y contraseña funciona correctamente

2. **ProductsRepository**
   - Obtención de productos sin gluten funciona correctamente
   - El manejo de supermercados inválidos funciona correctamente
   - El sistema de caché funciona correctamente para reducir peticiones

#### Widgets
1. **ProductCard**
   - Muestra correctamente la información del producto
   - Muestra correctamente la etiqueta "SIN GLUTEN"
   - Muestra el botón de agregar al carrito para usuarios registrados

### Tests Pendientes

#### Tests de Integración
Los tests de integración requieren inicialización de Firebase, que actualmente falla en el entorno de test:

1. **App loads and navigates correctly**
2. **Login form validation works correctly**
3. **App theme is correctly applied**

### Recomendaciones

1. **Tests de Integración**: Para resolver los problemas de Firebase, se podría:
   - Usar `fake_cloud_firestore` para simular Firestore
   - Configurar un proyecto Firebase de prueba específico para tests
   - Mejorar las abstracciones sobre los servicios de Firebase

2. **Cobertura**: Para aumentar la cobertura, se podrían añadir:
   - Tests para los providers (usando ProviderContainer)
   - Tests para más widgets de UI
   - Tests para las pantallas principales

Luego abrir `coverage/html/index.html` en el navegador.

## Dependencias para Testing

Este proyecto utiliza las siguientes dependencias para testing:

- `flutter_test`: Librería principal de testing para Flutter.
- `mockito`: Para crear mocks y stubs.
- `http_mock_adapter`: Para simular respuestas HTTP.
- `fake_cloud_firestore`: Para simular Firestore sin requerir conexión.
- `firebase_auth_mocks`: Para simular autenticación Firebase.
- `test`: Librería adicional para tests en Dart.

## Notas

- Los tests de UI pueden fallar si el tema o el diseño cambian. Actualízalos según evolucione la interfaz.
- Para los tests que involucran Firebase, se utilizan mocks en lugar de conectarse a servicios reales.
- Para ejecutar los tests de integración en un dispositivo real, usa `flutter test integration_test`.
