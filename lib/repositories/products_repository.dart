import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../models/product.dart';

// Config común para llamadas OFF
const _requestTimeout = Duration(seconds: 15);
const _offHost = 'world.openfoodfacts.org';
const _offHeaders = {
  'User-Agent': 'GlutenSearch/1.0 (gluten.search.app@gmail.com)',
  'Accept': 'application/json',
};

class ProductsRepository {
  final http.Client _client;

  // Cache simple para evitar peticiones repetidas
  final Map<String, List<Product>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 30);

  ProductsRepository({http.Client? client}) : _client = client ?? http.Client();

  // Utilidad: GET con timeout y log
  Future<String> _safeGet(Uri uri, http.Client client) async {
    debugPrint('[OFF][GET] $uri');
    final res = await client
        .get(uri, headers: _offHeaders)
        .timeout(_requestTimeout);
    debugPrint('[OFF][${res.statusCode}] $uri');
    if (res.statusCode != 200) {
      throw HttpException('OpenFoodFacts ${res.statusCode}');
    }
    return res.body;
  }

  Future<List<Product>> getGlutenFreeProducts(String supermarketId) async {
    // Verificar cache
    if (_isCacheValid(supermarketId)) {
      return _cache[supermarketId]!;
    }

    try {
      // Obtener productos desde la API
      final products = await _fetchProductsFromAPI(supermarketId);

      // Guardar en cache
      _cache[supermarketId] = products;
      _cacheTimestamps[supermarketId] = DateTime.now();

      return products;
    } catch (e) {
      // Si hay error y tenemos cache (aunque esté expirado), devolverlo
      if (_cache.containsKey(supermarketId)) {
        return _cache[supermarketId]!;
      }
      rethrow;
    }
  }

  Future<List<Product>> _fetchProductsFromAPI(String supermarketId) async {
    final allProducts = <Product>[];

    // Realizar búsquedas múltiples con diferentes términos para obtener más resultados
    final searchTerms = _getSearchTermsForSupermarket(supermarketId);

    for (final searchTerm in searchTerms) {
      try {
        final products = await _searchProductsByTerm(
          searchTerm,
          store: supermarketId,
        );
        allProducts.addAll(products);

        // Añadir un pequeño delay entre peticiones para no sobrecargar la API
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        print('Error searching for term "$searchTerm": $e');
        // Continuar con el siguiente término
      }
    }

    // Eliminar duplicados basados en el código del producto
    final uniqueProducts = <String, Product>{};
    for (final product in allProducts) {
      if (!uniqueProducts.containsKey(product.id)) {
        uniqueProducts[product.id] = product;
      }
    }

    // Filtrar y validar productos
    final validProducts = uniqueProducts.values.where(_isValidProduct).toList();

    // Ordenar por relevancia (productos con más información primero)
    validProducts.sort(_compareProductRelevance);

    return validProducts.take(100).toList(); // Limitar a 100 productos
  }

  // Reemplaza el GET directo por _safeGet dentro de la búsqueda por término
  Future<List<Product>> _searchProductsByTerm(
    String term, {
    String? store,
  }) async {
    final params = <String, String>{
      'action': 'process',
      'json': '1',
      'search_simple': '1',
      'page_size': '20',
      'sort_by': 'popularity',
      'search_terms': term,
    };

    int tagIndex = 0;
    params.addAll({
      'tagtype_$tagIndex': 'labels',
      'tag_contains_$tagIndex': 'contains',
      'tag_$tagIndex': 'gluten-free',
    });
    if (store != null && store.isNotEmpty) {
      tagIndex++;
      params.addAll({
        'tagtype_$tagIndex': 'stores',
        'tag_contains_$tagIndex': 'contains',
        'tag_$tagIndex': store,
      });
    }

    final uri = Uri.https(_offHost, '/cgi/search.pl', params);

    try {
      final body = await _safeGet(uri, _client);
      final jsonMap = json.decode(body) as Map<String, dynamic>;
      return (jsonMap['products'] as List<dynamic>)
          .map((productJson) => Product.fromJson(productJson))
          .where(_isValidProduct)
          .where(_isGlutenFree)
          .toList();
    } on TimeoutException {
      debugPrint('[OFF][TIMEOUT] $uri');
      return <Product>[]; // No bloquea toda la búsqueda
    } on SocketException catch (e) {
      debugPrint('[OFF][SOCKET] $e $uri');
      rethrow;
    }
  }

  List<String> _getSearchTermsForSupermarket(String supermarketId) {
    // Términos de búsqueda específicos para productos sin gluten
    const baseTerms = [
      'sin gluten',
      'gluten free',
      'celiacos',
      'pan sin gluten',
      'pasta sin gluten',
      'galletas sin gluten',
      'harina sin gluten',
      'cereales sin gluten',
    ];

    // Términos adicionales específicos por supermercado
    final Map<String, List<String>> specificTerms = {
      'mercadona': ['hacendado sin gluten', 'mercadona'],
      'carrefour': ['carrefour sin gluten', 'carrefour'],
      'eroski': ['eroski sin gluten', 'eroski'],
    };

    final terms = List<String>.from(baseTerms);
    if (specificTerms.containsKey(supermarketId)) {
      terms.addAll(specificTerms[supermarketId]!);
    }

    return terms;
  }

  String _normalizeStoreTag(String supermarketId) {
    // Mapear IDs de supermercado a tags de Open Food Facts
    const storeMapping = {
      'mercadona': 'mercadona',
      'carrefour': 'carrefour',
      'eroski': 'eroski',
    };

    return storeMapping[supermarketId] ?? supermarketId;
  }

  bool _isValidProduct(Product product) {
    // Validar que el producto tenga información mínima necesaria
    return product.name.isNotEmpty &&
        product.name != 'Nombre no disponible' &&
    !product.name.startsWith('Error al cargar producto') &&
        product.id.isNotEmpty &&
        product.name.length > 2 &&
        !product.name.toLowerCase().contains('test') &&
        !product.name.toLowerCase().contains('ejemplo');
  }

  bool _isGlutenFree(Product product) {
    // Verificar múltiples indicadores de que es sin gluten
    final name = product.name.toLowerCase();
    final ingredients = product.ingredients?.toLowerCase() ?? '';
    final allergens = product.allergens.join(' ').toLowerCase();

    // Indicadores positivos
    final glutenFreeIndicators = [
      'sin gluten',
      'gluten free',
      'gluten-free',
      'celiac',
      'celiaco',
      'apto celiacos',
      'libre de gluten',
    ];

    // Indicadores negativos (contiene gluten)
    final glutenIndicators = [
      'contiene gluten',
      'contains gluten',
      'wheat',
      'trigo',
      'cebada',
      'centeno',
      'avena', // A menos que específicamente diga "avena sin gluten"
    ];

    // Verificar indicadores positivos
    final hasPositiveIndicator = glutenFreeIndicators.any(
      (indicator) =>
          name.contains(indicator) ||
          ingredients.contains(indicator) ||
          allergens.contains(indicator),
    );

    // Verificar que no tenga indicadores negativos
    final hasNegativeIndicator = glutenIndicators.any(
      (indicator) =>
          name.contains(indicator) ||
          ingredients.contains(indicator) ||
          allergens.contains(indicator),
    );

    // Si tiene indicador positivo y no tiene negativo, es válido
    if (hasPositiveIndicator && !hasNegativeIndicator) {
      return true;
    }

    // Si no tiene gluten en la lista de alérgenos, también puede ser válido
    final hasGlutenAllergen =
        allergens.contains('gluten') ||
        allergens.contains('wheat') ||
        allergens.contains('trigo');

    return !hasGlutenAllergen && hasPositiveIndicator;
  }

  int _compareProductRelevance(Product a, Product b) {
    // Criterios de relevancia (mayor número = más relevante)
    int scoreA = _calculateRelevanceScore(a);
    int scoreB = _calculateRelevanceScore(b);

    return scoreB.compareTo(scoreA); // Orden descendente
  }

  int _calculateRelevanceScore(Product product) {
    int score = 0;

    // Bonificación por tener imagen
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      score += 10;
    }

    // Bonificación por tener marca
    if (product.brands != null && product.brands!.isNotEmpty) {
      score += 5;
    }

    // Bonificación por tener ingredientes
    if (product.ingredients != null && product.ingredients!.isNotEmpty) {
      score += 8;
    }

    // Bonificación por nombre descriptivo
    if (product.name.length > 20) {
      score += 3;
    }

    // Bonificación por tener información de tiendas
    score += product.stores.length * 2;

    // Penalización por nombres muy genéricos
    final name = product.name.toLowerCase();
    if (name.length < 10 ||
        name.contains('producto') ||
        name.contains('artículo')) {
      score -= 5;
    }

    return score;
  }

  bool _isCacheValid(String supermarketId) {
    if (!_cache.containsKey(supermarketId) ||
        !_cacheTimestamps.containsKey(supermarketId)) {
      return false;
    }

    final cacheTime = _cacheTimestamps[supermarketId]!;
    final now = DateTime.now();

    return now.difference(cacheTime) < _cacheExpiration;
  }

  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // Método para buscar productos específicos por nombre
  Future<List<Product>> searchProductsByName(
    String query, {
    String? supermarketId,
  }) async {
    try {
      final params = <String, String>{
        'search_terms': '$query sin gluten',
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '20',
        'sort_by': 'popularity',
        'tagtype_0': 'labels',
        'tag_contains_0': 'contains',
        'tag_0': 'gluten-free',
        'countries': 'spain',
      };
      if (supermarketId != null) {
        params.addAll({
          'tagtype_1': 'stores',
          'tag_contains_1': 'contains',
          'tag_1': _normalizeStoreTag(supermarketId),
        });
      }

      final url = Uri.https(_offHost, '/cgi/search.pl', params);
      final body = await _safeGet(url, _client);
      final data = json.decode(body);

      if (data['products'] != null) {
        final List productsJson = data['products'];
        return productsJson
            .map((json) => Product.fromJson(json))
            .where(_isValidProduct)
            .where(_isGlutenFree)
            .take(20)
            .toList();
      }

      return <Product>[];
    } catch (e) {
      print('Error searching products by name: $e');
      return [];
    }
  }
}
