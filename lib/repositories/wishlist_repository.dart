import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/models/wishlist.dart';

class WishlistRepository {
  // Hàm chung để gửi yêu cầu HTTP
  Future<dynamic> _sendRequest(
    Uri url, {
    required String method,
    required String token,
    Map<String, dynamic>? body,
  }) async {
    if (token.isEmpty) {
      throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
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
        response =
            await http.post(url, headers: headers, body: json.encode(body));
      } else if (method == 'DELETE') {
        response = await http.delete(url, headers: headers);
      } else {
        throw Exception('Phương thức HTTP không được hỗ trợ: $method');
      }

      print('Request URL: $url');
      print('Request Method: $method');
      print('Request Headers: $headers');
      if (body != null) print('Request Body: ${json.encode(body)}');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        if (data['status'] == false) {
          throw Exception(data['message'] ?? 'Đã xảy ra lỗi');
        }
        return data;
      } else {
        throw Exception(
            'Lỗi HTTP: ${response.statusCode} - ${response.reasonPhrase}\nPhản hồi: ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi gửi yêu cầu: $e');
      throw Exception('Lỗi khi gửi yêu cầu: $e');
    }
  }

  // Thêm sản phẩm vào wishlist
  Future<bool> addToWishlist(String token, int productId) async {
    try {
      final Uri url = Uri.parse(api_wishlist_add);
      final data = await _sendRequest(
        url,
        method: 'POST',
        token: token,
        body: {'product_id': productId},
      );

      return data['status'] == true;
    } catch (e) {
      print('Lỗi khi thêm vào wishlist: $e');
      return false;
    }
  }

  // Xóa sản phẩm khỏi wishlist
  Future<bool> removeFromWishlist(String token, int productId) async {
    try {
      final Uri url = Uri.parse('${api_wishlist_remove}/$productId');
      final data = await _sendRequest(
        url,
        method: 'DELETE',
        token: token,
      );

      return data['status'] == true;
    } catch (e) {
      print('Lỗi khi xóa khỏi wishlist: $e');
      return false;
    }
  }

  // Lấy danh sách wishlist
  Future<List<int>> getWishlistProductIds(String token) async {
    try {
      final Uri url = Uri.parse(api_wishlist_view);
      final data = await _sendRequest(
        url,
        method: 'GET',
        token: token,
      );

      if (data['status'] == true &&
          data['data'] != null &&
          data['data']['wishlists'] != null) {
        final List<dynamic> wishlistItems = data['data']['wishlists'];
        return wishlistItems
            .map<int>((item) => item['product_id'] as int)
            .toList();
      }

      return [];
    } catch (e) {
      print('Lỗi khi lấy danh sách wishlist: $e');
      return [];
    }
  }
}
