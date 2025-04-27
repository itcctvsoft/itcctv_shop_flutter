import 'package:shoplite/models/product.dart';

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
      currentPage: json['current_page'] ?? 0,
      lastPage: json['last_page'] ?? 0,
      perPage: json['per_page'] ?? 0,
      total: json['total'] ?? 0,
    );
  }

  // Phương thức để lấy trang tiếp theo
  bool get hasNextPage => currentPage < lastPage;
}

class ProductResponse {
  final List<Product> products;
  final Pagination pagination;

  ProductResponse({
    required this.products,
    required this.pagination,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    List<Product> productList = (json['products'] as List<dynamic>)
        .map((productJson) => Product.fromJson(productJson))
        .toList();
    Pagination pagination = Pagination.fromJson(json['pagination']);

    return ProductResponse(
      products: productList,
      pagination: pagination,
    );
  }
}
