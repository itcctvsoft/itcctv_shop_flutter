import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shoplite/constants/apilist.dart'; // Đường dẫn API
import 'package:shoplite/models/Cart.dart'; // Đường dẫn model Cart

class CartRepository {
  final String apiUrl = api_get_cart;
  final String apiAddToCart = api_add_to_cart;
  final String apiRemoveFromCart = api_delete_cart;
  final String apiUpdateCart = api_put_cart;

  // Hàm chung để gửi yêu cầu HTTP
  Future<dynamic> _sendRequest(
      Uri url, {
        required String method,
        required String token,
        Map<String, dynamic>? body,
      }) async {
    if (token.isEmpty) {
      throw Exception('Authentication token is missing. Please login.');
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      http.Response response;
      if (method == 'GET') {
        response = await http.get(url, headers: headers);
      } else if (method == 'POST') {
        response = await http.post(url, headers: headers, body: json.encode(body));
      } else if (method == 'DELETE') {
        response = await http.delete(url, headers: headers, body: json.encode(body));
      } else if (method == 'PUT') {
        response = await http.put(url, headers: headers, body: json.encode(body));
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      // Log URL, method, headers và body để debug
      print('Request URL: $url');
      print('Request Method: $method');
      print('Request Headers: $headers');
      if (body != null) print('Request Body: ${json.encode(body)}');

      // Kiểm tra mã trạng thái HTTP
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Xử lý phản hồi JSON
        final data = json.decode(response.body);
        print('Response Data: $data');
        if (data['status'] == false) {
          throw Exception(data['message'] ?? 'An error occurred');
        }
        return data;
      } else {
        // Xử lý lỗi HTTP chi tiết
        throw Exception(
            'HTTP error: ${response.statusCode} - ${response.reasonPhrase}\nResponse Body: ${response.body}');
      }
    } catch (e) {
      // Log lỗi để dễ debug
      print('Failed to send request: $e');
      throw Exception('Failed to send request: $e');
    }
  }

  Future<List<CartItem>> getCartItems(String token) async {
    final url = Uri.parse(apiUrl);

    try {
      print('Gửi yêu cầu GET danh sách giỏ hàng đến URL: $url');
      final data = await _sendRequest(url, method: 'GET', token: token);

      if (data['data'] == null || (data['data'] as List).isEmpty) {
        print('Giỏ hàng trống.');
        return [];
      }

      List<CartItem> cartItems = (data['data'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList();

      print('Số lượng sản phẩm trong giỏ hàng: ${cartItems.length}');
      return cartItems;
    } catch (e) {
      print('Lỗi khi lấy danh sách giỏ hàng: $e');
      rethrow;
    }
  }

  // Thêm sản phẩm vào giỏ hàng
  Future<void> addToCart(String token, int productId, int quantity) async {
    final url = Uri.parse(apiAddToCart);

    try {
      // Gửi yêu cầu POST để thêm sản phẩm
      await _sendRequest(
        url,
        method: 'POST',
        token: token,
        body: {'product_id': productId, 'quantity': quantity},
      );

      print('Sản phẩm đã được thêm vào giỏ hàng: $productId - Số lượng: $quantity');
    } catch (e) {
      // Log lỗi và throw lại để lớp trên xử lý
      print('Lỗi khi thêm sản phẩm vào giỏ hàng: $e');
      rethrow;
    }
  }

  // Hàm xóa sản phẩm khỏi giỏ hàng
  Future<void> removeFromCart(String token, int productId) async {
    final url = Uri.parse(apiRemoveFromCart);

    try {
      print('Gửi yêu cầu xóa sản phẩm khỏi giỏ hàng: Product ID $productId');
      print('API URL: $url');

      // Sử dụng hàm _sendRequest để gửi yêu cầu DELETE
      final data = await _sendRequest(
        url,
        method: 'DELETE', // Sử dụng DELETE nếu API hỗ trợ
        token: token,
        body: {'product_id': productId},
      );

      // Kiểm tra trạng thái phản hồi từ server
      if (data['status'] == true) {
        print('Sản phẩm đã được xóa khỏi giỏ hàng: $productId');
      } else {
        throw Exception(data['message'] ?? 'Lỗi không xác định khi xóa sản phẩm.');
      }
    } catch (e) {
      // Log lỗi và throw để lớp trên xử lý
      print('Lỗi khi xóa sản phẩm khỏi giỏ hàng: $e');
      rethrow;
    }
  }
  // Hàm chỉnh sửa thông tin sản phẩm trong giỏ hàng
  Future<void> updateCartItem(String token, int productId, int quantity) async {
    final url = Uri.parse(apiUpdateCart); // Thay bằng URL API chỉnh sửa

    try {
      print('Gửi yêu cầu chỉnh sửa sản phẩm trong giỏ hàng: Product ID $productId');
      print('API URL: $url');

      // Sử dụng _sendRequest để gửi yêu cầu PUT
      final data = await _sendRequest(
        url,
        method: 'PUT', // Hoặc PATCH nếu API yêu cầu
        token: token,
        body: {
          'product_id': productId,
          'quantity': quantity,
        },
      );

      // Kiểm tra trạng thái phản hồi từ server
      if (data['status'] == true) {
        print('Sản phẩm đã được chỉnh sửa: $productId - Số lượng: $quantity');
      } else {
        throw Exception(data['message'] ?? 'Lỗi không xác định khi chỉnh sửa sản phẩm.');
      }
    } catch (e) {
      // Log lỗi và throw lại để lớp trên xử lý
      print('Lỗi khi chỉnh sửa sản phẩm trong giỏ hàng: $e');
      rethrow;
    }
  }



}
