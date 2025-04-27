import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/models/chat_message.dart';

class ChatRepository {
  // Singleton pattern
  static final ChatRepository _instance = ChatRepository._internal();
  factory ChatRepository() => _instance;
  ChatRepository._internal();

  final Dio _dio = Dio();

  // Lấy hoặc tạo cuộc trò chuyện với admin
  Future<Map<String, dynamic>> getOrCreateSupportChat(String token) async {
    try {
      debugPrint('ChatRepository: Đang tạo/lấy chat hỗ trợ');

      final response = await http.post(
        Uri.parse(api_chat_get_or_create),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('ChatRepository: Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('ChatRepository: Phản hồi thành công: $responseData');
        return {
          'success': true,
          'chatId': responseData['data']['chat_id'],
        };
      } else {
        debugPrint('ChatRepository: Lỗi khi lấy chat: ${response.body}');
        return {
          'success': false,
          'message': 'Không thể kết nối với bộ phận hỗ trợ',
          'error': response.body,
        };
      }
    } catch (e) {
      debugPrint('ChatRepository: Exception: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi kết nối với máy chủ',
        'error': e.toString(),
      };
    }
  }

  // Gửi tin nhắn văn bản
  Future<Map<String, dynamic>> sendTextMessage(
      String token, int chatId, String message,
      {Map<String, dynamic>? userInfo}) async {
    try {
      debugPrint('📤 ChatRepository: Đang gửi tin nhắn đến chatId=$chatId');
      debugPrint('📤 ChatRepository: Nội dung: "$message"');
      debugPrint('📤 ChatRepository: URL API - ${api_chat_send}');

      // Chuẩn bị dữ liệu gửi lên server
      var requestData = {
        'chat_id': chatId,
        'message': message,
      };

      // Thêm thông tin userInfo nếu có
      if (userInfo != null) {
        requestData['user_info'] = userInfo;
      }

      final response = await http
          .post(
        Uri.parse(api_chat_send),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      )
          .timeout(Duration(seconds: 10), onTimeout: () {
        debugPrint('⏱️ ChatRepository: Timeout khi gửi tin nhắn');
        throw TimeoutException('Gửi tin nhắn quá thời gian.');
      });

      debugPrint('📤 ChatRepository: Status code: ${response.statusCode}');
      debugPrint('📤 ChatRepository: Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('✅ ChatRepository: Gửi tin nhắn thành công');
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else if (response.statusCode == 401) {
        debugPrint('❌ ChatRepository: Lỗi xác thực 401');
        return {
          'success': false,
          'message': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          'error': 'Lỗi xác thực: ${response.body}',
        };
      } else if (response.statusCode == 422) {
        debugPrint('❌ ChatRepository: Lỗi dữ liệu 422');
        // Parse lỗi validation
        Map<String, dynamic> errorData;
        try {
          errorData = json.decode(response.body);
        } catch (e) {
          errorData = {'message': 'Dữ liệu không hợp lệ'};
        }
        return {
          'success': false,
          'message': errorData['message'] ?? 'Dữ liệu không hợp lệ',
          'error': 'Validation Error: ${errorData['errors'] ?? response.body}',
        };
      } else {
        debugPrint('❌ ChatRepository: Lỗi khi gửi tin nhắn: ${response.body}');
        return {
          'success': false,
          'message': 'Không thể gửi tin nhắn',
          'error': response.body,
        };
      }
    } on SocketException catch (e) {
      debugPrint('🔌 ChatRepository: SocketException: $e');
      return {
        'success': false,
        'message':
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
        'error': e.toString(),
      };
    } on TimeoutException catch (e) {
      debugPrint('⏱️ ChatRepository: TimeoutException: $e');
      return {
        'success': false,
        'message': 'Gửi tin nhắn quá thời gian. Vui lòng thử lại.',
        'error': e.toString(),
      };
    } catch (e) {
      debugPrint('❌ ChatRepository: Exception khi gửi tin nhắn: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi gửi tin nhắn',
        'error': e.toString(),
      };
    }
  }

  // Gửi tin nhắn có đính kèm
  Future<Map<String, dynamic>> sendMessageWithAttachment(
      String token, int chatId, String? message, File attachment,
      {Map<String, dynamic>? userInfo}) async {
    try {
      debugPrint('📤 ChatRepository: Đang gửi tin nhắn có đính kèm');
      debugPrint('📤 ChatRepository: File path: ${attachment.path}');

      // Xác định loại tệp qua phần mở rộng
      final fileName = attachment.path.split('/').last.toLowerCase();
      final isImage = fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg') ||
          fileName.endsWith('.png') ||
          fileName.endsWith('.gif') ||
          fileName.endsWith('.webp');

      // Chuẩn bị dữ liệu FormData
      Map<String, dynamic> formDataMap = {
        'chat_id': chatId,
        'message': message ?? '',
        'attachment': await MultipartFile.fromFile(
          attachment.path,
          filename: fileName,
        ),
      };

      // Thêm thông tin userInfo nếu có
      if (userInfo != null) {
        formDataMap['user_info'] = json.encode(userInfo);
      }

      // Tạo FormData để tải lên
      FormData formData = FormData.fromMap(formDataMap);

      debugPrint(
          '📤 ChatRepository: Đang tải lên ${isImage ? "hình ảnh" : "tệp đính kèm"}: $fileName');

      final response = await _dio.post(
        api_chat_send,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      debugPrint('📤 ChatRepository: Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        debugPrint('✅ ChatRepository: Gửi tin nhắn đính kèm thành công');

        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        debugPrint('❌ ChatRepository: Lỗi khi gửi đính kèm: ${response.data}');
        return {
          'success': false,
          'message': 'Không thể gửi tin nhắn',
          'error': response.data,
        };
      }
    } on DioException catch (e) {
      debugPrint(
          '❌ ChatRepository: DioException khi gửi đính kèm: ${e.message}');
      final String errorMessage;

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Quá thời gian kết nối khi tải lên tệp đính kèm';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Lỗi kết nối. Vui lòng kiểm tra kết nối mạng của bạn';
      } else {
        errorMessage = 'Lỗi khi gửi tệp đính kèm: ${e.message}';
      }

      return {
        'success': false,
        'message': errorMessage,
        'error': e.toString(),
      };
    } catch (e) {
      debugPrint('❌ ChatRepository: Exception khi gửi đính kèm: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi gửi tin nhắn',
        'error': e.toString(),
      };
    }
  }

  // Phương thức mới: Gửi hình ảnh dưới dạng base64
  Future<Map<String, dynamic>> sendImageBase64(String token, int chatId,
      String? message, String base64Image, String imageName,
      {Map<String, dynamic>? userInfo}) async {
    try {
      debugPrint('📤 ChatRepository: Đang gửi hình ảnh base64');

      // Kiểm tra độ dài của chuỗi base64 (phải lớn hơn một ngưỡng nhất định)
      if (base64Image.length < 100) {
        return {
          'success': false,
          'message': 'Dữ liệu hình ảnh không hợp lệ',
          'error': 'Chuỗi base64 quá ngắn',
        };
      }

      // Chuẩn bị dữ liệu gửi lên server
      var requestData = {
        'chat_id': chatId,
        'message': message ?? '',
        'image_base64': base64Image,
        'image_name': imageName,
      };

      // Thêm thông tin userInfo nếu có
      if (userInfo != null) {
        requestData['user_info'] = userInfo;
      }

      final response = await http
          .post(
        Uri.parse(api_chat_send),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: json.encode(requestData),
      )
          .timeout(Duration(seconds: 30), onTimeout: () {
        debugPrint('⏱️ ChatRepository: Timeout khi gửi hình ảnh base64');
        throw TimeoutException('Gửi hình ảnh quá thời gian.');
      });

      debugPrint('📤 ChatRepository: Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('✅ ChatRepository: Gửi hình ảnh base64 thành công');

        return {
          'success': true,
          'data': responseData['data'],
        };
      } else if (response.statusCode == 422) {
        debugPrint('❌ ChatRepository: Lỗi dữ liệu 422: ${response.body}');
        Map<String, dynamic> errorData;
        try {
          errorData = json.decode(response.body);
        } catch (e) {
          errorData = {'message': 'Dữ liệu hình ảnh không hợp lệ'};
        }

        return {
          'success': false,
          'message': errorData['message'] ?? 'Dữ liệu hình ảnh không hợp lệ',
          'error': errorData.toString(),
        };
      } else {
        debugPrint(
            '❌ ChatRepository: Lỗi khi gửi hình ảnh base64: ${response.body}');
        return {
          'success': false,
          'message': 'Không thể gửi hình ảnh',
          'error': response.body,
        };
      }
    } on SocketException catch (e) {
      debugPrint('🔌 ChatRepository: SocketException: $e');
      return {
        'success': false,
        'message':
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
        'error': e.toString(),
      };
    } on TimeoutException catch (e) {
      debugPrint('⏱️ ChatRepository: TimeoutException: $e');
      return {
        'success': false,
        'message': 'Gửi hình ảnh quá thời gian. Vui lòng thử lại.',
        'error': e.toString(),
      };
    } catch (e) {
      debugPrint('❌ ChatRepository: Exception khi gửi hình ảnh base64: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi gửi hình ảnh',
        'error': e.toString(),
      };
    }
  }

  // Lấy lịch sử tin nhắn với phân trang - API sử dụng phương thức GET
  Future<Map<String, dynamic>> getChatHistory(String token, int chatId,
      {int page = 1, int perPage = 20}) async {
    try {
      debugPrint(
          '🔄 ChatRepository: Đang tải lịch sử chat với chatId=$chatId, page=$page, perPage=$perPage');

      // API mới đã thay đổi, không cần chat_id trong tham số nữa vì API sẽ tự xác định chat của người dùng
      final url = Uri.parse('$api_chat_history?page=$page&per_page=$perPage');

      debugPrint('🔗 ChatRepository: URL API - ${url.toString()}');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      ).timeout(Duration(seconds: 10), onTimeout: () {
        debugPrint('⏱️ ChatRepository: Timeout khi gọi API chat history');
        throw TimeoutException('Kết nối đến máy chủ quá thời gian.');
      });

      debugPrint(
          '📢 ChatRepository: Đã nhận phản hồi, status code=${response.statusCode}');

      // In chi tiết body của response
      debugPrint(
          '📝 ChatRepository: Response body: ${response.body.substring(0, min(500, response.body.length))}...');

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData;
        try {
          responseData = json.decode(response.body);
          debugPrint('✅ ChatRepository: Phản hồi thành công từ API history');
        } catch (e) {
          debugPrint('❌ ChatRepository: Lỗi khi parse JSON: $e');
          return {
            'success': false,
            'message': 'Lỗi định dạng dữ liệu từ máy chủ',
            'error': e.toString(),
          };
        }

        // Kiểm tra trường success từ API
        if (responseData['success'] == false) {
          debugPrint('❌ ChatRepository: API trả về success=false');
          return {
            'success': false,
            'message':
                responseData['message'] ?? 'Lỗi không xác định từ máy chủ',
            'error': responseData['errors'] != null
                ? json.encode(responseData['errors'])
                : 'Unknown error',
          };
        }

        // Kiểm tra cấu trúc dữ liệu
        if (responseData['data'] == null) {
          debugPrint('❌ ChatRepository: Dữ liệu phản hồi thiếu trường "data"');
          return {
            'success': false,
            'message': 'Cấu trúc dữ liệu phản hồi không hợp lệ',
            'error': 'Dữ liệu không hợp lệ: thiếu trường data',
          };
        }

        // Lấy chat ID từ phản hồi - API mới sẽ trả về chat_id
        final chatId = responseData['data']['chat_id'];
        debugPrint('🆔 ChatRepository: Chat ID từ API: $chatId');

        // In cấu trúc chi tiết của data
        debugPrint(
            '📊 ChatRepository: Data structure: ${responseData['data'].keys.toList()}');

        if (responseData['data']['messages'] == null) {
          debugPrint('⚠️ ChatRepository: Không có tin nhắn nào trong phản hồi');
          return {
            'success': true,
            'chatId': chatId, // Thêm chatId vào kết quả
            'messages': [], // Trả về danh sách trống nếu không có tin nhắn
            'hasMore': false,
            'nextPage': null,
            'total': 0,
          };
        }

        final List<dynamic> messagesJson = responseData['data']['messages'];
        debugPrint(
            '📊 ChatRepository: Đã nhận ${messagesJson.length} tin nhắn');

        // In mẫu tin nhắn đầu tiên để debug
        if (messagesJson.isNotEmpty) {
          debugPrint(
              '📱 ChatRepository: Mẫu tin nhắn đầu tiên: ${json.encode(messagesJson.first)}');
        }

        try {
          final List<ChatMessage> messages =
              messagesJson.map((json) => ChatMessage.fromJson(json)).toList();

          debugPrint(
              '✅ ChatRepository: Đã parse thành công ${messages.length} tin nhắn');

          return {
            'success': true,
            'chatId': chatId, // Thêm chatId vào kết quả
            'messages': messages,
            'hasMore': responseData['data']['has_more'] ?? false,
            'nextPage': responseData['data']['next_page'],
            'total': responseData['data']['total'] ?? 0,
          };
        } catch (parseError) {
          debugPrint('❌ ChatRepository: Lỗi khi parse tin nhắn: $parseError');

          // Log chi tiết hơn về lỗi parse
          if (messagesJson.isNotEmpty) {
            try {
              final firstMessage = messagesJson.first;
              debugPrint(
                  '🔍 ChatRepository: Cấu trúc tin nhắn: ${firstMessage.keys.toList()}');

              // Thử parse tin nhắn đầu tiên
              ChatMessage.fromJson(firstMessage);
              debugPrint(
                  '🔍 ChatRepository: Parse tin nhắn đầu tiên thành công, lỗi có thể ở tin nhắn khác');
            } catch (detailError) {
              debugPrint(
                  '🔍 ChatRepository: Chi tiết lỗi parse tin nhắn đầu tiên: $detailError');
            }
          }

          return {
            'success': false,
            'message': 'Không thể phân tích dữ liệu tin nhắn',
            'error': parseError.toString(),
          };
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ ChatRepository: Lỗi xác thực 401');
        return {
          'success': false,
          'message': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          'error': 'Lỗi xác thực: ${response.body}',
          'status_code': 401,
        };
      } else if (response.statusCode == 403) {
        debugPrint('❌ ChatRepository: Lỗi quyền truy cập 403');
        return {
          'success': false,
          'message':
              'Bạn không có quyền xem tin nhắn trong cuộc trò chuyện này',
          'error': 'Lỗi quyền: ${response.body}',
          'status_code': 403,
        };
      } else if (response.statusCode == 422) {
        debugPrint('❌ ChatRepository: Lỗi dữ liệu đầu vào 422');
        Map<String, dynamic> errorData;
        try {
          errorData = json.decode(response.body);
          debugPrint(
              '❌ ChatRepository: Lỗi validation: ${errorData['errors']}');
        } catch (e) {
          errorData = {'message': 'Dữ liệu không hợp lệ'};
        }

        return {
          'success': false,
          'message': errorData['message'] ?? 'Dữ liệu không hợp lệ',
          'error': 'Validation Error: ${errorData['errors'] ?? response.body}',
          'status_code': 422,
        };
      } else if (response.statusCode >= 500) {
        debugPrint('❌ ChatRepository: Lỗi server ${response.statusCode}');
        return {
          'success': false,
          'message': 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.',
          'error': 'Server Error: ${response.body}',
          'status_code': response.statusCode,
        };
      } else {
        debugPrint(
            '❓ ChatRepository: Lỗi không xác định ${response.statusCode}');
        return {
          'success': false,
          'message': 'Không thể tải lịch sử tin nhắn',
          'error': 'HTTP Error ${response.statusCode}: ${response.body}',
          'status_code': response.statusCode,
        };
      }
    } on SocketException catch (e) {
      debugPrint('🔌 ChatRepository: SocketException: $e');
      return {
        'success': false,
        'message':
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng của bạn.',
        'error': e.toString(),
      };
    } on TimeoutException catch (e) {
      debugPrint('⏱️ ChatRepository: TimeoutException: $e');
      return {
        'success': false,
        'message': 'Kết nối đến máy chủ quá thời gian. Vui lòng thử lại sau.',
        'error': e.toString(),
      };
    } on FormatException catch (e) {
      debugPrint('📋 ChatRepository: FormatException: $e');
      return {
        'success': false,
        'message': 'Lỗi định dạng dữ liệu từ máy chủ.',
        'error': e.toString(),
      };
    } catch (e) {
      debugPrint('❗ ChatRepository: Exception không xác định: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi tải lịch sử tin nhắn',
        'error': e.toString(),
      };
    }
  }

  // Lấy số tin nhắn chưa đọc
  Future<Map<String, dynamic>> getUnreadCount(String token) async {
    try {
      debugPrint('ChatRepository: Đang lấy số tin nhắn chưa đọc');
      final response = await http.get(
        Uri.parse(api_chat_unread),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint(
            'ChatRepository: Số tin nhắn chưa đọc: ${responseData['data']['unread_count']}');
        return {
          'success': true,
          'unreadCount': responseData['data']['unread_count'],
        };
      } else {
        debugPrint(
            'ChatRepository: Lỗi khi lấy số tin nhắn chưa đọc: ${response.body}');
        return {
          'success': false,
          'message': 'Không thể tải số tin nhắn chưa đọc',
          'error': response.body,
        };
      }
    } catch (e) {
      debugPrint('ChatRepository: Exception khi lấy số tin nhắn chưa đọc: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi tải số tin nhắn chưa đọc',
        'error': e.toString(),
      };
    }
  }
}
