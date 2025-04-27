import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/providers/chat_provider.dart';
import 'package:shoplite/screens/chat_screen.dart';

class FloatingChatButton extends ConsumerStatefulWidget {
  final bool showLabel;
  final bool expandOnHover;
  final EdgeInsets padding;
  final bool mini;

  const FloatingChatButton({
    Key? key,
    this.showLabel = false,
    this.expandOnHover = true,
    this.padding = const EdgeInsets.only(right: 16.0, bottom: 80.0),
    this.mini = false,
  }) : super(key: key);

  @override
  ConsumerState<FloatingChatButton> createState() => _FloatingChatButtonState();
}

class _FloatingChatButtonState extends ConsumerState<FloatingChatButton>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  bool _isAnimating = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Thiết lập hoạt ảnh tự động nếu có tin nhắn chưa đọc
    _setupPulseAnimation();
  }

  void _setupPulseAnimation() {
    // Kiểm tra nếu có tin nhắn chưa đọc, thực hiện hiệu ứng nhắc nhở
    final unreadCount = ref.read(unreadMessagesProvider);
    if (unreadCount > 0 && !_isAnimating) {
      _isAnimating = true;
      _animationController.repeat(reverse: true);
    } else if (unreadCount == 0 && _isAnimating) {
      _isAnimating = false;
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void didUpdateWidget(FloatingChatButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setupPulseAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupPulseAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Đọc số tin nhắn chưa đọc từ provider
    final unreadCount = ref.watch(unreadMessagesProvider);
    final isDarkMode = ThemeController.isDarkMode;

    // Kiểm tra và cập nhật trạng thái animation
    if (unreadCount > 0 && !_isAnimating) {
      _isAnimating = true;
      _animationController.repeat(reverse: true);
    } else if (unreadCount == 0 && _isAnimating) {
      _isAnimating = false;
      _animationController.stop();
      _animationController.reset();
    }

    return Positioned(
      right: widget.padding.right,
      bottom: widget.padding.bottom,
      child: MouseRegion(
        onEnter: (_) =>
            widget.expandOnHover ? setState(() => _isHovering = true) : null,
        onExit: (_) =>
            widget.expandOnHover ? setState(() => _isHovering = false) : null,
        child: GestureDetector(
          onTap: () {
            // Khi nút được nhấn, dừng hoạt ảnh và đánh dấu tin nhắn đã đọc
            if (_isAnimating) {
              _isAnimating = false;
              _animationController.stop();
              _animationController.reset();
            }

            // Chuyển hướng đến trang chat
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            ).then((_) {
              // Sau khi quay lại, làm mới số tin nhắn chưa đọc
              ref.read(unreadMessagesProvider.notifier).refreshUnreadCount();
            });
          },
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: child,
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isHovering && widget.showLabel
                  ? 180
                  : widget.mini
                      ? 50
                      : 60,
              height: widget.mini ? 50 : 60,
              decoration: BoxDecoration(
                color: isDarkMode ? DarkThemeColors.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(
                    _isHovering && widget.showLabel ? 30 : 30),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : AppColors.shadowColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Nút và label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: _isHovering && widget.showLabel ? 12.0 : 0,
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: isDarkMode
                              ? AppColors.accentColor
                              : AppColors.primaryColor,
                          size: widget.mini ? 24 : 28,
                        ),
                      ),
                      if (_isHovering && widget.showLabel)
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, right: 12.0),
                            child: Text(
                              'Hỗ trợ trực tuyến',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white
                                    : AppColors.fontBlack,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Badge cho tin nhắn chưa đọc
                  if (unreadCount > 0)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.buttonColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDarkMode
                                ? DarkThemeColors.backgroundColor
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
