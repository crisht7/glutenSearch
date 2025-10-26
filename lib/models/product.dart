// Agregar import para Color
import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String? brands;
  final String? imageUrl;
  final String? ingredients;
  final List<String> allergens;
  final List<String> stores;
  final String? nutritionGrade; // Nuevo campo para Nutri-Score
  final String? category; // Categoría del producto
  final Map<String, dynamic>? nutriments; // Información nutricional
  final List<String> labels; // Etiquetas como "sin gluten", "bio", etc.
  final double? rating; // Puntuación del producto si está disponible

  Product({
    required this.id,
    required this.name,
    this.brands,
    this.imageUrl,
    this.ingredients,
    required this.allergens,
    required this.stores,
    this.nutritionGrade,
    this.category,
    this.nutriments,
    required this.labels,
    this.rating,
  });

  /// Getter para manejar un posible imageUrl nulo de forma segura en la UI.
  String get safeImageUrl {
    if (imageUrl != null &&
        imageUrl!.isNotEmpty &&
        !imageUrl!.contains('placeholder')) {
      return imageUrl!;
    }
    return 'https://images.openfoodfacts.org/images/icons/uploads-big-icon.svg';
  }

  /// Getter para mostrar una marca segura en la UI.
  String get safeBrands {
    if (brands != null && brands!.isNotEmpty) {
      // Limpiar la marca de caracteres extraños y limitar longitud
      final cleanBrand = brands!.replaceAll(RegExp(r'[^\w\s\-]'), '').trim();

      if (cleanBrand.isNotEmpty) {
        return cleanBrand.length > 30
            ? '${cleanBrand.substring(0, 30)}...'
            : cleanBrand;
      }
    }
    return 'Marca no disponible';
  }

  /// Getter para obtener el nombre limpio del producto
  String get cleanName {
    if (name.isEmpty) return 'Producto sin nombre';

    // Limpiar el nombre de caracteres extraños y normalizar
    return name
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s\-àáèéìíòóùúüñç]', caseSensitive: false), '')
        .trim();
  }

  /// Verificar si el producto es realmente sin gluten
  bool get isGlutenFree {
    final searchText =
        '${name.toLowerCase()} ${(ingredients ?? '').toLowerCase()} ${labels.join(' ').toLowerCase()}';

    // Indicadores positivos
    final positiveIndicators = [
      'sin gluten',
      'gluten free',
      'gluten-free',
      'sans gluten',
      'senza glutine',
      'glutenfrei',
      'celiaco',
      'celiac',
      'apto celiacos',
    ];

    // Indicadores negativos
    final negativeIndicators = [
      'contiene gluten',
      'contains gluten',
      'con gluten',
      'wheat',
      'trigo',
    ];

    final hasPositive = positiveIndicators.any(searchText.contains);
    final hasNegative = negativeIndicators.any(searchText.contains);

    return hasPositive && !hasNegative;
  }

  /// Obtener categoría limpia
  String get safeCategory {
    if (category != null && category!.isNotEmpty) {
      return category!
          .split(':')
          .last
          .replaceAll('-', ' ')
          .replaceAll('_', ' ')
          .trim();
    }
    return 'Sin categoría';
  }

  /// Obtener el Nutri-Score como color
  Color? get nutritionGradeColor {
    switch (nutritionGrade?.toLowerCase()) {
      case 'a':
        return const Color(0xFF4CAF50); // Verde
      case 'b':
        return const Color(0xFF8BC34A); // Verde claro
      case 'c':
        return const Color(0xFFFFEB3B); // Amarillo
      case 'd':
        return const Color(0xFFFF9800); // Naranja
      case 'e':
        return const Color(0xFFF44336); // Rojo
      default:
        return null;
    }
  }

  /// Factory mejorado para crear un Producto desde el JSON de Open Food Facts
  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      // Primero asegurar que los datos de JSON son válidos
      Map<String, dynamic> safeJson = Map<String, dynamic>.from(json);

      // Manejar 'nutriments' con cuidado - podría no ser un Map
      Map<String, dynamic>? nutriments;
      if (json['nutriments'] != null) {
        if (json['nutriments'] is Map) {
          // Intenta convertir a Map<String, dynamic>
          try {
            nutriments = Map<String, dynamic>.from(json['nutriments'] as Map);
          } catch (e) {
            print('Error convirtiendo nutriments: $e');
            nutriments = null;
          }
        }
      }

      return Product(
        id: _extractId(safeJson),
        name: _extractName(safeJson),
        brands: _extractBrands(safeJson),
        imageUrl: _extractImageUrl(safeJson),
        ingredients: _extractIngredients(safeJson),
        allergens: _extractAllergens(safeJson),
        stores: _extractStores(safeJson),
        nutritionGrade: json['nutrition_grade_fr']?.toString(),
        category: _extractCategory(safeJson),
        nutriments: nutriments,
        labels: _extractLabels(safeJson),
        rating: _extractRating(safeJson),
      );
    } catch (e) {
      print('Error en Product.fromJson: $e');
      // Devolver un producto con datos mínimos en caso de error
      return Product(
        id: 'error-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Error al cargar producto',
        allergens: [],
        stores: [],
        labels: [],
      );
    }
  }

  static String _extractId(Map<String, dynamic> json) {
    final code = json['code'] ?? json['_id'] ?? '';
    if (code.toString().isNotEmpty) {
      return code.toString();
    }
    return 'unknown-${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _extractName(Map<String, dynamic> json) {
    // Priorizar nombre en español, luego otros idiomas
    final name =
        json['product_name_es'] ??
        json['product_name'] ??
        json['generic_name_es'] ??
        json['generic_name'] ??
        '';

    if (name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }
    return 'Producto sin nombre';
  }

  static String? _extractBrands(Map<String, dynamic> json) {
    final brands = json['brands'];
    if (brands != null && brands.toString().trim().isNotEmpty) {
      // Tomar solo la primera marca si hay múltiples
      final brandsList = brands.toString().split(',');
      return brandsList.first.trim();
    }
    return null;
  }

  static String? _extractImageUrl(Map<String, dynamic> json) {
    // Priorizar imagen frontal, luego cualquier imagen disponible
    final frontUrl =
        json['image_front_url'] ??
        json['image_url'] ??
        json['image_front_small_url'];

    if (frontUrl != null && frontUrl.toString().isNotEmpty) {
      final url = frontUrl.toString();
      // Verificar que la URL sea válida
      if (url.startsWith('http') && !url.contains('placeholder')) {
        return url;
      }
    }
    return null;
  }

  static String? _extractIngredients(Map<String, dynamic> json) {
    // Priorizar ingredientes en español
    final ingredients =
        json['ingredients_text_es'] ?? json['ingredients_text'] ?? '';

    if (ingredients.toString().trim().isNotEmpty) {
      return ingredients.toString().trim();
    }
    return null;
  }

  static List<String> _extractAllergens(Map<String, dynamic> json) {
    final allergens = <String>[];

    // Manejar con cuidado el caso de allergens_tags que podría no ser una lista
    try {
      final allergensTags = json['allergens_tags'];
      if (allergensTags is List) {
        allergens.addAll(allergensTags.map((e) => e.toString()));
      }
    } catch (e) {
      print('Error extrayendo allergens_tags: $e');
    }

    // Extraer alergenos de ingredientes
    try {
      final allergensFromIngredients = json['allergens_from_ingredients'];
      if (allergensFromIngredients is String &&
          allergensFromIngredients.isNotEmpty) {
        allergens.add(allergensFromIngredients);
      }
    } catch (e) {
      print('Error extrayendo allergens_from_ingredients: $e');
    }

    // Extraer alergenos del usuario
    try {
      final allergensFromUser = json['allergens_from_user'];
      if (allergensFromUser is String && allergensFromUser.isNotEmpty) {
        allergens.add(allergensFromUser);
      }
    } catch (e) {
      print('Error extrayendo allergens_from_user: $e');
    }

    // Si después de todo no hay alérgenos, devolver una lista vacía
    if (allergens.isEmpty) {
      return [];
    }

    return allergens.map((a) => a.toString().replaceAll('en:', '')).toList();
  }

  static List<String> _extractStores(Map<String, dynamic> json) {
    final stores = <String>[];

    try {
      final storesTags = json['stores_tags'];
      if (storesTags is List) {
        stores.addAll(
          storesTags.map((e) => e.toString().replaceAll('en:', '')),
        );
      }
    } catch (e) {
      print('Error extrayendo stores_tags: $e');
    }

    try {
      final storesString = json['stores'];
      if (storesString is String && storesString.isNotEmpty) {
        stores.addAll(storesString.split(',').map((s) => s.trim()));
      }
    } catch (e) {
      print('Error extrayendo stores: $e');
    }

    return stores.where((s) => s.isNotEmpty).toList();
  }

  static String? _extractCategory(Map<String, dynamic> json) {
    try {
      final categories = json['categories_tags'];
      if (categories is List && categories.isNotEmpty) {
        // Tomar la categoría más específica (última en la lista)
        return categories.last.toString();
      }
    } catch (e) {
      print('Error extrayendo categories_tags: $e');
    }

    try {
      final categoriesStr = json['categories'];
      if (categoriesStr is String && categoriesStr.isNotEmpty) {
        return categoriesStr;
      }
    } catch (e) {
      print('Error extrayendo categories: $e');
    }

    return null;
  }

  static List<String> _extractLabels(Map<String, dynamic> json) {
    final labels = <String>[];

    try {
      final labelsTags = json['labels_tags'];
      if (labelsTags is List) {
        labels.addAll(
          labelsTags.map((e) => e.toString().replaceAll('en:', '')),
        );
      }
    } catch (e) {
      print('Error extrayendo labels_tags: $e');
    }

    // Añadir etiquetas específicas relevantes
    try {
      final labelsString = json['labels'];
      if (labelsString is String && labelsString.isNotEmpty) {
        labels.addAll(labelsString.split(',').map((s) => s.trim()));
      }
    } catch (e) {
      print('Error extrayendo labels: $e');
    }

    return labels.where((l) => l.isNotEmpty).toList();
  }

  static double? _extractRating(Map<String, dynamic> json) {
    // Open Food Facts no tiene rating directo, pero podemos usar otros indicadores
    final dynamic raw = json['popularity_key'];
    if (raw == null) return null;

    double? value;
    if (raw is num) {
      value = raw.toDouble();
    } else if (raw is String) {
      final parsed = num.tryParse(raw.trim());
      if (parsed != null) value = parsed.toDouble();
    }

    if (value == null) return null;

    // Convertir popularidad a una escala de 0-5
    final score = (value / 100000).clamp(0.0, 5.0);
    return score;
  }

  Map<String, dynamic> toJson() {
    return {
      'code': id,
      'product_name': name,
      'brands': brands,
      'image_front_url': imageUrl,
      'ingredients_text': ingredients,
      'allergens_tags': allergens,
      'stores_tags': stores,
      'nutrition_grade_fr': nutritionGrade,
      'categories': category,
      'nutriments': nutriments,
      'labels_tags': labels,
      'rating': rating,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? brands,
    String? imageUrl,
    String? ingredients,
    List<String>? allergens,
    List<String>? stores,
    String? nutritionGrade,
    String? category,
    Map<String, dynamic>? nutriments,
    List<String>? labels,
    double? rating,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brands: brands ?? this.brands,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      stores: stores ?? this.stores,
      nutritionGrade: nutritionGrade ?? this.nutritionGrade,
      category: category ?? this.category,
      nutriments: nutriments ?? this.nutriments,
      labels: labels ?? this.labels,
      rating: rating ?? this.rating,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, brands: $brands)';
  }
}

extension ProductSearchExtension on Product {
  bool matchesQuery(String query) {
    final q = query.toLowerCase();
    return cleanName.toLowerCase().contains(q) ||
        safeBrands.toLowerCase().contains(q) ||
        safeCategory.toLowerCase().contains(q) ||
        labels.join(' ').toLowerCase().contains(q);
  }

  int relevanceScore(String query) {
    final q = query.toLowerCase();
    int score = 0;

    if (cleanName.toLowerCase().contains(q)) score += 3;
    if (safeBrands.toLowerCase().contains(q)) score += 2;
    if (safeCategory.toLowerCase().contains(q)) score += 1;
    if (labels.join(' ').toLowerCase().contains(q)) score += 1;

    return score;
  }
}
