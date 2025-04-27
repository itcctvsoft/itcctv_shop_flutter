import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/models/category.dart';

class CategoryRepository {
  // Hàm chung để gửi yêu cầu HTTP
  Future<dynamic> _sendRequest(
    Uri url, {
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    // Thêm token nếu có
    if (g_token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $g_token';
    }

    try {
      http.Response response;
      if (method == 'GET') {
        response = await http.get(url, headers: headers);
      } else if (method == 'POST') {
        response =
            await http.post(url, headers: headers, body: json.encode(body));
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      print('Request URL: $url');
      print('Request Method: $method');
      print('Request Headers: $headers');
      if (body != null) print('Request Body: ${json.encode(body)}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        print('Response Data: $data');
        if (data['status'] == false) {
          throw Exception(data['message'] ?? 'An error occurred');
        }
        return data;
      } else {
        throw Exception(
            'HTTP error: ${response.statusCode} - ${response.reasonPhrase}\nResponse Body: ${response.body}');
      }
    } catch (e) {
      print('Failed to send request: $e');
      throw Exception('Failed to send request: $e');
    }
  }

  // Lấy danh sách danh mục với phân trang
  Future<CategoryApiResponse> getCategories(int page, int perPage) async {
    final url =
        Uri.parse('$api_get_category_list?page=$page&per_page=$perPage');

    try {
      print('Gửi yêu cầu GET danh sách danh mục đến URL: $url');
      final data = await _sendRequest(url, method: 'GET');
      return CategoryApiResponse.fromJson(data);
    } catch (e) {
      print('Lỗi khi lấy danh sách danh mục: $e');
      rethrow;
    }
  }

  // Cung cấp danh mục mẫu trong trường hợp lỗi
  List<Category> getDummyCategories() {
    return [
      Category(
        id: 1,
        title: 'Thời trang',
        slug: 'thoi-trang',
        photos: ['https://via.placeholder.com/150/771796/FFFFFF?text=Fashion'],
        description: 'Các sản phẩm thời trang',
        isParent: 1,
      ),
      Category(
        id: 2,
        title: 'Điện tử',
        slug: 'dien-tu',
        photos: [
          'https://via.placeholder.com/150/24f355/000000?text=Electronics'
        ],
        description: 'Các sản phẩm điện tử',
        isParent: 1,
      ),
      Category(
        id: 3,
        title: 'Gia dụng',
        slug: 'gia-dung',
        photos: [
          'https://via.placeholder.com/150/d32776/FFFFFF?text=Household'
        ],
        description: 'Các sản phẩm gia dụng',
        isParent: 1,
      ),
      Category(
        id: 4,
        title: 'Mỹ phẩm',
        slug: 'my-pham',
        photos: [
          'https://via.placeholder.com/150/f66b97/000000?text=Cosmetics'
        ],
        description: 'Các sản phẩm mỹ phẩm',
        isParent: 1,
      ),
    ];
  }
}
