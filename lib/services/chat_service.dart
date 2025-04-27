import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/models/chat.dart';
import 'package:shoplite/models/chat_message.dart';

class ChatService {
  // Singleton pattern
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final Dio _dio = Dio();

  // Get or create a support chat with admin
  Future<Map<String, dynamic>> getOrCreateSupportChat() async {
    try {
      final response = await http.post(
        Uri.parse(api_chat_get_or_create),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $g_token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'chatId': responseData['data']['chat_id'],
        };
      } else {
        return {
          'success': false,
          'message': 'Không thể kết nối với bộ phận hỗ trợ',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  // Send a text message
  Future<Map<String, dynamic>> sendTextMessage(
      int chatId, String message) async {
    try {
      final response = await http.post(
        Uri.parse(api_chat_send),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $g_token',
        },
        body: json.encode({
          'chat_id': chatId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Không thể gửi tin nhắn',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  // Send a message with attachment
  Future<Map<String, dynamic>> sendMessageWithAttachment(
      int chatId, String? message, File attachment) async {
    try {
      FormData formData = FormData.fromMap({
        'chat_id': chatId,
        'message': message ?? '',
        'attachment': await MultipartFile.fromFile(
          attachment.path,
          filename: attachment.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        api_chat_send,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $g_token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Không thể gửi tin nhắn',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  // Get chat history with pagination
  Future<Map<String, dynamic>> getChatHistory(int chatId,
      {int page = 1, int perPage = 20}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$api_chat_history?chat_id=$chatId&page=$page&per_page=$perPage'),
        headers: {
          'Authorization': 'Bearer $g_token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> messagesJson = responseData['data']['messages'];
        final List<ChatMessage> messages =
            messagesJson.map((json) => ChatMessage.fromJson(json)).toList();

        // Sort by created_at in ascending order (oldest to newest)
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        return {
          'success': true,
          'messages': messages,
          'hasMore': responseData['data']['has_more'],
          'nextPage': responseData['data']['next_page'],
          'total': responseData['data']['total'],
        };
      } else {
        return {
          'success': false,
          'message': 'Không thể tải lịch sử tin nhắn',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  // Get unread message count
  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse(api_chat_unread),
        headers: {
          'Authorization': 'Bearer $g_token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'unreadCount': responseData['data']['unread_count'],
        };
      } else {
        return {
          'success': false,
          'message': 'Không thể tải số tin nhắn chưa đọc',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }
}
