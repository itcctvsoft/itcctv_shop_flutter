import 'dart:io';
import 'dart:async'; // Thêm import cho TimeoutException
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/models/chat_message.dart';
import 'package:shoplite/providers/chat_provider.dart';
import 'package:shoplite/widgets/chat_bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:shoplite/constants/pref_data.dart';

// Phương thức dùng để kiểm tra xem provider có phương thức này không
// Nếu không, tạo phương thức giả định cho việc tải tin nhắn từ cache
extension ChatMessagesExtension on ChatMessagesNotifier {
  Future<bool> loadCachedMessages() async {
    // Kiểm tra xem provider đã có sẵn phương thức loadCachedMessages chưa
    try {
      // Trả về false nếu không có tin nhắn cache
      return false;
    } catch (e) {
      return false;
    }
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isSending = false;
  bool _isLoadingMore = false;
  int? _currentUserId;
  String? _userPhotoUrl;

  // Animators
  late AnimationController _typingAnimationController;
  late AnimationController _sendButtonAnimationController;
  late Animation<double> _sendButtonScaleAnimation;
  bool _showScrollToBottom = false;

  // Thêm biến thành viên để theo dõi số lượng tin nhắn trước đó
  int _previousMessageCount = 0;

  // Sử dụng biến này để kiểm soát retry và hiển thị các tin nhắn cached
  bool _hasCachedMessages = false;
  bool _isLoadingFromCache = false;

  // Thêm biến để theo dõi timer
  Timer? _autoRefreshTimer;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _scrollController.addListener(_scrollListener);

    // Khởi tạo chat khi vào màn hình
    _initChat();
  }

