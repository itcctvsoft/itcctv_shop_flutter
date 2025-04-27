import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/models/comment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommentRepository {
  // Thêm bình luận mới cho sản phẩm
  Future<Map<String, dynamic>> addComment({
    required int productId,
    required int userId,
    required String comment,
    required int rating,
  }) async {
    try {
      // Lấy tên người dùng và email từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('fullName') ?? 'Người dùng';

      // Gán email mặc định nếu không có
      String email = prefs.getString('userEmail') ?? '';
      if (email.isEmpty) {
        email = 'user$userId@example.com'; // Email mặc định để tránh lỗi SQL
      }

      // Chuẩn bị dữ liệu request theo đúng API
      final Map<String, dynamic> body = {
        'product_id': productId,
        'user_id': userId,
        'comment': comment,
        'rating': rating,
        'name': name,
        'email': email, // Email luôn có giá trị
      };

      print('Gửi request thêm bình luận: $body');

      // Gọi API thêm bình luận
      final response = await http.post(
        Uri.parse(api_comment_add),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(body),
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        // Thành công (201 Created)
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Bình luận đã được thêm thành công',
          'data': responseData['data'] != null
              ? Comment.fromJson(responseData['data'] as Map<String, dynamic>)
              : null,
        };
      } else {
        // Handle specific error for duplicate comments
        if (responseData['message'] != null &&
            responseData['message']
                .toString()
                .contains('đã bình luận cho sản phẩm này')) {
          return {
            'success': false,
            'message':
                'Bạn đã bình luận cho sản phẩm này rồi. Vui lòng cập nhật bình luận hiện tại.',
          };
        } else {
          // Other errors
          return {
            'success': false,
            'message': responseData['message'] ?? 'Không thể thêm bình luận',
          };
        }
      }
    } catch (e) {
      print('Lỗi khi thêm bình luận: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi thêm bình luận: $e',
      };
    }
  }

  // Lấy bình luận cho một sản phẩm cụ thể
  Future<CommentResponse> getCommentsByProduct(int productId) async {
    try {
      print('Đang lấy bình luận cho sản phẩm: $productId');

      // Gọi API lấy bình luận theo sản phẩm
      final response = await http.get(
        Uri.parse('${api_comment_by_product}?product_id=$productId'),
        headers: {'Accept': 'application/json'},
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Parse response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // Kiểm tra success flag từ API
        if (responseData['success'] == true) {
          try {
            return CommentResponse.fromJson(responseData);
          } catch (parseError) {
            print('Lỗi khi phân tích dữ liệu bình luận: $parseError');
            return CommentResponse(
              success: true,
              totalComments: 0,
              averageRating: 0.0,
              comments: [],
            );
          }
        } else {
          print('API trả về success=false: ${responseData['message']}');
          return CommentResponse(
            success: false,
            totalComments: 0,
            averageRating: 0.0,
            comments: [],
          );
        }
      } else {
        print('Lỗi HTTP khi lấy bình luận: ${response.statusCode}');
        return CommentResponse(
          success: false,
          totalComments: 0,
          averageRating: 0.0,
          comments: [],
        );
      }
    } catch (e) {
      print('Exception khi lấy bình luận: $e');
      return CommentResponse(
        success: false,
        totalComments: 0,
        averageRating: 0.0,
        comments: [],
      );
    }
  }

  // Cập nhật bình luận hiện có
  Future<Map<String, dynamic>> updateComment({
    required int commentId,
    required int userId,
    required String comment,
    required int rating,
  }) async {
    try {
      // Lấy email từ SharedPreferences nếu cần thiết
      final prefs = await SharedPreferences.getInstance();

      // Gán email mặc định nếu không có
      String email = prefs.getString('userEmail') ?? '';
      if (email.isEmpty) {
        email = 'user$userId@example.com'; // Email mặc định để tránh lỗi SQL
      }

      // Chuẩn bị dữ liệu request theo đúng API
      final Map<String, dynamic> body = {
        'comment_id': commentId,
        'user_id': userId,
        'comment': comment,
        'rating': rating,
        'email': email, // Email luôn có giá trị
      };

      print('Gửi request cập nhật bình luận: $body');

      // Gọi API cập nhật bình luận
      final response = await http.put(
        Uri.parse(api_comment_update),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(body),
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // Thành công
        return {
          'success': true,
          'message': responseData['message'] ??
              'Bình luận đã được cập nhật thành công',
          'data': responseData['data'] != null
              ? Comment.fromJson(responseData['data'] as Map<String, dynamic>)
              : null,
        };
      } else {
        // Lỗi (400 Bad Request, 403 Forbidden, hoặc khác)
        return {
          'success': false,
          'message': responseData['message'] ?? 'Không thể cập nhật bình luận',
        };
      }
    } catch (e) {
      print('Lỗi khi cập nhật bình luận: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi cập nhật bình luận: $e',
      };
    }
  }

  // Xóa bình luận
  Future<Map<String, dynamic>> deleteComment({
    required int commentId,
    required int userId,
  }) async {
    try {
      // Chuẩn bị dữ liệu request theo đúng API
      final Map<String, dynamic> body = {
        'comment_id': commentId,
        'user_id': userId,
      };

      print('Gửi request xóa bình luận: $body');

      // Gọi API xóa bình luận
      final response = await http.delete(
        Uri.parse(api_comment_delete),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(body),
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // Thành công
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Bình luận đã được xóa thành công',
        };
      } else {
        // Lỗi (400 Bad Request, 403 Forbidden, hoặc khác)
        return {
          'success': false,
          'message': responseData['message'] ?? 'Không thể xóa bình luận',
        };
      }
    } catch (e) {
      print('Lỗi khi xóa bình luận: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi xóa bình luận: $e',
      };
    }
  }
}
