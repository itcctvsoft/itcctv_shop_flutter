import 'dart:convert';

class CartItem {
  final int id;
  final String title;
  final int price;
  final dynamic photo; // Có thể là String hoặc List<String>
  late final int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.photo,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Xử lý trường photo có thể là chuỗi hoặc mảng
    var photoData = json['photo'];

    // Nếu là JSON string chứa mảng
    if (photoData is String &&
        photoData.startsWith('[') &&
        photoData.endsWith(']')) {
      try {
        photoData = List<String>.from(jsonDecode(photoData));
      } catch (e) {
        // Nếu không parse được, giữ nguyên chuỗi
        print("Không thể parse chuỗi JSON: $e");
      }
    }

    return CartItem(
      id: json['id'],
      title: json['title'],
      price: json['price'],
      photo: photoData,
      quantity: json['quantity'],
    );
  }
}
