import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductsRepository {
  final http.Client _client;

  // Se puede pasar un cliente http para facilitar los tests
  ProductsRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Product>> getGlutenFreeProducts(String supermarketId) async {
    // URL de la API de Open Food Facts para buscar por tienda y etiqueta "sin gluten"
    final url = Uri.parse(
      'https://world.openfoodfacts.org/cgi/search.pl?action=process&tagtype_0=stores&tag_contains_0=contains&tag_0=$supermarketId&tagtype_1=labels&tag_contains_1=contains&tag_1=sin%20gluten&json=true&page_size=100',
    ); // Aumentado a 100 productos

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List productsJson = data['products'];

        // Filtramos para asegurar que el producto tiene un nombre antes de mostrarlo
        final validProducts = productsJson
            .map((json) => Product.fromJson(json))
            .where((product) => product.name != 'Nombre no disponible')
            .toList();

        return validProducts;
      } else {
        // Manejo de errores del servidor
        throw Exception(
          'Error al obtener los productos: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Manejo de errores de red o de otro tipo
      throw Exception('Error de conexión o al procesar los datos: $e');
    }
  }
}
