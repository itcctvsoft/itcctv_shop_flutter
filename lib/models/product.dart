class Product {
  final int id;
  final String title;
  final double price;
  final String description;
  final List<String> photos;
  final int categoryId;
  final int brandId;
  final int stock;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.photos,
    required this.categoryId,
    required this.brandId,
    this.stock = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle photos - could be a list, string, or null
    List<String> photosList = [];

    try {
      if (json['photos'] is List) {
        photosList = List<String>.from(json['photos']);
      } else if (json['photos'] is String) {
        // If it's a single string, add it to the list
        String photoStr = json['photos'].toString();
        if (photoStr.isNotEmpty) {
          photosList = [photoStr];
        }
      } else if (json['photo'] != null) {
        // Some APIs might use 'photo' instead of 'photos'
        if (json['photo'] is List) {
          photosList = List<String>.from(json['photo']);
        } else if (json['photo'] is String) {
          String photoStr = json['photo'].toString();
          if (photoStr.isNotEmpty) {
            photosList = [photoStr];
          }
        }
      }

      // If we still have no photos, use a placeholder
      if (photosList.isEmpty) {
        photosList = [
          'https://via.placeholder.com/150/cccccc/ffffff?text=No+Image'
        ];
      }
    } catch (e) {
      print('Error parsing photos: $e');
      // Fallback to placeholder
      photosList = [
        'https://via.placeholder.com/150/cccccc/ffffff?text=No+Image'
      ];
    }

    // Handle price which might be a string or number
    double parsePrice(dynamic price) {
      if (price == null) return 0.0;
      if (price is double) return price;
      if (price is int) return price.toDouble();
      if (price is String) {
        try {
          // Remove any non-numeric characters except decimal point
          String cleanPrice = price.replaceAll(RegExp(r'[^\d.]'), '');
          return double.tryParse(cleanPrice) ?? 0.0;
        } catch (e) {
          print('Error parsing price string: $e');
          return 0.0;
        }
      }
      return 0.0;
    }

    // Safely parse integers with fallback
    int safeParseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          print('Error parsing int: $e');
          return defaultValue;
        }
      }
      return defaultValue;
    }

    // Safely handle description text - preserving HTML formatting and newlines
    String safeDescription(dynamic text) {
      if (text == null) return '';

      String result = text.toString();

      // Only remove potentially dangerous or problematic characters
      // But preserve HTML formatting and newlines for proper display
      try {
        result = result
        // Remove only null characters
            .replaceAll('\u0000', '')
        // Convert HTML non-breaking spaces to regular spaces
            .replaceAll('&nbsp;', ' ');

        // Don't strip HTML tags or newlines as they're needed for formatting
      } catch (e) {
        print('Error processing description: $e');
        return '';
      }

      return result;
    }

    // Create product with safe parsing
    try {
      return Product(
        id: safeParseInt(json['id']),
        title: json['title']?.toString() ?? 'Unnamed Product',
        price: parsePrice(json['price']),
        description: safeDescription(json['description']),
        photos: photosList,
        categoryId: safeParseInt(json['category_id']),
        brandId: safeParseInt(json['brand_id']),
        stock: safeParseInt(json['stock']),
      );
    } catch (e) {
      print('Error creating Product from JSON: $e');
      // Return a fallback product if parsing fails
      return Product(
        id: 0,
        title: 'Error Loading Product',
        price: 0,
        description: 'There was an error loading this product',
        photos: ['https://via.placeholder.com/150/ff0000/ffffff?text=Error'],
        categoryId: 0,
        brandId: 0,
        stock: 0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'photos': photos,
      'category_id': categoryId,
      'brand_id': brandId,
      'stock': stock,
    };
  }
}

class ProductApiResponse {
  final List<Product> products;
  final Pagination pagination;

  ProductApiResponse({
    required this.products,
    required this.pagination,
  });

  factory ProductApiResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    // Parse products
    final productsList = data['products'] as List<dynamic>;
    final products =
    productsList.map((item) => Product.fromJson(item)).toList();

    // Parse pagination
    final paginationData = data['pagination'] as Map<String, dynamic>;
    final pagination = Pagination.fromJson(paginationData);

    return ProductApiResponse(
      products: products,
      pagination: pagination,
    );
  }
}

class PaginationResponse<T> {
  final List<T> items;
  final Pagination pagination;

  PaginationResponse({
    required this.items,
    required this.pagination,
  });
}

class Pagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
    );
  }
}
