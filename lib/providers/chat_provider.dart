import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/constants/pref_data.dart';
import 'package:shoplite/models/chat_message.dart';
import 'package:shoplite/repositories/chat_repository.dart';

// Provider để quản lý số tin nhắn chưa đọc
final unreadMessagesProvider =
    StateNotifierProvider<UnreadMessagesNotifier, int>((ref) {
  return UnreadMessagesNotifier();
});

class UnreadMessagesNotifier extends StateNotifier<int> {
  UnreadMessagesNotifier() : super(0) {
    // Khởi tạo với việc lấy số tin nhắn chưa đọc
    _initUnreadCount();
    // Thiết lập timer để định kỳ kiểm tra tin nhắn mới
    _setupPollingTimer();
  }

  Timer? _pollingTimer;
  final ChatRepository _chatRepository = ChatRepository();
  bool _isInitialized = false;

  // Khởi tạo số tin nhắn chưa đọc
  Future<void> _initUnreadCount() async {
    if (_isInitialized) return;

    final token = await PrefData.getToken();
    if (token == null || token.isEmpty) return;

    try {
      final result = await _chatRepository.getUnreadCount(token);
      if (result['success']) {
        state = result['unreadCount'];
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Lỗi khi khởi tạo số tin nhắn chưa đọc: $e');
    }
  }

  // Thiết lập timer để định kỳ kiểm tra tin nhắn mới
  void _setupPollingTimer() {
    // Kiểm tra mỗi 15 giây
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await refreshUnreadCount();
    });
  }

  // Làm mới số tin nhắn chưa đọc
  Future<void> refreshUnreadCount() async {
    final token = await PrefData.getToken();
    if (token == null || token.isEmpty) return;

    try {
      final result = await _chatRepository.getUnreadCount(token);
      if (result['success']) {
        state = result['unreadCount'];
      }
    } catch (e) {
      debugPrint('Lỗi khi làm mới số tin nhắn chưa đọc: $e');
    }
  }

  // Đặt số tin nhắn chưa đọc về 0
  void resetUnreadCount() {
    state = 0;
  }

  // Hủy timer khi không cần thiết nữa
  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

// Provider để quản lý trạng thái chat (loading, error, success)
final chatStateProvider = StateProvider<String>((ref) => 'initial');

// Provider để quản lý thông báo lỗi
final chatErrorProvider = StateProvider<String?>((ref) => null);