  void _initAnimations() {
    // Animation cho nút gửi
    _sendButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _sendButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _sendButtonAnimationController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    // Animation cho hiệu ứng đang nhập
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  // Phương thức khởi tạo chat với cải tiến
  Future<void> _initChat() async {
    debugPrint('🚀 ChatScreen: Bắt đầu khởi tạo chat...');

    // Tải thông tin user trước
    await _loadUserInfo();

    // Đặt lại số tin nhắn chưa đọc ngay lập tức
    if (mounted) {
      ref.read(unreadMessagesProvider.notifier).resetUnreadCount();
    }

    // Hiển thị loading và thử tải tin nhắn từ cache trước
    setState(() {
      _isLoadingFromCache = true;
    });

    if (mounted) {
      ref.read(chatStateProvider.notifier).state = 'loading';
    }

    // Thử tải tin nhắn từ cache trước
    final hasCachedMessages = await _loadCachedMessages();

    if (!mounted) return;

    if (hasCachedMessages) {
      // Nếu có tin nhắn trong cache, hiển thị ngay lập tức
      ref.read(chatStateProvider.notifier).state = 'success';

      // Cuộn xuống tin nhắn mới nhất
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Không hiển thị thông báo nữa
    }

    // Tải tin nhắn mới từ server (bất kể có cache hay không)
    _fetchMessagesFromServer();

    // Thiết lập timer tự động làm mới tin nhắn
    _setupAutoRefresh();
  }

  // Tải tin nhắn từ cache
  Future<bool> _loadCachedMessages() async {
    try {
      setState(() {
        _isLoadingFromCache = true;
      });

      // Gọi phương thức tải tin nhắn từ cache trong provider
      final success =
          await ref.read(chatMessagesProvider.notifier).loadCachedMessages();

      if (success && mounted) {
        _hasCachedMessages = true;
        debugPrint('✅ ChatScreen: Đã tải tin nhắn từ cache thành công');

        // Đảm bảo không có thông báo snackbar nào đang hiển thị
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ ChatScreen: Lỗi khi tải tin nhắn từ cache: $e');
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFromCache = false;
        });
      }
    }
  }

  // Tải tin nhắn từ server với retry
  Future<void> _fetchMessagesFromServer() async {
    if (!mounted) return;

    // Ẩn mọi thông báo hiện tại
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    // Đặt timeout dài hơn để tránh lỗi khi mạng chậm
    const timeout = Duration(seconds: 20);
    int retryCount = 0;
    const maxRetries = 2;

    // Đảm bảo không hiển thị loading nếu đã có tin nhắn trong cache
    if (!_hasCachedMessages && mounted) {
      ref.read(chatStateProvider.notifier).state = 'loading';
    }

    Future<void> attemptFetchMessages() async {
      try {
        // Gọi API để tải tin nhắn với timeout
        await ref
            .read(chatMessagesProvider.notifier)
            .loadMessages()
            .timeout(timeout, onTimeout: () {
          throw TimeoutException('Quá thời gian kết nối');
        });

        // Nếu thành công, cập nhật UI
        if (mounted) {
          ref.read(chatStateProvider.notifier).state = 'success';

          // Ẩn mọi thông báo đang hiển thị
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          // Cuộn xuống tin nhắn mới nhất nếu cần
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_isNearBottom() || _hasCachedMessages) {
              _scrollToBottom();
            }
          });
        }
      } catch (e) {
        debugPrint('❌ ChatScreen: Lỗi khi tải tin nhắn: $e');

        if (mounted) {
          // Nếu đã có tin nhắn từ cache, không hiển thị lỗi
          if (_hasCachedMessages) {
            // Không hiển thị thông báo nào khi có lỗi làm mới tin nhắn
            debugPrint('ℹ️ ChatScreen: Sử dụng tin nhắn từ cache, bỏ qua lỗi');

            // Ẩn mọi thông báo đang hiển thị
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          } else if (retryCount < maxRetries) {
            // Thử lại nếu chưa có cache và còn lượt retry
            retryCount++;
            debugPrint('🔄 ChatScreen: Đang thử lại lần $retryCount...');

            // Hiển thị thông báo đang retry
            if (!_hasCachedMessages) {
              ref.read(chatErrorProvider.notifier).state =
                  'Đang kết nối lại...';
            }

            // Đợi một chút trước khi thử lại
            await Future.delayed(Duration(seconds: 1));
            return attemptFetchMessages();
          } else {
            // Hết lượt retry và không có cache
            if (!_hasCachedMessages) {
              ref.read(chatStateProvider.notifier).state = 'error';
              ref.read(chatErrorProvider.notifier).state =
                  'Không thể kết nối đến máy chủ. Vui lòng thử lại sau.';
            }
          }
        }
      }
    }

    // Bắt đầu tải tin nhắn
    await attemptFetchMessages();
  }

  // Thiết lập timer để tự động làm mới tin nhắn
  void _setupAutoRefresh() {
    // Hủy timer cũ nếu có
    _autoRefreshTimer?.cancel();

    // Tạo timer mới để làm mới tin nhắn mỗi 10 giây
    _autoRefreshTimer = Timer.periodic(Duration(seconds: 10), (_) {
      _refreshMessagesQuietly();
    });

    debugPrint(
        '🔄 ChatScreen: Đã thiết lập tự động làm mới tin nhắn mỗi 10 giây');
  }

  // Làm mới tin nhắn mà không hiển thị trạng thái loading
  Future<void> _refreshMessagesQuietly() async {
    if (!mounted) return;

    try {
      debugPrint('🔄 ChatScreen: Đang tự động làm mới tin nhắn...');

      // Ẩn mọi notification hiện tại
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      // Lấy độ dài tin nhắn hiện tại để so sánh sau
      final currentMessages = ref.read(chatMessagesProvider);
      final prevMessageCount = currentMessages.length;

      // Lưu trạng thái hiện tại để khôi phục sau
      final currentChatState = ref.read(chatStateProvider);

      // Lưu lại các trạng thái cần khôi phục sau khi tải xong
      final wasLoading = ref.read(chatMessagesProvider.notifier).isLoading;

      try {
        // Gọi API để tải tin nhắn mới
        await ref.read(chatMessagesProvider.notifier).loadMessages();
      } finally {
        // Luôn khôi phục trạng thái UI sau khi tải xong, bất kể thành công hay thất bại
        if (mounted && currentChatState == 'success') {
          // Đảm bảo không hiển thị trạng thái loading
          ref.read(chatStateProvider.notifier).state = currentChatState;
        }
      }

      // Nếu chưa bị dispose, xử lý tin nhắn mới
      if (mounted) {
        // Lấy danh sách tin nhắn sau khi làm mới
        final newMessages = ref.read(chatMessagesProvider);

        // Kiểm tra có tin nhắn mới không
        if (newMessages.length > prevMessageCount) {
          debugPrint(
              '🎉 ChatScreen: Tìm thấy ${newMessages.length - prevMessageCount} tin nhắn mới');

          // Cập nhật biến theo dõi số lượng tin nhắn
          _previousMessageCount = newMessages.length;

          // Nếu người dùng đang ở cuối danh sách, tự động cuộn xuống
          if (_isNearBottom()) {
            _scrollToBottom();
          }
          // Loại bỏ hiển thị thông báo có tin nhắn mới
        } else {
          debugPrint('ℹ️ ChatScreen: Không có tin nhắn mới');
        }
      }
    } catch (e) {
      // Không hiển thị lỗi UI khi làm mới tự động
      debugPrint('❌ ChatScreen: Lỗi khi tự động làm mới: $e');
    }
  }

  // Kiểm tra xem người dùng có đang ở gần cuối danh sách không
  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;

    final double currentPosition = _scrollController.position.pixels;
    final double maxPosition = _scrollController.position.maxScrollExtent;

    // Nếu vị trí hiện tại cách cuối danh sách không quá 100 pixels
    return (maxPosition - currentPosition) < 100;
  }

  // Hiển thị thông báo có tin nhắn mới
  void _showNewMessageNotification() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.message, color: Colors.white),
            SizedBox(width: 12),
            Text('Có tin nhắn mới'),
          ],
        ),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 70, left: 20, right: 20),
        action: SnackBarAction(
          label: 'Xem',
          onPressed: _scrollToBottom,
        ),
      ),
    );
  }

  Future<void> _loadUserInfo() async {
    try {
      final profile = await PrefData.getProfile();
      if (profile != null && mounted) {
        setState(() {
          _currentUserId = -99;
          _userPhotoUrl = profile.photo;
        });
        print(
            "Debug: Loaded user info, ID = $_currentUserId, Photo = $_userPhotoUrl");
      } else {
        print("Debug: Không tìm thấy profile người dùng");
      }
    } catch (e) {
      print("Debug: Lỗi khi tải thông tin người dùng: $e");
    }
  }

  void _scrollListener() {
    // Xử lý tải thêm tin nhắn khi cuộn đến đầu
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoadingMore) {
      final provider = ref.read(chatMessagesProvider.notifier);
      if (provider.hasMore) {
        setState(() {
          _isLoadingMore = true;
        });

        provider.loadMoreMessages().then((_) {
          setState(() {
            _isLoadingMore = false;
          });
        });
      }
    }

    // Hiển thị nút cuộn xuống khi người dùng cuộn lên
    final currentOffset = _scrollController.position.pixels;
    final maxOffset = _scrollController.position.maxScrollExtent;

    setState(() {
      _showScrollToBottom = currentOffset < maxOffset - 300;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // Hàm xử lý khi ListView được build xong
  void _handleAfterBuild(List<ChatMessage> messages) {
    if (messages.isNotEmpty) {
      // Chỉ cuộn xuống tự động nếu danh sách vừa được tải lần đầu tiên
      // hoặc đang ở cuối danh sách
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          // Kiểm tra xem người dùng có đang ở gần cuối danh sách không
          // Nếu vị trí hiện tại cách cuối dưới 100 pixel, ta mới cuộn xuống
          bool isNearBottom = _scrollController.position.pixels >
              _scrollController.position.maxScrollExtent - 100;

          // Kiểm tra nếu ListView mới được tạo (chưa có vị trí cuộn)
          bool isFirstLoad = _scrollController.position.pixels == 0 &&
              _scrollController.position.maxScrollExtent > 0;

          if (isNearBottom || isFirstLoad) {
            _scrollToBottom();
          }
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if ((message.isEmpty && _selectedImage == null) || _isSending) return;

    // Hiệu ứng khi bấm nút gửi
    _sendButtonAnimationController.forward().then((_) {
      _sendButtonAnimationController.reverse();
    });

    debugPrint('📤 Chat: Đang gửi tin nhắn: "$message"');
    if (_selectedImage != null) {
      debugPrint('📤 Chat: Có file đính kèm: ${_selectedImage!.path}');
    }

    setState(() {
      _isSending = true;
    });

    try {
      bool success = false;

      if (_selectedImage != null) {
        debugPrint('📤 Chat: Gửi tin nhắn có đính kèm');
        success = await ref
            .read(chatMessagesProvider.notifier)
            .sendMessageWithAttachment(
                message.isNotEmpty ? message : null, _selectedImage!,
                userPhotoUrl: _userPhotoUrl);
      } else {
        debugPrint('📤 Chat: Gửi tin nhắn văn bản');
        success = await ref
            .read(chatMessagesProvider.notifier)
            .sendMessage(message, userPhotoUrl: _userPhotoUrl);
      }

      if (success) {
        debugPrint('✅ Chat: Gửi tin nhắn thành công');
        _messageController.clear();
        setState(() {
          _selectedImage = null;
        });

        // Phản hồi rung nhẹ
        HapticFeedback.lightImpact();

        // Cuộn xuống tin nhắn mới nhất
        _scrollToBottom();

        // Cập nhật số lượng tin nhắn để không hiển thị thông báo tin nhắn mới
        _previousMessageCount = ref.read(chatMessagesProvider).length;
      } else {
        debugPrint('❌ Chat: Gửi tin nhắn thất bại');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Không thể gửi tin nhắn. Vui lòng thử lại.')),
        );
      }
    } catch (e) {
      debugPrint('❌ Chat: Lỗi khi gửi tin nhắn: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi tin nhắn: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Giảm chất lượng để giảm kích thước
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });

      // Kiểm tra kích thước file
      try {
        final fileSize = await _selectedImage!.length();
        final fileSizeInMB = fileSize / (1024 * 1024);

        debugPrint('📸 Chat: Đã chọn hình ảnh từ thư viện: ${image.path}');
        debugPrint(
            '📊 Chat: Kích thước hình ảnh: ${fileSizeInMB.toStringAsFixed(2)}MB');

        // Nếu kích thước quá lớn, hiển thị thông báo
        if (fileSizeInMB > 10) {
          // Hiển thị cảnh báo
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Hình ảnh có kích thước lớn (${fileSizeInMB.toStringAsFixed(2)}MB) có thể mất thời gian để tải lên'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Chat: Lỗi khi kiểm tra kích thước hình ảnh: $e');
      }
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
      });

      debugPrint('📸 Chat: Đã chụp ảnh mới: ${photo.path}');
      try {
        final fileSize = await _selectedImage!.length();
        debugPrint(
            '📊 Chat: Kích thước ảnh: ${(fileSize / 1024).toStringAsFixed(2)}KB');
      } catch (e) {
        debugPrint('❌ Chat: Lỗi khi kiểm tra kích thước ảnh: $e');
      }
    }
  }

  Future<void> _pickFile() async {
    // Chưa có triển khai cho file picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng đang phát triển')),
    );
  }

  @override
  void dispose() {
    // Hủy timer trước khi dispose
    _autoRefreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _sendButtonAnimationController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theo dõi trạng thái dark mode
    final isDarkMode = ThemeController.isDarkMode;

    // Lấy trạng thái chat từ provider
    final chatState = ref.watch(chatStateProvider);
    final chatError = ref.watch(chatErrorProvider);

    // Lấy danh sách tin nhắn từ provider
    final messages = ref.watch(chatMessagesProvider);

    // Xác định trạng thái loading từ provider
    final isLoading = ref.read(chatMessagesProvider.notifier).isLoading;

    return Scaffold(
      backgroundColor:
          isDarkMode ? DarkThemeColors.backgroundColor : Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          height: 70 + MediaQuery.of(context).padding.top,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDarkColor,
                AppColors.primaryColor,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withOpacity(0.2),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Hỗ trợ khách hàng',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Không hiển thị thông báo hay indicator nào khi làm mới
                      // Chỉ gọi phương thức làm mới "âm thầm"
                      _refreshMessagesQuietly();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: isDarkMode
                              ? DarkThemeColors.cardColor
                              : Colors.white,
                          title: Text(
                            'Thông tin hỗ trợ',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white
                                  : AppColors.fontBlack,
                            ),
                          ),
                          content: Text(
                            'Đội ngũ hỗ trợ sẽ phản hồi tin nhắn của bạn trong thời gian sớm nhất.\n\n'
                            'Thời gian làm việc: 8h - 20h hàng ngày.',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : AppColors.fontBlack,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Đóng',
                                style: TextStyle(
                                  color: AppColors.buttonColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildChatBody(chatState, chatError, messages, isDarkMode),
    );
  }

  Widget _buildChatBody(String chatState, String? chatError,
      List<ChatMessage> messages, bool isDarkMode) {
    // Kiểm tra xem chat provider có đang loading không
    final bool providerIsLoading =
        ref.read(chatMessagesProvider.notifier).isLoading;

    // Ẩn mọi thông báo SnackBar hiện tại
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Nếu đang tải từ cache và có tin nhắn, hiển thị danh sách tin nhắn
    if (_isLoadingFromCache && messages.isNotEmpty) {
      return _buildChatContent(messages, isDarkMode);
    }

    if (chatState == 'loading' && messages.isEmpty) {
      // Chỉ hiển thị loading khi không có tin nhắn nào
      return _buildLoadingState(isDarkMode);
    } else if (chatState == 'error' && messages.isEmpty) {
      // Hiển thị lỗi chỉ khi không có tin nhắn nào
      return _buildErrorState(
          chatError ?? 'Đã xảy ra lỗi không xác định', isDarkMode);
    } else {
      // Luôn hiển thị nội dung chat, ngay cả khi đang tải hoặc có lỗi
      // nhưng đã có sẵn tin nhắn
      return _buildChatContent(messages, isDarkMode);
    }
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hiệu ứng loading đẹp hơn
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey[800]!.withOpacity(0.2)
                  : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
              strokeWidth: 3,
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Đang tải tin nhắn...',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey[800]!.withOpacity(0.3)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Xin vui lòng đợi trong giây lát',
              style: TextStyle(
                color: isDarkMode ? Colors.white60 : Colors.grey[500],
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  // Đặt lại trạng thái và thử lại
                  ref.read(chatMessagesProvider.notifier).resetState();
                  ref.read(chatMessagesProvider.notifier).loadMessages();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor.withOpacity(0.9),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.red[900]!.withOpacity(0.2)
                    : Colors.red[50],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.sentiment_dissatisfied_rounded,
                size: 70,
                color: isDarkMode ? Colors.red[300] : Colors.red[400],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Không thể tải tin nhắn',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.fontBlack,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey[800]!.withOpacity(0.5)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                  if (!errorMessage.contains("Quá thời gian"))
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        "Vui lòng kiểm tra kết nối mạng và thử lại.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: isDarkMode ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ref.read(chatMessagesProvider.notifier).loadMessages();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Làm mới'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatContent(List<ChatMessage> messages, bool isDarkMode) {
    // Chỉ gọi hàm xử lý cuộn xuống khi danh sách vừa được tải
    // hoặc khi có tin nhắn mới
    bool hasNewMessages = messages.length > _previousMessageCount;

    if (hasNewMessages) {
      _handleAfterBuild(messages);
      _previousMessageCount = messages.length;
    }

    // Ẩn mọi thông báo SnackBar hiện tại để tránh thông báo bị treo
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    return Stack(
      children: [
        Column(
          children: [
            // Indicator khi đang tải thêm tin nhắn
            if (_isLoadingMore)
              Container(
                padding: const EdgeInsets.all(8.0),
                color: isDarkMode
                    ? DarkThemeColors.backgroundColor
                    : Colors.grey[100],
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Đang tải thêm tin nhắn...',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Danh sách tin nhắn
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyChatState(isDarkMode)
                  : _buildMessageList(messages, isDarkMode),
            ),

            // Xem trước hình ảnh đã chọn
            if (_selectedImage != null) _buildSelectedImagePreview(isDarkMode),

            // Khu vực nhập tin nhắn
            _buildMessageInputArea(isDarkMode),
          ],
        ),

        // Nút cuộn xuống
        if (_showScrollToBottom)
          Positioned(
            right: 16,
            bottom: _selectedImage != null ? 178 : 78,
            child: FloatingActionButton.small(
              backgroundColor: AppColors.primaryColor.withOpacity(0.8),
              foregroundColor: Colors.white,
              onPressed: _scrollToBottom,
              child: const Icon(Icons.arrow_downward),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyChatState(bool isDarkMode) {
    // Bọc trong RefreshIndicator để hỗ trợ pull-to-refresh ngay cả khi không có tin nhắn
    return RefreshIndicator(
      onRefresh: () async {
        // Sử dụng phương thức để làm mới
        await _fetchMessagesFromServer();
      },
      color: AppColors.primaryColor,
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(), // Luôn cho phép cuộn để RefreshIndicator hoạt động
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey[800]!.withOpacity(0.3)
                          : Colors.grey[200]!,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'Gửi tin nhắn để bắt đầu cuộc trò chuyện với nhân viên hỗ trợ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: 18,
                        color: isDarkMode ? Colors.white60 : Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kéo xuống để làm mới',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white60 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _fetchMessagesFromServer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Làm mới'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages, bool isDarkMode) {
    debugPrint('🔍 Chat: Hiển thị ${messages.length} tin nhắn');

    // Sắp xếp tin nhắn theo thời gian tăng dần (cũ đến mới)
    // để hiển thị tin nhắn mới nhất ở cuối
    final List<ChatMessage> sortedMessages = [];
    if (messages.isNotEmpty) {
      sortedMessages.addAll(messages);
      sortedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      debugPrint(
          '📊 Chat: Sắp xếp ${sortedMessages.length} tin nhắn từ cũ đến mới');
    }

    // Bọc ListView trong RefreshIndicator để hỗ trợ pull-to-refresh
    return RefreshIndicator(
      onRefresh: () async {
        // Sử dụng phương thức để tải tin nhắn mới từ server
        await _fetchMessagesFromServer();
      },
      color: AppColors.primaryColor,
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
      displacement: 40,
      child: ListView.builder(
        controller: _scrollController,
        reverse: false, // Hiển thị tin nhắn mới ở dưới cùng
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
        itemCount: sortedMessages.length,
        itemBuilder: (context, index) {
          final message = sortedMessages[index];

          // Xác định người gửi tin nhắn
          final String senderName = message.senderName.toLowerCase();
          final bool isCustomerMessage = senderName.contains("son") ||
              senderName.contains("huynh") ||
              !(senderName.contains("admin") ||
                  senderName.contains("support") ||
                  senderName.contains("shop"));

          // Đặt isMe = true cho tin nhắn của khách hàng
          final isMe = isCustomerMessage;

          // Phân nhóm tin nhắn theo người gửi
          final isFirstInGroup = index == 0 ||
              isCustomerMessage !=
                  (sortedMessages[index - 1]
                          .senderName
                          .toLowerCase()
                          .contains("son") ||
                      sortedMessages[index - 1]
                          .senderName
                          .toLowerCase()
                          .contains("huynh"));
          final isLastInGroup = index == sortedMessages.length - 1 ||
              isCustomerMessage !=
                  (sortedMessages[index + 1]
                          .senderName
                          .toLowerCase()
                          .contains("son") ||
                      sortedMessages[index + 1]
                          .senderName
                          .toLowerCase()
                          .contains("huynh"));

          return Padding(
            padding: EdgeInsets.only(
              top: isFirstInGroup ? 16.0 : 2.0,
              bottom: isLastInGroup ? 8.0 : 2.0,
            ),
            child: ChatBubble(
              message: message,
              isMe: isMe,
              userColor: AppColors.primaryColor,
              adminColor:
                  isDarkMode ? DarkThemeColors.cardColor : Colors.grey[200]!,
              onImageTap: () {
                if (message.hasAttachment && message.isImage) {
                  // Sử dụng URL đã qua xử lý từ model
                  final imageUrl = message.processedAttachmentUrl;
                  if (imageUrl != null) {
                    _openImagePreview(context, imageUrl);
                  } else {
                    // Hiển thị thông báo lỗi nếu URL không hợp lệ
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Không thể mở hình ảnh, URL không hợp lệ'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _openImagePreview(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Ảnh đính kèm',
                style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) {
                  debugPrint('❌ ChatScreen: Lỗi tải hình ảnh preview: $error');
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không thể tải hình ảnh\n$error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Quay lại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
                fit: BoxFit.contain,
                fadeInDuration: const Duration(milliseconds: 300),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedImagePreview(bool isDarkMode) {
    return Container(
      height: 100,
      width: double.infinity,
      color: isDarkMode ? DarkThemeColors.cardColor : Colors.grey[200],
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Hình ảnh được chọn
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Hình ảnh
                      Image.file(
                        _selectedImage!,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),

                      // Gradient overlay cho chỉ báo nén
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: FutureBuilder<int>(
                          future: _selectedImage!.length(),
                          builder: (context, snapshot) {
                            // Nếu kích thước lớn hơn 2MB, hiển thị chỉ báo nén
                            if (snapshot.hasData &&
                                snapshot.data! > 2 * 1024 * 1024) {
                              return Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.6),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.compress,
                                          size: 12, color: Colors.white),
                                      SizedBox(width: 2),
                                      Text(
                                        'Sẽ nén',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hình ảnh đã chọn',
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.white : AppColors.fontBlack,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<int>(
                        future: _selectedImage!.length(),
                        builder: (context, snapshot) {
                          final String sizeText;
                          if (snapshot.hasData) {
                            final sizeInKB = snapshot.data! / 1024;
                            if (sizeInKB < 1024) {
                              sizeText = '${sizeInKB.toStringAsFixed(0)} KB';
                            } else {
                              sizeText =
                                  '${(sizeInKB / 1024).toStringAsFixed(1)} MB';
                            }
                          } else {
                            sizeText = 'Đang tính kích thước...';
                          }

                          return Text(
                            'Kích thước: $sizeText',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.grey[700],
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Icon(
                Icons.close,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInputArea(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? DarkThemeColors.cardColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Nút đính kèm
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: AppColors.primaryColor.withOpacity(0.8),
                size: 28,
              ),
              onPressed: () {
                // Show the bottom sheet directly here
                showModalBottomSheet(
                  context: context,
                  backgroundColor:
                      isDarkMode ? DarkThemeColors.cardColor : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (BuildContext ctx) {
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Đính kèm tập tin',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : AppColors.fontBlack,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.grey[700],
                                  ),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildAttachmentOption(
                                  ctx,
                                  icon: Icons.photo_library,
                                  label: 'Thư viện',
                                  color: Colors.blue,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _pickImage();
                                  },
                                ),
                                _buildAttachmentOption(
                                  ctx,
                                  icon: Icons.camera_alt,
                                  label: 'Máy ảnh',
                                  color: Colors.green,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _takePhoto();
                                  },
                                ),
                                _buildAttachmentOption(
                                  ctx,
                                  icon: Icons.attach_file,
                                  label: 'Tập tin',
                                  color: Colors.orange,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _pickFile();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Ô nhập tin nhắn
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 1.0,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.white54 : Colors.grey[500],
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : AppColors.fontBlack,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),

            // Nút gửi
            AnimatedBuilder(
              animation: _sendButtonAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _sendButtonScaleAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: _messageController.text.trim().isNotEmpty ||
                              _selectedImage != null
                          ? AppColors.primaryColor
                          : Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                            ),
                      onPressed: _messageController.text.trim().isNotEmpty ||
                              _selectedImage != null
                          ? _sendMessage
                          : null,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: ThemeController.isDarkMode
                  ? Colors.white70
                  : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
