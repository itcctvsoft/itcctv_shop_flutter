import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/models/comment.dart';
import 'package:shoplite/repositories/comment_repository.dart';
import 'package:intl/intl.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoplite/widgets/auth_required_wrapper.dart';
import 'package:shoplite/utils/auth_helpers.dart';
import 'package:shoplite/ui/login/login_screen.dart';
import 'package:shoplite/ui/widgets/notification_dialog.dart';
import 'package:shoplite/ui/widgets/auth_action_view.dart';
import 'package:shoplite/providers/auth_service_provider.dart';
import 'package:shoplite/constants/pref_data.dart';

// Provider for comment repository
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository();
});

// Provider for comment state
final commentsStateProvider = StateNotifierProvider.family<CommentsNotifier,
    AsyncValue<CommentResponse>, int>(
  (ref, productId) => CommentsNotifier(
    repository: ref.watch(commentRepositoryProvider),
    productId: productId,
  ),
);

// Tạo provider riêng để check login state
final isUserLoggedInProvider = FutureProvider<bool>((ref) async {
  return await AuthHelpers.isLoggedIn();
});

// State notifier cho comments
class CommentsNotifier extends StateNotifier<AsyncValue<CommentResponse>> {
  final CommentRepository repository;
  final int productId;

  CommentsNotifier({required this.repository, required this.productId})
      : super(const AsyncValue.loading()) {
    fetchComments();
  }

  Future<void> fetchComments() async {
    state = const AsyncValue.loading();
    try {
      print('[CommentsNotifier] Đang tải bình luận cho sản phẩm $productId');
      final response = await repository.getCommentsByProduct(productId);
      print('[CommentsNotifier] Đã nhận ${response.comments.length} bình luận');

      // Sắp xếp bình luận từ mới đến cũ
      final sortedComments = response.comments
        ..sort((a, b) {
          if (a.createdAt == null || b.createdAt == null) return 0;
          return DateTime.parse(b.createdAt!)
              .compareTo(DateTime.parse(a.createdAt!));
        });

      final sortedResponse = CommentResponse(
        success: response.success,
        totalComments: response.totalComments,
        averageRating: response.averageRating,
        comments: sortedComments,
      );

      state = AsyncValue.data(sortedResponse);
    } catch (err, stack) {
      print('[CommentsNotifier] Lỗi: $err');
      state = AsyncValue.error(err, stack);
    }
  }

