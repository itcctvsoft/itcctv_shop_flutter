import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shoplite/models/chat_message.dart';
import 'package:intl/intl.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final Color userColor;
  final Color adminColor;
  final VoidCallback? onImageTap;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.userColor = const Color(0xFF007AFF), // iOS blue for user messages
    this.adminColor = const Color(0xFFE9E9EB), // iOS gray for admin messages
    this.onImageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeController.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) _buildAvatar(isAdmin: true),
              if (!isMe) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: EdgeInsets.all(message.hasAttachment ? 8.0 : 12.0),
                  decoration: BoxDecoration(
                    color: isMe ? userColor : adminColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            message.senderName,
                            style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (message.hasAttachment) ...[
                        _buildAttachment(context),
                        if (message.message.isNotEmpty &&
                            message.message != 'Đã gửi một tập tin đính kèm.')
                          const SizedBox(height: 8),
                      ],
                      if (message.message.isNotEmpty &&
                          message.message != 'Đã gửi một tập tin đính kèm.')
                        Text(
                          message.message,
                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : (isDarkMode ? Colors.white : Colors.black87),
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 8),
              if (isMe) _buildAvatar(isAdmin: false),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4.0,
              left: isMe ? 0 : 40,
              right: isMe ? 40 : 0,
            ),
            child: Text(
              message.formattedTime,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to build avatar
  Widget _buildAvatar({required bool isAdmin}) {
    final avatarImage = isAdmin ? _getAdminAvatar() : _getUserAvatar();

    if (avatarImage != null) {
      // For network images
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: (avatarImage as NetworkImage).url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isAdmin ? Colors.grey[400]! : AppColors.primaryColor,
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Icon(
              isAdmin ? Icons.support_agent : Icons.person,
              color: Colors.grey[700],
              size: 16,
            ),
          ),
        ),
      );
    } else {
      // Default icon when no image is available
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[300],
        child: Icon(
          isAdmin ? Icons.support_agent : Icons.person,
          color: Colors.grey[700],
          size: 16,
        ),
      );
    }
  }

  // Helper method to get user avatar
  ImageProvider? _getUserAvatar() {
    // Kiểm tra nếu có thông tin user trong message
    if (message.user != null &&
        message.user!['photo'] != null &&
        message.user!['photo'].toString().isNotEmpty) {
      String photoUrl = message.user!['photo'].toString();
      if (photoUrl.startsWith('http')) {
        return NetworkImage(photoUrl);
      }
    }

    // Nếu không có ảnh từ tin nhắn, trả về null để hiển thị icon mặc định
    return null;
  }

  // Helper method to get admin avatar
  ImageProvider? _getAdminAvatar() {
    // Check if admin photo is available in message
    if (!isMe &&
        message.user != null &&
        message.user!['photo'] != null &&
        message.user!['photo'].toString().isNotEmpty) {
      String photoUrl = message.user!['photo'].toString();
      if (photoUrl.startsWith('http')) {
        return NetworkImage(photoUrl);
      }
    }

    // Mặc định sử dụng ảnh admin từ assets nếu có
    // return AssetImage('assets/images/shop_admin.png');
    return null; // Trả về null để sử dụng icon mặc định
  }

  Widget _buildAttachment(BuildContext context) {
    final isDarkMode = ThemeController.isDarkMode;

    // Thêm debug log
    debugPrint(
        '🖼️ Chat: Hiển thị tệp đính kèm - Loại: ${message.attachmentType}');

    // Lấy URL đã qua xử lý từ model
    final processedUrl = message.processedAttachmentUrl;

    if (processedUrl != null) {
      debugPrint('🔗 Chat: URL đính kèm đã xử lý: $processedUrl');
    } else {
      debugPrint('⚠️ Chat: Không có URL đính kèm hợp lệ');
    }

    if (message.attachmentType == 'image' ||
        (processedUrl != null &&
            (processedUrl.toLowerCase().endsWith('.jpg') ||
                processedUrl.toLowerCase().endsWith('.jpeg') ||
                processedUrl.toLowerCase().endsWith('.png') ||
                processedUrl.toLowerCase().endsWith('.gif') ||
                processedUrl.toLowerCase().endsWith('.webp')))) {
      // Kiểm tra URL có hợp lệ không
      if (processedUrl == null) {
        debugPrint('❌ Chat: URL hình ảnh không hợp lệ');
        return _buildErrorAttachment('Hình ảnh không khả dụng');
      }

      debugPrint('✅ Chat: Đang tải hình ảnh: $processedUrl');

      // URL đã được xử lý trong model
      String imageUrl = processedUrl;

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: onImageTap,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: double.infinity,
            fit: BoxFit.cover,
            maxHeightDiskCache: 300, // Giới hạn kích thước cache
            memCacheHeight: 300, // Giới hạn kích thước bộ nhớ cache

            // Thêm HTTP header nếu cần
            httpHeaders: const {
              'Accept': 'image/jpeg,image/png,image/jpg,image/*',
              'Cache-Control': 'max-age=3600',
            },

            // Thêm tùy chọn retry cho việc tải hình ảnh
            fadeOutDuration: const Duration(milliseconds: 300),
            fadeInDuration: const Duration(milliseconds: 700),

            placeholder: (context, url) => Container(
              height: 150,
              color: isDarkMode
                  ? Colors.grey[800]!.withOpacity(0.3)
                  : Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isMe ? Colors.white70 : AppColors.primaryColor,
                      ),
                      strokeWidth: 2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đang tải...',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            errorWidget: (context, url, error) {
              debugPrint('❌ Chat: Lỗi tải hình ảnh: $error');
              return _buildErrorAttachment('Không thể tải hình ảnh');
            },
          ),
        ),
      );
    } else if (message.attachmentType == 'video') {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.video_file,
                size: 50, color: Colors.white.withOpacity(0.7)),
            Positioned(
              bottom: 8,
              left: 8,
              child: Text(
                'Video',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onImageTap,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (message.attachmentType == 'audio') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.grey[800]!.withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.audiotrack,
                color: isMe ? Colors.white : AppColors.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tin nhắn thoại',
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : (isDarkMode ? Colors.white : Colors.black),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.play_arrow,
                  color: isMe ? Colors.white : AppColors.primaryColor),
              onPressed: onImageTap,
            ),
          ],
        ),
      );
    } else {
      // Document or general attachment
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.grey[800]!.withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.insert_drive_file,
                color: isMe ? Colors.white : AppColors.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tập tin đính kèm',
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : (isDarkMode ? Colors.white : Colors.black),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.download,
                  color: isMe ? Colors.white : AppColors.primaryColor),
              onPressed: onImageTap,
            ),
          ],
        ),
      );
    }
  }

  // Widget hiển thị lỗi tệp đính kèm
  Widget _buildErrorAttachment(String errorMessage) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ThemeController.isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeController.isDarkMode
              ? Colors.grey[700]!
              : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage,
            style: TextStyle(
              color: ThemeController.isDarkMode
                  ? Colors.white70
                  : Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (onImageTap != null)
            TextButton.icon(
              onPressed: onImageTap,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Tải lại'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
