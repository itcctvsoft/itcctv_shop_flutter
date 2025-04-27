import 'dart:math';
import 'dart:ui';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:shoplite/constants/widget_utils.dart';
import 'package:shoplite/constants/color_data.dart';

class NotificationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String imageName; // SVG image name
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? primaryAction;
  final VoidCallback? secondaryAction;
  final BuildContext context;
  final bool autoDismiss;
  final Duration autoDismissDuration;

  const NotificationDialog({
    Key? key,
    required this.context,
    required this.title,
    required this.message,
    required this.imageName,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.primaryAction,
    this.secondaryAction,
    this.autoDismiss = false,
    this.autoDismissDuration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  _NotificationDialogState createState() => _NotificationDialogState();

  // Static methods for common dialog types
  static void showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? primaryAction,
    VoidCallback? secondaryAction,
    bool autoDismiss = false,
    Duration autoDismissDuration = const Duration(seconds: 2),
  }) {
    if (autoDismiss) {
      _showToastNotification(
        context: context,
        title: title,
        message: message,
        imageName: "thankyou.svg",
        type: NotificationType.success,
        duration: autoDismissDuration,
        onDismiss: primaryAction,
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return NotificationDialog(
            context: context,
            title: title,
            message: message,
            imageName: "thankyou.svg", // Success image
            primaryButtonText: primaryButtonText,
            secondaryButtonText: secondaryButtonText,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            autoDismiss: false,
            autoDismissDuration: autoDismissDuration,
          );
        },
      );
    }
  }

  static void showRemovedFromWishlist({
    required BuildContext context,
    required String title,
    required String message,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? primaryAction,
    VoidCallback? secondaryAction,
    bool autoDismiss = false,
    Duration autoDismissDuration = const Duration(seconds: 2),
  }) {
    if (autoDismiss) {
      _showToastNotification(
        context: context,
        title: title,
        message: message,
        imageName: "removed_wishlist.svg",
        type: NotificationType.wishlist,
        duration: autoDismissDuration,
        onDismiss: primaryAction,
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return NotificationDialog(
            context: context,
            title: title,
            message: message,
            imageName: "removed_wishlist.svg",
            primaryButtonText: primaryButtonText,
            secondaryButtonText: secondaryButtonText,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            autoDismiss: false,
            autoDismissDuration: autoDismissDuration,
          );
        },
      );
    }
  }

  static void showError({
    required BuildContext context,
    required String title,
    required String message,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? primaryAction,
    VoidCallback? secondaryAction,
    bool autoDismiss = false,
    Duration autoDismissDuration = const Duration(seconds: 2),
  }) {
    if (autoDismiss) {
      _showToastNotification(
        context: context,
        title: title,
        message: message,
        imageName: "error.svg",
        type: NotificationType.error,
        duration: autoDismissDuration,
        onDismiss: primaryAction,
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return NotificationDialog(
            context: context,
            title: title,
            message: message,
            imageName: "error.svg",
            primaryButtonText: primaryButtonText,
            secondaryButtonText: secondaryButtonText,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            autoDismiss: false,
            autoDismissDuration: autoDismissDuration,
          );
        },
      );
    }
  }

  static void showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? primaryAction,
    VoidCallback? secondaryAction,
    bool autoDismiss = false,
    Duration autoDismissDuration = const Duration(seconds: 2),
  }) {
    if (autoDismiss) {
      _showToastNotification(
        context: context,
        title: title,
        message: message,
        imageName: "info.svg",
        type: NotificationType.info,
        duration: autoDismissDuration,
        onDismiss: primaryAction,
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return NotificationDialog(
            context: context,
            title: title,
            message: message,
            imageName: "info.svg",
            primaryButtonText: primaryButtonText,
            secondaryButtonText: secondaryButtonText,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            autoDismiss: false,
            autoDismissDuration: autoDismissDuration,
          );
        },
      );
    }
  }

  static void showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? primaryAction,
    VoidCallback? secondaryAction,
    bool autoDismiss = false,
    Duration autoDismissDuration = const Duration(seconds: 2),
  }) {
    if (autoDismiss) {
      _showToastNotification(
        context: context,
        title: title,
        message: message,
        imageName: "warning.svg",
        type: NotificationType.warning,
        duration: autoDismissDuration,
        onDismiss: primaryAction,
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return NotificationDialog(
            context: context,
            title: title,
            message: message,
            imageName: "warning.svg",
            primaryButtonText: primaryButtonText,
            secondaryButtonText: secondaryButtonText,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            autoDismiss: false,
            autoDismissDuration: autoDismissDuration,
          );
        },
      );
    }
  }

  static void showPaymentFailed({
    required BuildContext context,
    required String title,
    required String message,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? primaryAction,
    VoidCallback? secondaryAction,
    bool autoDismiss = false,
    Duration autoDismissDuration = const Duration(seconds: 2),
  }) {
    if (autoDismiss) {
      _showToastNotification(
        context: context,
        title: title,
        message: message,
        imageName: "payment_failed.svg",
        type: NotificationType.error,
        duration: autoDismissDuration,
        onDismiss: primaryAction,
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return NotificationDialog(
            context: context,
            title: title,
            message: message,
            imageName: "payment_failed.svg",
            primaryButtonText: primaryButtonText,
            secondaryButtonText: secondaryButtonText,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            autoDismiss: false,
            autoDismissDuration: autoDismissDuration,
          );
        },
      );
    }
  }

  // Helper method for toast-style notifications
  static void _showToastNotification({
    required BuildContext context,
    required String title,
    required String message,
    required String imageName,
    required NotificationType type,
    required Duration duration,
    VoidCallback? onDismiss,
  }) {
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(builder: (context) {
      return _ToastNotification(
        title: title,
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          overlayEntry?.remove();
          if (onDismiss != null) {
            onDismiss();
          }
        },
      );
    });

    overlayState.insert(overlayEntry);
  }
}

