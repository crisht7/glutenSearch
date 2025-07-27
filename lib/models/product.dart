class Product {
  final String id;
  final String name;
  final String? brands; // Puede ser nulo
  final String? imageUrl; // Puede ser nulo
  final String? ingredients; // Puede ser nulo
  final List<String> allergens;
  final List<String> stores;

  Product({
    required this.id,
    required this.name,
    this.brands,
    this.imageUrl,
    this.ingredients,
    required this.allergens,
    required this.stores,
  });

  /// Getter para manejar un posible imageUrl nulo de forma segura en la UI.
  String get safeImageUrl {
    return imageUrl ??
        'https://static.thenounproject.com/png/3674270-200.png'; // URL de una imagen placeholder
  }

  /// Getter para mostrar una marca segura en la UI.
  String get safeBrands {
    return brands ?? 'Marca no disponible';
  }

  /// Factory para crear un Producto desde el JSON de Open Food Facts.
  /// Se encarga de la "traducción" de los nombres de campo.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['code'] ?? 'no-id-${DateTime.now().millisecondsSinceEpoch}',
      name: json['product_name'] ?? 'Nombre no disponible',
      brands: json['brands'], // Puede ser nulo directamente
      imageUrl: json['image_front_url'], // Puede ser nulo
      ingredients: json['ingredients_text'], // Puede ser nulo
      allergens:
          (json['allergens_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      stores:
          (json['stores_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
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
    };
  }
}