  // Thêm bình luận mới
  Future<Map<String, dynamic>> addComment({
    required int userId,
    required String commentText,
    required int rating,
  }) async {
    try {
      print('[CommentsNotifier] Đang thêm bình luận mới');
      final result = await repository.addComment(
        productId: productId,
        userId: userId,
        comment: commentText,
        rating: rating,
      );

      if (result['success']) {
        print('[CommentsNotifier] Bình luận đã được thêm thành công');
        await fetchComments(); // Cập nhật danh sách bình luận
      }

      return result;
    } catch (e) {
      print('[CommentsNotifier] Lỗi khi thêm bình luận: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  // Cập nhật bình luận hiện có
  Future<Map<String, dynamic>> updateComment({
    required int commentId,
    required int userId,
    required String commentText,
    required int rating,
  }) async {
    try {
      print('[CommentsNotifier] Đang cập nhật bình luận ID=$commentId');
      final result = await repository.updateComment(
        commentId: commentId,
        userId: userId,
        comment: commentText,
        rating: rating,
      );

      if (result['success']) {
        print('[CommentsNotifier] Bình luận đã được cập nhật thành công');
        await fetchComments(); // Cập nhật danh sách bình luận
      }

      return result;
    } catch (e) {
      print('[CommentsNotifier] Lỗi khi cập nhật bình luận: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  // Xóa bình luận
  Future<Map<String, dynamic>> deleteComment({
    required int commentId,
    required int userId,
  }) async {
    try {
      print('[CommentsNotifier] Đang xóa bình luận ID=$commentId');
      final result = await repository.deleteComment(
        commentId: commentId,
        userId: userId,
      );

      if (result['success']) {
        print('[CommentsNotifier] Bình luận đã được xóa thành công');
        await fetchComments(); // Cập nhật danh sách bình luận
      }

      return result;
    } catch (e) {
      print('[CommentsNotifier] Lỗi khi xóa bình luận: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }
}

class CommentSection extends ConsumerStatefulWidget {
  final int productId;
  final int userId;

  const CommentSection({
    Key? key,
    required this.productId,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  Comment? _userExistingComment;
  int _rating = 5;
  bool isDarkMode = false;
  bool _isAuthenticated = false;

  // Add caching variables
  bool _isCheckingAuth = false;
  DateTime? _lastAuthCheck;
  String? _cachedToken;

  // Add flag to track if user is actively editing
  bool _isUserEditing = false;

  // Save comment draft
  String _savedCommentText = '';

  // Prevent unintended refreshes
  bool _isRefreshing = false;

  // Remember if input has focus to avoid focus loss
  final FocusNode _commentFocusNode = FocusNode();

  // Throttle duration - only check auth every 30 seconds
  static const _authCheckThrottleDuration = Duration(seconds: 30);

  // Giữ nguyên trạng thái khi widget rebuild
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set initial dark mode value
    isDarkMode = ThemeController.isDarkMode;

    // Listen for theme changes
    ThemeController.addListener(_onThemeChanged);

    // Add listener to detect when user is typing
    _commentController.addListener(_onCommentTextChanged);

    // Add focus listener
    _commentFocusNode.addListener(_onFocusChanged);

    // Force authentication check on init - with small delay to avoid race conditions
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _checkLoginAndUserComment();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes from background, check auth status again
    if (state == AppLifecycleState.resumed) {
      // Force refresh when resuming from background
      _lastAuthCheck = null;
      _checkLoginAndUserComment();
    }
  }

  void _onCommentTextChanged() {
    final newText = _commentController.text;
    // If content changed and not empty, mark as editing
    if (newText.isNotEmpty && newText != _savedCommentText) {
      _isUserEditing = true;
      _savedCommentText = newText;
    }
  }

  void _onFocusChanged() {
    // Update editing state based on focus
    if (_commentFocusNode.hasFocus) {
      _isUserEditing = true;
    } else if (_commentController.text.isEmpty) {
      // Only mark as not editing if text is empty
      _isUserEditing = false;
    }
  }

  @override
  void dispose() {
    _commentFocusNode.removeListener(_onFocusChanged);
    _commentFocusNode.dispose();
    _commentController.removeListener(_onCommentTextChanged);
    _commentController.dispose();
    ThemeController.removeListener(_onThemeChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        isDarkMode = ThemeController.isDarkMode;
      });
    }
  }

  // Lấy tên người dùng từ SharedPreferences
  Future<String> _getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fullName') ?? 'Người dùng';
  }

  // Reset auth cache when needed (like after login/logout)
  void _resetAuthCache() {
    _lastAuthCheck = null;
    _cachedToken = null;
  }

  // Improved method to check login status with throttling
  Future<void> _checkLoginAndUserComment() async {
    // Prevent multiple simultaneous checks
    if (_isCheckingAuth || _isRefreshing) return;

    // Skip if user is actively editing to prevent disruption
    if (_isUserEditing && _commentController.text.isNotEmpty) {
      print('[CommentSection] User is actively editing, skipping auth check');
      return;
    }

    // Check if we should throttle the check
    final now = DateTime.now();
    if (_lastAuthCheck != null &&
        now.difference(_lastAuthCheck!) < _authCheckThrottleDuration) {
      // Use cached auth status if recent
      print('[CommentSection] Using cached auth status');

      // If already authenticated, check for user comment
      if (_isAuthenticated && _userExistingComment == null) {
        _checkForUserComment();
      }
      return;
    }

    _isCheckingAuth = true;

    // Important: Save cursor position
    final oldSelection = _commentController.selection;

    // Save current comment text before auth check
    final currentText = _commentController.text;
    final hasFocus = _commentFocusNode.hasFocus;

    print('[CommentSection] Checking login status...');

    try {
      // Get token from cache or load it if needed
      String token = _cachedToken ?? '';
      if (token.isEmpty) {
        token = await PrefData.getToken();
        _cachedToken = token; // Cache the token
      }

      // Do a quick check - if no token, definitely not authenticated
      if (token.isEmpty) {
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _lastAuthCheck = now;
            _isCheckingAuth = false;
          });
        }
        return;
      }

      // Only verify authentication with backend if we have a token
      final loginStatus = await PrefData.isAuthenticated();

      if (mounted) {
        setState(() {
          _isAuthenticated = loginStatus;
          _lastAuthCheck = now;
          _isCheckingAuth = false;
        });
      } else {
        _isCheckingAuth = false;
      }

      // Check for user comment if authenticated
      if (_isAuthenticated) {
        _checkForUserComment();
      }

      // Restore comment text and cursor position if needed
      if (mounted &&
          _commentController.text != currentText &&
          currentText.isNotEmpty) {
        // Set the text first, then restore selection
        _commentController.value = TextEditingValue(
          text: currentText,
          selection: oldSelection,
        );

        // Important: restore focus if it was lost
        if (hasFocus && !_commentFocusNode.hasFocus) {
          _commentFocusNode.requestFocus();
        }
      }
    } catch (e) {
      print('[CommentSection] Error checking auth: $e');
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      } else {
        _isCheckingAuth = false;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only check if not actively editing and not refreshing
    if (!_isUserEditing && !_isRefreshing) {
      _checkLoginAndUserComment();
    }
  }

  // Kiểm tra xem người dùng đã có bình luận chưa
  void _checkForUserComment() {
    // Skip if user is actively editing to prevent disruption
    if (_isUserEditing && _commentController.text.isNotEmpty) {
      print(
          '[CommentSection] User is actively editing, skipping user comment check');
      return;
    }

    // Skip if refreshing is in progress
    if (_isRefreshing) return;

    if (widget.userId <= 0) {
      print('[CommentSection] Invalid user ID: ${widget.userId}');
      return;
    }

    final commentsState = ref.read(commentsStateProvider(widget.productId));

    if (commentsState is AsyncData<CommentResponse>) {
      final comments = commentsState.value.comments;
      Comment? foundComment;

      for (final comment in comments) {
        if (comment.userId == widget.userId) {
          print(
              '[CommentSection] ✅ Tìm thấy bình luận của người dùng ID=${comment.id}');
          foundComment = comment;
          break;
        }
      }

      // Only update if not actively editing and comment text hasn't been changed
      if (foundComment != null &&
          mounted &&
          (!_isUserEditing || _commentController.text.isEmpty)) {
        // Remember input focus state
        final hadFocus = _commentFocusNode.hasFocus;

        setState(() {
          _userExistingComment = foundComment;

          // Only update text if the user hasn't changed it themselves
          if (_savedCommentText.isEmpty ||
              _savedCommentText == _commentController.text) {
            _commentController.text = foundComment!.comment;
            _savedCommentText = foundComment.comment;
          }

          _rating = foundComment!.rating;
        });

        // Restore focus if it was lost
        if (hadFocus && !_commentFocusNode.hasFocus) {
          _commentFocusNode.requestFocus();
        }
      }
    }
  }

  Future<void> _submitComment(BuildContext context) async {
    // Force clear auth cache to ensure fresh check before submitting
    _resetAuthCache();

    // Force check login status before submitting
    bool isLoggedIn = await AuthHelpers.isLoggedIn();

    if (!isLoggedIn) {
      print('[CommentSection] User not logged in, showing login prompt');

      // Navigate to login screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuthActionView(
            featureDescription: "bình luận sản phẩm",
            featureIcon: Icons.comment,
          ),
        ),
      );

      // When returning from login screen, force check login status again
      await _checkLoginAndUserComment();

      // Re-check login status after returning from login screen
      isLoggedIn = await AuthHelpers.isLoggedIn();
      if (!isLoggedIn) {
        print('[CommentSection] User still not logged in after login prompt');
        return;
      }
    }

    final text = _commentController.text.trim();
    if (text.isEmpty) {
      // Thêm thông báo nếu comment quá ngắn
      NotificationDialog.showWarning(
        context: context,
        title: 'Lỗi',
        message: 'Vui lòng nhập nội dung bình luận',
        primaryButtonText: 'OK',
        primaryAction: () {
          Navigator.of(context).pop();
        },
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final commentsNotifier =
          ref.read(commentsStateProvider(widget.productId).notifier);
      Map<String, dynamic> result;

      if (_userExistingComment != null) {
        // Cập nhật bình luận
        result = await commentsNotifier.updateComment(
          commentId: _userExistingComment!.id!,
          userId: widget.userId,
          commentText: text,
          rating: _rating,
        );
      } else {
        // Thêm bình luận mới
        result = await commentsNotifier.addComment(
          userId: widget.userId,
          commentText: text,
          rating: _rating,
        );

        // Xử lý trường hợp đặc biệt khi backend trả về lỗi "đã bình luận rồi"
        if (!result['success'] &&
            result['message'] != null &&
            (result['message'].toString().contains('đã bình luận') ||
                result['message'].toString().contains('Bạn đã bình luận'))) {
          print(
              '[CommentSection] Phát hiện người dùng đã bình luận, tìm kiếm bình luận hiện có');

          // Tải lại danh sách bình luận để tìm kiếm bình luận của người dùng
          await commentsNotifier.fetchComments();

          // Delay nhỏ để đảm bảo state được cập nhật
          await Future.delayed(const Duration(milliseconds: 300));

          // Đọc lại state sau khi đã refresh
          final commentsState =
              ref.read(commentsStateProvider(widget.productId));

          if (commentsState is AsyncData<CommentResponse>) {
            // Tìm bình luận của người dùng hiện tại
            Comment? userComment;
            for (final comment in commentsState.value.comments) {
              if (comment.userId == widget.userId) {
                userComment = comment;
                break;
              }
            }

            if (userComment != null) {
              print(
                  '[CommentSection] Đã tìm thấy bình luận của người dùng: ID=${userComment.id}');

              // Cập nhật UI
              setState(() {
                _userExistingComment = userComment;
                // Giữ nguyên nội dung người dùng vừa nhập thay vì lấy từ bình luận cũ
              });

              // Thử cập nhật bình luận thay vì tạo mới
              result = await commentsNotifier.updateComment(
                commentId: userComment.id!,
                userId: widget.userId,
                commentText: text,
                rating: _rating,
              );

              if (result['success']) {
                return;
              }
            }
          }
        }

        // Refresh comments để tìm bình luận hiện có
        ref
            .read(commentsStateProvider(widget.productId).notifier)
            .fetchComments();
      }

      if (result['success']) {
        if (_userExistingComment == null) {
          _commentController.clear();

          // Cập nhật UI để hiển thị bình luận mới
          final commentData = result['data'];
          if (commentData != null && commentData is Comment) {
            setState(() {
              _userExistingComment = commentData;
            });
          }
        }
        // Success - no notification needed
      } else {
        // Error - no notification needed
      }
    } catch (e) {
      print('Lỗi khi gửi bình luận: $e');
      // Error - no notification needed
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteComment() async {
    if (_userExistingComment == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final commentsNotifier =
          ref.read(commentsStateProvider(widget.productId).notifier);
      final result = await commentsNotifier.deleteComment(
        commentId: _userExistingComment!.id!,
        userId: widget.userId,
      );

      if (result['success']) {
        setState(() {
          _userExistingComment = null;
          _commentController.clear();
        });
        // Success - no notification needed
      } else {
        // Error - no notification needed
      }
    } catch (e) {
      print('Lỗi khi xóa bình luận: $e');
      // Error - no notification needed
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Watch comments state for this product
    final commentsState = ref.watch(commentsStateProvider(widget.productId));

    return commentsState.when(
      data: (commentsData) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.shadowColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                blurRadius: 15,
                spreadRadius: 0,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề và phần nhập bình luận
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    16, 16, 16, 8), // Reduced bottom padding from 20 to 8
                child: Row(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      color: AppColors.primaryColor.withOpacity(0.8),
                      size: 24, // Reduced from 28
                    ),
                    SizedBox(width: 8), // Reduced from 12
                    Text(
                      'Bình luận',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppColors.fontBlack,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${commentsData.totalComments} bình luận',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.greyFont,
                      ),
                    ),
                  ],
                ),
              ),
              // Phần viết bình luận
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16), // Reduced from 20 to 16
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8), // Reduced from 16
                    Text(
                      'Viết bình luận của bạn',
                      style: TextStyle(
                        fontSize: 16, // Reduced from 17
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : AppColors.fontBlack,
                      ),
                    ),
                    SizedBox(height: 8), // Reduced from 12
                    // Rating stars
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                          child: Icon(
                            index < _rating
                                ? Icons.star
                                : Icons.star_border_outlined,
                            color: index < _rating
                                ? AppColors.primaryColor
                                : AppColors.greyFont,
                            size: 28, // Reduced from 32
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 10), // Reduced from 16
                    // Comment text field with increased height for more visibility
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey[850]
                            : const Color(0xFFF5F8FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: 4), // Reduced padding
                      child: TextField(
                        focusNode: _commentFocusNode,
                        controller: _commentController,
                        maxLines: 3, // Reduced from 4
                        minLines: 2, // Set minimum lines
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: 15, // Reduced from 16
                          color:
                              isDarkMode ? Colors.white : AppColors.fontBlack,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nhập bình luận của bạn...',
                          hintStyle: TextStyle(
                            color: AppColors.greyFont,
                            fontSize: 15, // Reduced from 16
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8), // Reduced padding
                        ),
                      ),
                    ),
                    SizedBox(height: 10), // Reduced from 16
                    // Submit button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  // Clear text field and reset
                                  setState(() {
                                    _commentController.clear();
                                    _userExistingComment = null;
                                    _rating = 5;
                                  });
                                },
                          child: Text(
                            'Hủy',
                            style: TextStyle(
                              color: AppColors.greyFont,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8), // Reduced spacing
                        ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _submitComment(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10), // Reduced padding
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // Reduced radius
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : Text(
                                  _userExistingComment != null
                                      ? 'Cập nhật'
                                      : 'Gửi bình luận',
                                  style: TextStyle(
                                    fontSize: 14, // Reduced size
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Hiển thị danh sách bình luận
              if (commentsData.comments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                      top: 8,
                      left: 16,
                      right: 16), // Reduced top padding from 16 to 8
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4), // Reduced from 8 to 4
                      Divider(
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      ),
                      SizedBox(height: 4), // Reduced from 8 to 4
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${commentsData.totalComments} bình luận',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white
                                  : AppColors.fontBlack,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _isRefreshing ? null : _refreshComments,
                            icon: _isRefreshing
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryColor,
                                    ),
                                  )
                                : Icon(
                                    Icons.refresh,
                                    size: 16,
                                    color: AppColors.primaryColor,
                                  ),
                            label: Text(
                              'Làm mới',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: Size(0, 0),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4), // Smaller padding
                            ),
                          ),
                        ],
                      ),
                      // No space here - remove any SizedBox
                      // Danh sách bình luận
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: commentsData.comments.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 8),
                        padding:
                            EdgeInsets.only(top: 8), // Add minimal top padding
                        itemBuilder: (context, index) {
                          final comment = commentsData.comments[index];
                          return _buildCommentItem(comment);
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'Không thể tải bình luận: $error',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.fontBlack),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isRefreshing ? null : _refreshComments,
                child: _isRefreshing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.fontLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Safely refresh comments without disrupting user input
  Future<void> _refreshComments() async {
    // Skip if already refreshing
    if (_isRefreshing) return;

    // Don't refresh while user is editing
    if (_isUserEditing && _commentController.text.isNotEmpty) {
      print('[CommentSection] User is actively editing, skipping refresh');
      return;
    }

    _isRefreshing = true;

    try {
      // Save text and focus state
      final currentText = _commentController.text;
      final hadFocus = _commentFocusNode.hasFocus;
      final cursorPosition = _commentController.selection;

      // Refresh comments
      await ref
          .read(commentsStateProvider(widget.productId).notifier)
          .fetchComments();

      // Wait for state to update
      await Future.delayed(Duration(milliseconds: 100));

      if (mounted) {
        // Restore text if needed
        if (currentText.isNotEmpty && _commentController.text != currentText) {
          _commentController.value = TextEditingValue(
            text: currentText,
            selection: cursorPosition,
          );
        }

        // Restore focus if needed
        if (hadFocus && !_commentFocusNode.hasFocus) {
          _commentFocusNode.requestFocus();
        }
      }
    } catch (e) {
      print('[CommentSection] Error refreshing comments: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Widget to display a single comment
  Widget _buildCommentItem(Comment comment) {
    // Format date
    String formattedDate = '';
    if (comment.createdAt != null) {
      try {
        final dateTime = DateTime.parse(comment.createdAt!);
        formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
      } catch (e) {
        formattedDate = comment.createdAt ?? '';
      }
    }

    // Check if this is the current user's comment
    final isCurrentUserComment = comment.userId == widget.userId;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUserComment
            ? (isDarkMode
                ? AppColors.primaryColor.withOpacity(0.1)
                : Colors.blue.shade50)
            : (isDarkMode ? Colors.grey[800] : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUserComment
              ? AppColors.primaryColor
              : (isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: isCurrentUserComment
                    ? AppColors.primaryColor
                    : Colors.grey.shade300,
                backgroundImage: comment.user?.photo != null &&
                        comment.user!.photo.isNotEmpty
                    ? NetworkImage(comment.user!.photo)
                    : null,
                child:
                    comment.user?.photo == null || comment.user!.photo.isEmpty
                        ? Text(
                            comment.user?.full_name != null &&
                                    comment.user!.full_name.isNotEmpty
                                ? comment.user!.full_name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
              ),
              SizedBox(width: 8),
              // User name
              Expanded(
                child: Text(
                  comment.user?.full_name ?? 'Người dùng ẩn danh',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : AppColors.fontBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Date
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.greyFont,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          // Rating
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < comment.rating ? Icons.star : Icons.star_border,
                color: index < comment.rating
                    ? AppColors.primaryColor
                    : AppColors.greyFont,
                size: 14,
              ),
            ),
          ),
          SizedBox(height: 8),
          // Comment content
          Text(
            comment.comment,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white : AppColors.fontBlack,
            ),
          ),
        ],
      ),
    );
  }
}
