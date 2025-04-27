import 'dart:convert';

class CheckoutResponse {
  final bool status;
  final String message;
  final CheckoutData data;

  CheckoutResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      status: json['status'],
      message: json['message'],
      data: CheckoutData.fromJson(json['data']),
    );
  }
}

class CheckoutData {
  final List<Product> products;
  final double? shippingCost;

  CheckoutData({required this.products, this.shippingCost = 0});

  factory CheckoutData.fromJson(Map<String, dynamic> json) {
    return CheckoutData(
      products: (json['products'] as List)
          .map((product) => Product.fromJson(product))
          .toList(),
      shippingCost: json['shipping_cost'] != null
          ? double.tryParse(json['shipping_cost'].toString()) ?? 0
          : 0,
    );
  }
}

class Product {
  final int quantity;
  final int id;
  final String code;
  final String? barcode;
  final int? userId;
  final String title;
  final String slug;
  final String summary;
  final String description;
  final double price;
  final String imageUrl;

  Product({
    required this.quantity,
    required this.id,
    required this.code,
    this.barcode,
    this.userId,
    required this.title,
    required this.slug,
    required this.summary,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Xử lý URL hình ảnh - đảm bảo nó là một chuỗi URL duy nhất
    String processImageUrl(dynamic imageData) {
      const String placeholderImage = 'assets/images/placeholder.png';

      if (imageData == null) {
        return placeholderImage;
      }

      // Nếu là String
      if (imageData is String) {
        if (imageData.isEmpty) {
          return placeholderImage;
        }

        // Kiểm tra nếu là chuỗi chứa nhiều URL phân cách bằng dấu phẩy
        if (imageData.contains(',')) {
          // Lấy URL đầu tiên trong chuỗi phân cách bằng dấu phẩy
          return imageData.split(',')[0];
        }

        // Nếu là chuỗi JSON chứa mảng
        if (imageData.startsWith('[') && imageData.endsWith(']')) {
          try {
            List<dynamic> imageList = jsonDecode(imageData);
            if (imageList.isNotEmpty) {
              return imageList[0].toString();
            }
            return placeholderImage;
          } catch (e) {
            // Nếu không parse được, trả về chuỗi ban đầu
            return imageData;
          }
        }

        // Chuỗi URL đơn giản
        return imageData;
      }

      // Nếu là List (từ API Laravel)
      if (imageData is List) {
        if (imageData.isNotEmpty) {
          return imageData[0].toString();
        }
        return placeholderImage;
      }

      // Trường hợp khác, trả về ảnh placeholder
      return placeholderImage;
    }

    // Log the raw JSON data to debug
    print("Processing product JSON: ${json['name'] ?? json['title']}");
    print("Image data: ${json['photos'] ?? json['image']}");

    // Handle both quantity and qty fields
    int qty = 1;
    if (json.containsKey('quantity')) {
      qty = int.tryParse(json['quantity'].toString()) ?? 1;
    } else if (json.containsKey('qty')) {
      qty = int.tryParse(json['qty'].toString()) ?? 1;
    }

    return Product(
      quantity: qty,
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      barcode: json['barcode'],
      userId: json['user_id'],
      title: json['name'] ?? json['title'] ?? '',
      slug: json['slug'] ?? '',
      summary: json['summary'] ?? '',
      description: json['description'] ?? '',
      price: double.parse((json['price'] ?? '0').toString()),
      imageUrl:
          processImageUrl(json['photos'] ?? json['image'] ?? json['image_url']),
    );
  }

  String get formattedPrice => "${price.toStringAsFixed(0)}";
  double get totalPrice => price * quantity;
}