class _NotificationDialogState extends State<NotificationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Start animation when dialog appears
    _animationController.forward();

    // Set up auto-dismiss animation if needed
    if (widget.autoDismiss) {
      Future.delayed(widget.autoDismissDuration - Duration(milliseconds: 300),
          () {
        if (mounted) {
          _animationController.reverse().then((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              if (widget.primaryAction != null) {
                widget.primaryAction!();
              }
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // More compact dimensions for auto-dismiss notifications
    double height = widget.autoDismiss
        ? Constant.getHeightPercentSize(38)
        : Constant.getHeightPercentSize(45);
    double width = Constant.getWidthPercentSize(85);
    double radius = 20.0;
    double imgSize =
        Constant.getPercentSize(height, widget.autoDismiss ? 25 : 32);

    // Choose iconData based on imageName for better consistency
    IconData iconData;
    Color iconColor;

    if (widget.imageName.contains("thankyou")) {
      iconData = Icons.check; // Simple check icon
      iconColor = Color(0xFF4CAF50); // Material green color
    } else if (widget.imageName.contains("error")) {
      iconData = Icons.error_outline;
      iconColor = Colors.red;
    } else if (widget.imageName.contains("warning")) {
      iconData = Icons.warning_amber_outlined;
      iconColor = Colors.orange;
    } else if (widget.imageName.contains("removed_wishlist")) {
      iconData = Icons.favorite_border;
      iconColor = Colors.red;
    } else if (widget.imageName.contains("payment_failed")) {
      iconData = Icons.payment_outlined;
      iconColor = Colors.red;
    } else {
      iconData = Icons.info_outline;
      iconColor = AppColors.primaryColor;
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5.0 * _opacityAnimation.value,
            sigmaY: 5.0 * _opacityAnimation.value,
          ),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            elevation: 0.0,
            insetPadding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  height: height,
                  width: width,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [
                              Color(0xFF2D2D2D),
                              Color(0xFF1A1A1A),
                            ]
                          : [
                              Colors.white,
                              Color(0xFFF8F9FA),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Icon with animated background
                      Container(
                        width: imgSize,
                        height: imgSize,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            iconData,
                            color: iconColor,
                            size: imgSize * 0.6,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Title with nice typography
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),

                      // Message with better readability
                      Text(
                        widget.message,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          letterSpacing: 0.2,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Only show buttons if autoDismiss is false
                      if (!widget.autoDismiss &&
                          widget.primaryButtonText != null)
                        Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: widget.secondaryButtonText != null
                              ? _buildDualButtons()
                              : _buildSingleButton(),
                        ),

                      // Add progress indicator for auto-dismiss
                      if (widget.autoDismiss)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: _buildProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return TweenAnimationBuilder<double>(
      duration: widget.autoDismissDuration,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          height: 2,
          width: Constant.getWidthPercentSize(70) * value,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      },
    );
  }

  Widget _buildSingleButton() {
    return InkWell(
      onTap: () {
        _animationController.reverse().then((_) {
          Navigator.pop(context);

          if (widget.primaryAction != null) {
            widget.primaryAction!();
          }
        });
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryDarkColor,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.25),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.primaryButtonText ?? "",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDualButtons() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              _animationController.reverse().then((_) {
                Navigator.pop(context);

                if (widget.secondaryAction != null) {
                  widget.secondaryAction!();
                }
              });
            },
            child: Container(
              height: 50,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  widget.secondaryButtonText ?? "",
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () {
              _animationController.reverse().then((_) {
                Navigator.pop(context);

                if (widget.primaryAction != null) {
                  widget.primaryAction!();
                }
              });
            },
            child: Container(
              height: 50,
              margin: EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryDarkColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.primaryButtonText ?? "",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ModernNotification {
  static void show({
    required BuildContext context,
    required String message,
    NotificationType type = NotificationType.success,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    // Thêm phản hồi xúc giác dựa vào loại thông báo
    switch (type) {
      case NotificationType.success:
        HapticFeedback.lightImpact();
        break;
      case NotificationType.error:
        HapticFeedback.mediumImpact();
        break;
      case NotificationType.warning:
      case NotificationType.info:
        HapticFeedback.selectionClick();
        break;
      case NotificationType.wishlist:
        HapticFeedback.lightImpact();
        break;
    }

    // Đảm bảo overlay đã được tạo
    final overlay = Overlay.of(context);

    // Khai báo biến trước
    late OverlayEntry entry;

    // Khởi tạo OverlayEntry
    entry = OverlayEntry(
      builder: (context) => _ModernNotificationWidget(
        message: message,
        type: type,
        onTap: onTap,
        onDismiss: () {
          entry.remove();
        },
      ),
    );

    // Hiển thị notification
    overlay.insert(entry);

    // Tự động ẩn sau thời gian duration
    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  static void showSuccess(BuildContext context, String message,
      {VoidCallback? onTap}) {
    show(
      context: context,
      message: message,
      type: NotificationType.success,
      onTap: onTap,
    );
  }

  static void showError(BuildContext context, String message,
      {VoidCallback? onTap}) {
    show(
      context: context,
      message: message,
      type: NotificationType.error,
      onTap: onTap,
    );
  }

  static void showInfo(BuildContext context, String message,
      {VoidCallback? onTap}) {
    show(
      context: context,
      message: message,
      type: NotificationType.info,
      onTap: onTap,
    );
  }

  static void showWarning(BuildContext context, String message,
      {VoidCallback? onTap}) {
    show(
      context: context,
      message: message,
      type: NotificationType.warning,
      onTap: onTap,
    );
  }
}

class _ModernNotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _ModernNotificationWidget({
    Key? key,
    required this.message,
    required this.type,
    this.onTap,
    required this.onDismiss,
  }) : super(key: key);

  @override
  _ModernNotificationWidgetState createState() =>
      _ModernNotificationWidgetState();
}

class _ModernNotificationWidgetState extends State<_ModernNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  // Thêm biến cho hiệu ứng rung
  late Animation<double> _shakeAnimation;
  bool _isShaking = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    // Tạo hiệu ứng rung cho thông báo lỗi
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();

    // Nếu là thông báo lỗi, thêm hiệu ứng rung
    if (widget.type == NotificationType.error) {
      Future.delayed(Duration(milliseconds: 600), () {
        _startShaking();
      });
    }

    // Thêm hiệu ứng nhấp nháy khi thông báo sắp hết thời gian
    Future.delayed(Duration(seconds: 2), () {
      if (mounted &&
          !_controller.isAnimating &&
          _opacityAnimation.value > 0.9) {
        _pulseNotification();
      }
    });
  }

  // Hàm tạo hiệu ứng rung
  void _startShaking() {
    if (!mounted) return;
    setState(() {
      _isShaking = true;
    });

    Future.delayed(Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _isShaking = false;
        });
      }
    });
  }

  // Hiệu ứng nhấp nháy khi sắp hết thời gian
  void _pulseNotification() {
    if (!mounted) return;

    // Tạo hiệu ứng nhấp nháy nhẹ
    Future.delayed(Duration(milliseconds: 150), () {
      if (mounted && _opacityAnimation.value > 0.9) {
        setState(() {
          // Giảm độ mờ một chút để tạo hiệu ứng nhấp nháy
        });
        Future.delayed(Duration(milliseconds: 150), () {
          if (mounted && _opacityAnimation.value > 0.9) {
            setState(() {
              // Trở lại bình thường
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Lấy màu dựa trên loại thông báo
  Color _getBackgroundColor() {
    // Màu nền tối cho tất cả thông báo
    return Color(0xFF1A2429).withOpacity(0.85);
  }

  // Lấy màu viền dựa vào loại thông báo
  Color _getBorderColor() {
    switch (widget.type) {
      case NotificationType.success:
        return DarkThemeColors.accentColor.withOpacity(0.5);
      case NotificationType.error:
        return Colors.redAccent.withOpacity(0.5);
      case NotificationType.warning:
        return Colors.orangeAccent.withOpacity(0.5);
      case NotificationType.info:
        return Colors.blueAccent.withOpacity(0.5);
      case NotificationType.wishlist:
        return Colors.pinkAccent.withOpacity(0.5);
    }
  }

  // Lấy icon dựa trên loại thông báo
  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.error:
        return Icons.error_rounded;
      case NotificationType.warning:
        return Icons.warning_rounded;
      case NotificationType.info:
        return Icons.info_rounded;
      case NotificationType.wishlist:
        return Icons.favorite_rounded;
    }
  }

  // Lấy màu accent cho các phần tử bên trong thông báo
  Color _getAccentColor() {
    switch (widget.type) {
      case NotificationType.success:
        return DarkThemeColors.accentColor;
      case NotificationType.error:
        return Colors.redAccent;
      case NotificationType.warning:
        return Colors.orangeAccent;
      case NotificationType.info:
        return Colors.blueAccent;
      case NotificationType.wishlist:
        return Colors.pinkAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: 50.0 + _slideAnimation.value,
          left: 16.0,
          right: 16.0,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder(
                duration: Duration(milliseconds: 200),
                tween: Tween<double>(begin: 1.0, end: _isShaking ? 1.03 : 1.0),
                builder: (context, double scale, child) {
                  return Transform.translate(
                    offset: _isShaking
                        ? Offset(
                            sin(DateTime.now().millisecondsSinceEpoch * 0.01) *
                                3,
                            0)
                        : Offset.zero,
                    child: Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    if (widget.onTap != null) {
                      widget.onTap!();
                    }
                    _controller.reverse().then((_) {
                      widget.onDismiss();
                    });
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: _getBackgroundColor(),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getBorderColor(),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getAccentColor().withOpacity(0.1),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Icon container với hiệu ứng glow
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getAccentColor().withOpacity(0.15),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _getAccentColor().withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getIcon(),
                                color: _getAccentColor(),
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                widget.message,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: Colors.white.withOpacity(0.7),
                                size: 20,
                              ),
                              onPressed: () {
                                _controller.reverse().then((_) {
                                  widget.onDismiss();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum NotificationType {
  success,
  error,
  warning,
  info,
  wishlist,
}

class _ToastNotification extends StatefulWidget {
  final String title;
  final String message;
  final NotificationType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastNotification({
    Key? key,
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  }) : super(key: key);

  @override
  _ToastNotificationState createState() => _ToastNotificationState();
}

class _ToastNotificationState extends State<_ToastNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1), // Start above the screen
      end: Offset(0, 0), // End at the top of the screen
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    // Start the animation when the widget is built
    _animationController.forward();

    // Schedule dismiss after the duration
    Future.delayed(widget.duration - Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get icon and color based on notification type
    IconData iconData;
    Color backgroundColor;

    switch (widget.type) {
      case NotificationType.success:
        iconData = Icons.check; // Simple check icon
        backgroundColor = AppColors.primaryColor; // Use app's primary color
        break;
      case NotificationType.error:
        iconData = Icons.error_outline;
        backgroundColor = Colors.red;
        break;
      case NotificationType.warning:
        iconData = Icons.warning_amber_outlined;
        backgroundColor = Colors.orange;
        break;
      case NotificationType.wishlist:
        iconData = Icons.favorite;
        backgroundColor = AppColors.primaryColor; // Use app's primary color
        break;
      case NotificationType.info:
      default:
        iconData = Icons.info_outline;
        backgroundColor = AppColors.primaryColor;
        break;
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Material(
                elevation: 0,
                shadowColor: Colors.transparent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Use a simple icon for cleaner look
                      Icon(
                        iconData,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.message.isNotEmpty
                              ? widget.message
                              : widget.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