// Provider để quản lý danh sách tin nhắn
final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier(ref);
});

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier(this.ref) : super([]) {
    // Khởi tạo với giá trị mặc định
    _loadingStateGuard();
  }

  final Ref ref;
  final ChatRepository _chatRepository = ChatRepository();
  int? _chatId;
  bool _hasMore = false;
  int _currentPage = 1;
  bool _isLoading = false;
  Timer? _refreshTimer;
  Timer? _loadingTimeoutTimer; // Timer mới để theo dõi quá trình loading

  // Thêm các hằng số để quản lý cache
  static const String _cacheKey = 'chat_messages_cache';
  static const Duration _cacheValidityDuration = Duration(hours: 12);

  // Giới hạn thời gian tối đa cho việc loading (25 giây)
  final _maxLoadingTime = Duration(seconds: 25);

  // Đảm bảo _isLoading luôn được đặt về false sau một khoảng thời gian
  void _loadingStateGuard() {
    // Khởi tạo một bộ đếm thời gian an toàn, đảm bảo không bao giờ bị treo ở loading vô tận
    Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isLoading) {
        debugPrint('⚡ ChatProvider: GUARD - Force reset loading state');
        _isLoading = false;
        ref.read(chatStateProvider.notifier).state = 'error';
        ref.read(chatErrorProvider.notifier).state =
            'Quá trình tải dữ liệu quá lâu, vui lòng thử lại.';
      }
    });
  }

  // Getters
  bool get hasMore => _hasMore;
  int? get chatId => _chatId;
  bool get isLoading => _isLoading;

  // Khởi tạo timer để định kỳ tải tin nhắn mới
  void _setupRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_isLoading) {
        _refreshMessages();
      }
    });
  }

  // Hủy timer khi không cần thiết nữa
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _loadingTimeoutTimer?.cancel();
    super.dispose();
  }

  // Reset trạng thái chat để bắt đầu lại
  void resetState() {
    debugPrint('🔄 ChatProvider: Reset trạng thái chat');

    // Force hủy bỏ tất cả các operation đang chạy
    _loadingTimeoutTimer?.cancel();

    // Force reset loading state ngay lập tức
    _isLoading = false;

    // Reset trạng thái UI
    ref.read(chatStateProvider.notifier).state = 'initial';
    ref.read(chatErrorProvider.notifier).state = null;

    // Reset pagination
    _hasMore = false;
    _currentPage = 1;

    // Không reset _chatId để giữ cuộc trò chuyện

    // Đặt lại thời gian timeout mới cho lần chạy tiếp theo
    _loadingTimeoutTimer = Timer(_maxLoadingTime, () {
      debugPrint('⏱️ ChatProvider: Timeout timer after resetState');
      if (_isLoading) {
        _isLoading = false;
        ref.read(chatErrorProvider.notifier).state =
            "Quá thời gian chờ phản hồi từ máy chủ. Vui lòng thử lại.";
        ref.read(chatStateProvider.notifier).state = 'error';
      }
    });
  }

  // Làm mới tin nhắn mà không thay đổi trạng thái UI
  Future<void> _refreshMessages() async {
    if (_chatId == null) return;

    final token = await PrefData.getToken();
    if (token == null || token.isEmpty) return;

    try {
      final result = await _chatRepository.getChatHistory(token, _chatId!,
          page: 1, perPage: 20);
      if (result['success'] && result['messages'] != null) {
        final newMessages = List<ChatMessage>.from(result['messages']);

        if (newMessages.isNotEmpty) {
          // Kiểm tra xem có tin nhắn mới không
          if (state.isEmpty || newMessages.first.id != state.first.id) {
            // Cập nhật danh sách tin nhắn
            state = newMessages;
            // Đặt số tin nhắn chưa đọc về 0
            ref.read(unreadMessagesProvider.notifier).resetUnreadCount();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ ChatProvider: Lỗi khi làm mới tin nhắn: $e');
    }
  }

  // Khởi tạo hoặc lấy cuộc trò chuyện
  Future<void> initChat() async {
    if (_isLoading) {
      debugPrint('⚠️ ChatProvider: Đang tải, bỏ qua yêu cầu initChat mới');
      return;
    }

    debugPrint('🚀 ChatProvider: Bắt đầu khởi tạo chat...');
    _isLoading = true;
    ref.read(chatStateProvider.notifier).state = 'loading';

    // Tạo một timeout để tránh treo vô tận
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = Timer(_maxLoadingTime, () {
      debugPrint(
          '⏱️ ChatProvider: initChat timeout sau ${_maxLoadingTime.inSeconds} giây');
      if (_isLoading) {
        _isLoading = false;
        ref.read(chatErrorProvider.notifier).state =
            "Quá thời gian chờ phản hồi từ máy chủ. Vui lòng thử lại.";
        ref.read(chatStateProvider.notifier).state = 'error';
      }
    });

    // Đặt lại trạng thái sau khoảng thời gian tối đa bất kể kết quả
    Future.delayed(_maxLoadingTime + Duration(seconds: 5), () {
      if (_isLoading) {
        debugPrint('⚠️ ChatProvider: Force reset loading state after max time');
        _isLoading = false;
      }
    });

    // Xử lý khởi tạo chat trong try-catch-finally
    try {
      final token = await PrefData.getToken();
      if (token == null || token.isEmpty) {
        throw Exception("Token không hợp lệ");
      }

      debugPrint('🔄 ChatProvider: Gọi API getOrCreateSupportChat...');

      // Đặt timeout cho API call
      final result = await _chatRepository
          .getOrCreateSupportChat(token)
          .timeout(Duration(seconds: 15), onTimeout: () {
        throw TimeoutException(
            'Kết nối đến máy chủ quá thời gian. Vui lòng thử lại sau.');
      });

      // Kiểm tra kết quả trả về
      if (!result['success']) {
        throw Exception(result['message'] ?? 'Lỗi khi khởi tạo chat');
      }

      // Nếu thành công, cập nhật chat ID
      _chatId = result['chatId'];
      debugPrint('✅ ChatProvider: Khởi tạo chat thành công, chatId=$_chatId');

      // Tải tin nhắn
      await loadMessages();

      // Thiết lập timer để định kỳ tải tin nhắn mới
      _setupRefreshTimer();
    } catch (e) {
      // Xử lý lỗi
      debugPrint('❌ ChatProvider: Exception khi khởi tạo chat: $e');
      String errorMessage = "Lỗi kết nối: ${e.toString()}";

      if (e is SocketException) {
        errorMessage =
            "Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng của bạn.";
      } else if (e is TimeoutException) {
        errorMessage =
            "Kết nối đến máy chủ quá thời gian. Vui lòng thử lại sau.";
      }

      ref.read(chatErrorProvider.notifier).state = errorMessage;
      ref.read(chatStateProvider.notifier).state = 'error';
    } finally {
      // Đảm bảo luôn reset loading state và hủy timer
      _isLoading = false;
      _loadingTimeoutTimer?.cancel();
      debugPrint('🏁 ChatProvider: Kết thúc quá trình khởi tạo chat');
    }
  }

  // Thêm phương thức để tải tin nhắn từ cache
  Future<bool> loadCachedMessages() async {
    try {
      debugPrint('🔍 ChatProvider: Đang tìm tin nhắn trong cache...');

      // Tải tin nhắn từ SharedPreferences
      final prefs = await PrefData.getPrefInstance();
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData == null || cachedData.isEmpty) {
        debugPrint('❌ ChatProvider: Không tìm thấy tin nhắn trong cache');
        return false;
      }

      // Parse dữ liệu cache
      final cacheMap = json.decode(cachedData) as Map<String, dynamic>;

      // Kiểm tra thời gian cache có hợp lệ không
      final cachedTime = DateTime.parse(cacheMap['timestamp']);
      final now = DateTime.now();

      if (now.difference(cachedTime) > _cacheValidityDuration) {
        debugPrint('⚠️ ChatProvider: Cache đã hết hạn, cần làm mới');
        return false;
      }

      // Tải chat_id từ cache
      _chatId = cacheMap['chat_id'];

      // Parse và tạo danh sách tin nhắn từ cache
      final List<dynamic> messagesJson = cacheMap['messages'];
      if (messagesJson.isEmpty) {
        debugPrint('ℹ️ ChatProvider: Cache rỗng, không có tin nhắn');
        return false;
      }

      try {
        final messages =
            messagesJson.map((json) => ChatMessage.fromJson(json)).toList();

        // Cập nhật state với tin nhắn từ cache
        state = messages;

        debugPrint(
            '✅ ChatProvider: Đã tải ${messages.length} tin nhắn từ cache');
        return true;
      } catch (e) {
        debugPrint('❌ ChatProvider: Lỗi khi parse tin nhắn từ cache: $e');
        return false;
      }
    } catch (e) {
      debugPrint('❌ ChatProvider: Lỗi khi tải tin nhắn từ cache: $e');
      return false;
    }
  }

  // Thêm phương thức để lưu tin nhắn vào cache
  Future<void> _saveChatMessagesToCache() async {
    try {
      // Chỉ lưu vào cache nếu có tin nhắn và chat_id hợp lệ
      if (state.isEmpty || _chatId == null) {
        debugPrint('ℹ️ ChatProvider: Không có tin nhắn để lưu vào cache');
        return;
      }

      // Tạo dữ liệu cache
      final cacheMap = {
        'timestamp': DateTime.now().toIso8601String(),
        'chat_id': _chatId,
        'messages': state.map((msg) => msg.toJson()).toList(),
      };

      // Lưu vào SharedPreferences
      final prefs = await PrefData.getPrefInstance();
      final cacheString = json.encode(cacheMap);
      await prefs.setString(_cacheKey, cacheString);

      debugPrint('✅ ChatProvider: Đã lưu ${state.length} tin nhắn vào cache');
    } catch (e) {
      debugPrint('❌ ChatProvider: Lỗi khi lưu tin nhắn vào cache: $e');
    }
  }

  // Tải tin nhắn từ server với retry
  Future<void> loadMessages() async {
    if (_isLoading) {
      debugPrint('⚠️ ChatProvider: Đang tải, bỏ qua yêu cầu loadMessages mới');
      return;
    }

    _isLoading = true;
    ref.read(chatStateProvider.notifier).state = 'loading';

    // Thiết lập timer timeout
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = Timer(_maxLoadingTime, () {
      if (_isLoading) {
        debugPrint('⏱️ ChatProvider: Timeout khi tải tin nhắn');
        _isLoading = false;
        ref.read(chatErrorProvider.notifier).state =
            "Quá thời gian chờ phản hồi từ máy chủ. Vui lòng thử lại.";
        ref.read(chatStateProvider.notifier).state = 'error';
      }
    });

    try {
      final token = await PrefData.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Không tìm thấy token. Vui lòng đăng nhập lại.');
      }

      // Tìm cuộc trò chuyện hỗ trợ hoặc tạo mới nếu chưa có
      if (_chatId == null) {
        final result = await _chatRepository.getOrCreateSupportChat(token);
        if (!result['success']) {
          throw Exception(result['message']);
        }
        _chatId = result['chatId'];

        if (_chatId == null) {
          throw Exception('Không tìm thấy hoặc không thể tạo cuộc trò chuyện');
        }
      }

      // Tải lịch sử tin nhắn
      final result = await _chatRepository.getChatHistory(
        token,
        _chatId!,
        page: 1,
        perPage: 20,
      );

      if (!result['success']) {
        throw Exception(result['message']);
      }

      // Xử lý tin nhắn
      final messagesCount =
          result['messages'] != null ? (result['messages'] as List).length : 0;
      debugPrint(
          '✅ ChatProvider: Tải tin nhắn thành công, số lượng: $messagesCount');

      // Lưu các thông tin phân trang
      _hasMore = result['hasMore'] ?? false;
      _currentPage =
          result['nextPage'] != null ? 1 : 1; // Reset page nếu là tải mới
      debugPrint('📊 ChatProvider: hasMore=$_hasMore, nextPage=$_currentPage');

      // Cập nhật state
      if (messagesCount == 0) {
        // Nếu không có tin nhắn, trả về một danh sách rỗng
        debugPrint('ℹ️ ChatProvider: Không có tin nhắn để hiển thị');
        state = [];
      } else {
        try {
          // API trả về tin nhắn xếp từ mới đến cũ
          final messages = List<ChatMessage>.from(result['messages']);
          state = messages;
          debugPrint(
              '✅ ChatProvider: Đã cập nhật ${messages.length} tin nhắn vào state');

          // Lưu tin nhắn vào cache sau khi tải thành công
          _saveChatMessagesToCache();
        } catch (parseError) {
          debugPrint('❌ ChatProvider: Lỗi khi xử lý tin nhắn: $parseError');
          throw Exception("Lỗi khi xử lý dữ liệu tin nhắn: $parseError");
        }
      }

      // Cập nhật trạng thái thành công
      ref.read(chatStateProvider.notifier).state = 'success';
    } catch (e) {
      // Xử lý lỗi
      debugPrint('❌ ChatProvider: Exception khi tải tin nhắn: $e');
      String errorMessage = "Lỗi tải tin nhắn: ${e.toString()}";

      if (!e.toString().contains("token")) {
        errorMessage = "Không thể kết nối đến máy chủ. Vui lòng thử lại sau.";
      }

      ref.read(chatErrorProvider.notifier).state = errorMessage;
      ref.read(chatStateProvider.notifier).state = 'error';
    } finally {
      // Huỷ timer timeout và reset trạng thái loading
      _loadingTimeoutTimer?.cancel();
      _isLoading = false;
    }
  }

  // Tải thêm tin nhắn cũ hơn
  Future<void> loadMoreMessages() async {
    if (_isLoading) return;

    // Kiểm tra chat_id và hasMore
    if (!_hasMore) {
      debugPrint('ChatProvider: Không còn tin nhắn cũ hơn để tải');
      return;
    }

    _isLoading = true;

    final token = await PrefData.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('ChatProvider: Token không hợp lệ khi tải thêm tin nhắn');
      _isLoading = false;
      return;
    }

    // Đảm bảo có chat_id
    if (_chatId == null) {
      debugPrint(
          'ChatProvider: Không có chat_id khi tải thêm tin nhắn, đang khởi tạo...');
      try {
        final result = await _chatRepository.getOrCreateSupportChat(token);
        if (result['success']) {
          _chatId = result['chatId'];
          debugPrint('ChatProvider: Đã khởi tạo chat mới, chatId=$_chatId');
        } else {
          debugPrint(
              'ChatProvider: Không thể khởi tạo chat khi tải thêm: ${result['message']}');
          _isLoading = false;
          return;
        }
      } catch (e) {
        debugPrint('ChatProvider: Lỗi khi khởi tạo chat: $e');
        _isLoading = false;
        return;
      }
    }

    try {
      final nextPage = _currentPage + 1;
      debugPrint(
          'ChatProvider: Đang tải thêm tin nhắn, trang $nextPage cho chatId=$_chatId');

      final result = await _chatRepository.getChatHistory(
        token,
        _chatId!,
        page: nextPage,
        perPage: 20,
      );

      if (result['success']) {
        debugPrint('ChatProvider: Tải thêm tin nhắn thành công');
        final oldMessages = List<ChatMessage>.from(result['messages']);

        if (oldMessages.isEmpty) {
          debugPrint('ChatProvider: Không còn tin nhắn cũ hơn');
          _hasMore = false;
        } else {
          // Cập nhật state với tin nhắn cũ được nối vào danh sách hiện tại
          state = [...state, ...oldMessages];

          _hasMore = result['hasMore'] ?? false;
          _currentPage = result['nextPage'] != null ? nextPage : _currentPage;

          debugPrint(
              'ChatProvider: Đã tải thêm ${oldMessages.length} tin nhắn, tổng cộng ${state.length} tin nhắn');
        }
      } else {
        debugPrint(
            'ChatProvider: Lỗi khi tải thêm tin nhắn: ${result['message']}');
      }
    } catch (e) {
      debugPrint('ChatProvider: Lỗi khi tải thêm tin nhắn: $e');
    } finally {
      _isLoading = false;
    }
  }

  // Cập nhật phương thức gửi tin nhắn để lưu vào cache sau khi gửi thành công
  Future<bool> sendMessage(String message, {String? userPhotoUrl}) async {
    if (_chatId == null || message.trim().isEmpty) return false;

    final token = await PrefData.getToken();
    if (token == null || token.isEmpty) return false;

    try {
      // Nếu có userPhotoUrl, tạo một user object để đính kèm vào tin nhắn
      Map<String, dynamic>? userInfo;
      if (userPhotoUrl != null && userPhotoUrl.isNotEmpty) {
        userInfo = {
          'photo': userPhotoUrl,
        };
      }

      final result = await _chatRepository.sendTextMessage(
        token,
        _chatId!,
        message,
        userInfo: userInfo,
      );

      if (result['success']) {
        await loadMessages();
        return true;
      } else {
        debugPrint('ChatProvider: Lỗi khi gửi tin nhắn: ${result['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('Lỗi khi gửi tin nhắn: $e');
      return false;
    }
  }

  // Cập nhật phương thức gửi tin nhắn có đính kèm để lưu vào cache sau khi gửi thành công
  Future<bool> sendMessageWithAttachment(String? message, File attachment,
      {String? userPhotoUrl}) async {
    if (_chatId == null) return false;

    final token = await PrefData.getToken();
    if (token == null || token.isEmpty) return false;

    try {
      debugPrint(
          '📤 ChatProvider: Gửi tin nhắn có đính kèm tới chatId=$_chatId');
      if (message != null && message.isNotEmpty) {
        debugPrint('📤 ChatProvider: Với nội dung: "$message"');
      }
      debugPrint('📤 ChatProvider: Đường dẫn file: ${attachment.path}');

      // Kiểm tra kích thước file, nếu quá lớn thì resize
      final fileSize = await attachment.length();
      debugPrint(
          '📤 ChatProvider: Kích thước file: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // Nếu là hình ảnh và kích thước quá lớn, thử gửi dưới dạng base64
      final fileName = attachment.path.split('/').last.toLowerCase();
      final isImage = fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg') ||
          fileName.endsWith('.png') ||
          fileName.endsWith('.gif') ||
          fileName.endsWith('.webp');

      final shouldUseBase64 =
          isImage && fileSize > 1024 * 1024 * 2; // Nếu lớn hơn 2MB

      // Nếu có userPhotoUrl, tạo một user object để đính kèm vào tin nhắn
      Map<String, dynamic>? userInfo;
      if (userPhotoUrl != null && userPhotoUrl.isNotEmpty) {
        userInfo = {
          'photo': userPhotoUrl,
        };
      }

      Map<String, dynamic> result;

      if (shouldUseBase64) {
        // Đọc file dưới dạng base64
        final bytes = await attachment.readAsBytes();
        final base64Image = base64Encode(bytes);

        debugPrint(
            '📤 ChatProvider: Gửi hình ảnh dưới dạng base64, độ dài: ${base64Image.length} ký tự');

        result = await _chatRepository.sendImageBase64(
            token, _chatId!, message, base64Image, fileName,
            userInfo: userInfo);
      } else {
        // Gửi file đính kèm bình thường
        result = await _chatRepository.sendMessageWithAttachment(
          token,
          _chatId!,
          message,
          attachment,
          userInfo: userInfo,
        );
      }

      if (result['success']) {
        debugPrint('✅ ChatProvider: Gửi tin nhắn đính kèm thành công');
        await loadMessages();
        return true;
      } else {
        debugPrint(
            '❌ ChatProvider: Lỗi khi gửi tin nhắn đính kèm: ${result['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ ChatProvider: Exception khi gửi tin nhắn đính kèm: $e');
      return false;
    }
  }

  // Gửi hình ảnh base64 riêng (không sử dụng File)
  Future<bool> sendBase64Image(
      String? message, String base64Image, String imageName) async {
    if (_chatId == null) return false;

    final token = await PrefData.getToken();
    if (token == null || token.isEmpty) return false;

    try {
      debugPrint('📤 ChatProvider: Gửi hình ảnh base64 tới chatId=$_chatId');
      if (message != null && message.isNotEmpty) {
        debugPrint('📤 ChatProvider: Với nội dung: "$message"');
      }

      final result = await _chatRepository.sendImageBase64(
          token, _chatId!, message, base64Image, imageName);

      if (result['success']) {
        debugPrint('✅ ChatProvider: Gửi hình ảnh base64 thành công');
        await loadMessages();
        return true;
      } else {
        debugPrint(
            '❌ ChatProvider: Lỗi khi gửi hình ảnh base64: ${result['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ ChatProvider: Exception khi gửi hình ảnh base64: $e');
      return false;
    }
  }
}
