import 'dart:convert';
import 'package:shoplite/models/profile.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class ChatMessage {
  final int id;
  final int chatId;
  final int userId;
  final String message;
  final String? attachmentUrl;
  final String? attachmentType;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Thêm thông tin user từ quan hệ với('user')
  final Map<String, dynamic>? user;

  // Thêm thuộc tính từ API mới
  final bool isFromCurrentUser;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.userId,
    required this.message,
    this.attachmentUrl,
    this.attachmentType,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.isFromCurrentUser = false,
  });

  // Lấy tên người gửi từ quan hệ user
  String get senderName {
    if (user == null) return 'Người dùng';

    // Thử các trường khác nhau mà API có thể trả về
    final name = user!['full_name'] ??
        user!['name'] ??
        user!['username'] ??
        user!['email'] ??
        'Người dùng #$userId';

    return name;
  }

  // Chuyển từ JSON từ API sang đối tượng
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw FormatException('Invalid JSON for ChatMessage: null');
    }

    try {
      // Parsing dates
      DateTime parseDateTime(String? dateTimeString) {
        if (dateTimeString == null) {
          return DateTime.now();
        }
        try {
          return DateTime.parse(dateTimeString);
        } catch (e) {
          debugPrint('Error parsing date: $dateTimeString, error: $e');
          return DateTime.now();
        }
      }

      // Xử lý trường hợp trường user là null hoặc không phải map
      Map<String, dynamic>? userMap;
      if (json['user'] != null) {
        try {
          userMap = json['user'] as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Error casting user to Map: ${json['user']}, error: $e');
          userMap = null;
        }
      }

      // API mới có thể trả về isFromCurrentUser
      final bool isFromCurrentUser = json['isFromCurrentUser'] ?? false;

      // Đảm bảo attachmentUrl luôn là đường dẫn đầy đủ
      String? attachmentUrl = json['attachment'];
      if (attachmentUrl != null && attachmentUrl.isNotEmpty) {
        // Nếu URL đã là HTTP thì giữ nguyên
        if (!attachmentUrl.startsWith('http')) {
          // Nếu có domain đầy đủ trong cấu hình
          // attachmentUrl = 'https://yourdomain.com' + attachmentUrl;
          debugPrint(
              '🔄 ChatMessage: Cần đường dẫn đầy đủ cho attachment: $attachmentUrl');
        }
      }

      return ChatMessage(
        id: json['id'] ?? 0,
        chatId: json['chat_id'] ?? 0,
        userId: json['user_id'] ?? 0,
        message: json['message'] ?? '',
        attachmentUrl: attachmentUrl,
        attachmentType: json['attachment_type'],
        isRead: json['is_read'] ?? false,
        createdAt: parseDateTime(json['created_at']),
        updatedAt: parseDateTime(json['updated_at']),
        user: userMap,
        isFromCurrentUser: isFromCurrentUser,
      );
    } catch (e) {
      debugPrint('Error creating ChatMessage from JSON: $e, JSON: $json');
      rethrow;
    }
  }

  // Chuyển đối tượng thành JSON để gửi đi
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'user_id': userId,
      'message': message,
      'attachment': attachmentUrl,
      'attachment_type': attachmentType,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'isFromCurrentUser': isFromCurrentUser,
    };
  }

  // Format thời gian hiển thị đẹp hơn
  String get formattedTime {
    // Điều chỉnh thời gian từ UTC sang múi giờ địa phương
    final localTime = createdAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate =
        DateTime(localTime.year, localTime.month, localTime.day);

    if (messageDate == today) {
      return 'Hôm nay, ${DateFormat('HH:mm').format(localTime)}';
    } else if (messageDate == yesterday) {
      return 'Hôm qua, ${DateFormat('HH:mm').format(localTime)}';
    } else {
      return DateFormat('dd/MM/yyyy, HH:mm').format(localTime);
    }
  }

  // Check if message is from the current user
  bool isMine(int currentUserId) {
    return userId == currentUserId;
  }

  // Check if message has an attachment
  bool get hasAttachment {
    // Kiểm tra kỹ lưỡng hơn
    final hasUrl = attachmentUrl != null &&
        attachmentUrl!.isNotEmpty &&
        attachmentUrl!.contains('.');

    // Thêm log debug để dễ theo dõi
    if (kDebugMode) {
      print(
          '🔍 ChatMessage: Kiểm tra tệp đính kèm ID=${id}, có URL=$hasUrl, loại=${attachmentType ?? "null"}');
    }

    return hasUrl;
  }

  // Get the fixed attachment URL or null if invalid
  String? get processedAttachmentUrl {
    if (attachmentUrl == null || attachmentUrl!.isEmpty) {
      return null;
    }

    String url = attachmentUrl!.trim();

    // Kiểm tra URL có hợp lệ không
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // Thêm schema nếu cần
      if (url.startsWith('//')) {
        url = 'https:$url';
      } else if (!url.contains('://')) {
        url = 'https://$url';
      }
    }

    // Xử lý các URL đặc biệt
    if (url.contains('storage.googleapis.com') && !url.contains('?')) {
      // Thêm timestamp để tránh cache nếu đây là URL của Google Cloud Storage
      url = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    }

    // Log thông tin khi debug
    if (kDebugMode) {
      print('🔍 ChatMessage: URL đính kèm đã xử lý: $url');
    }

    return url;
  }

  // Get attachment type
  bool get isImage {
    final type = attachmentType?.toLowerCase() ?? '';

    // Kiểm tra cả loại file và extension trong URL
    final isImageType = type == 'image';
    final hasImageExt = attachmentUrl != null &&
        (attachmentUrl!.toLowerCase().endsWith('.jpg') ||
            attachmentUrl!.toLowerCase().endsWith('.jpeg') ||
            attachmentUrl!.toLowerCase().endsWith('.png') ||
            attachmentUrl!.toLowerCase().endsWith('.gif') ||
            attachmentUrl!.toLowerCase().endsWith('.webp'));

    if (kDebugMode && attachmentUrl != null) {
      print(
          '🖼️ ChatMessage: Kiểm tra loại hình ảnh ID=${id}: type=$isImageType, ext=$hasImageExt');
    }

    return isImageType || hasImageExt;
  }

  bool get isAudio => attachmentType?.toLowerCase() == 'audio';
  bool get isVideo => attachmentType?.toLowerCase() == 'video';
  bool get isDocument => attachmentType?.toLowerCase() == 'document';
}
