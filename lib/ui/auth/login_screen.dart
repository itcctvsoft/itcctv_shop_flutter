import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/constants/widget_utils.dart';
import 'package:shoplite/providers/google_auth_provider.dart';
import 'package:shoplite/ui/home/home_screen.dart';
import 'package:shoplite/repositories/google_auth_repository.dart';
import 'package:shoplite/ui/widgets/notification_dialog.dart';
import 'dart:math' as math;

class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({Key? key}) : super(key: key);

  @override
  _GoogleSignInButtonState createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 15), // Thời gian dài hơn để chạy chậm hơn
    );

    // Chạy animation liên tục
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(googleAuthProvider);

    // Lắng nghe sự thay đổi trạng thái một cách an toàn
    ref.listen(
      googleAuthProvider,
      (previous, current) {
        if (current == GoogleAuthStatus.success) {
          // Điều hướng đến màn hình chính
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else if (current == GoogleAuthStatus.error) {
          // Thay đổi: Sử dụng ModernNotification.showError thay vì SnackBar
          final errorMsg = ref.read(googleAuthProvider.notifier).errorMessage;
          ModernNotification.showError(
            context,
            'Đăng nhập thất bại: $errorMsg',
          );
        }
      },
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            if (authState != GoogleAuthStatus.loading) {
              // Add button press animation
              HapticFeedback.lightImpact();

              // Force sign out directly using the repository
              final googleAuthRepo = GoogleAuthRepository();
              await googleAuthRepo.forceSignOut();

              // Then proceed with Google sign-in
              ref
                  .read(googleAuthProvider.notifier)
                  .signInWithGoogle(role: 'customer');
            }
          },
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              child: authState == GoogleAuthStatus.loading
                  ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF4285F4)), // Google blue
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        // Animated Google logo
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: CustomPaint(
                              painter: GoogleLogoPainter(),
                              size: const Size(18, 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Widget MarqueeText đơn giản và không gây overflow
                        Expanded(
                          child: MarqueeText(
                            text: 'Đăng nhập bằng tài khoản Google',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black.withOpacity(0.85),
                              letterSpacing: 0.2,
                            ),
                            speed: 20, // Tốc độ chạy chữ (pixel/giây)
                            controller: _animationController,
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

// Google Logo Painter with modern styling
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Official Google logo colors
    final Color red = Color(0xFFEA4335); // Google red
    final Color green = Color(0xFF34A853); // Google green
    final Color yellow = Color(0xFFFBBC05); // Google yellow
    final Color blue = Color(0xFF4285F4); // Google blue

    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1
      ..isAntiAlias = true; // Make edges smoother

    // Calculate dimensions for a perfectly sized logo
    final double logoSize = math.min(width, height);
    final double centerX = width / 2;
    final double centerY = height / 2;
    final double radius = logoSize / 2;

    // Draw the Google logo segments with smoother connections

    // Blue arc (left portion)
    paint.color = blue;
    final Path bluePath = Path();
    bluePath.moveTo(centerX, centerY);
    bluePath.lineTo(centerX - radius * 0.7, centerY - radius * 0.7);
    bluePath.arcTo(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        -math.pi * 3 / 4, // start angle
        -math.pi / 2, // sweep angle (counterclockwise)
        false);
    bluePath.close();
    canvas.drawPath(bluePath, paint);

    // Red arc (top portion)
    paint.color = red;
    final Path redPath = Path();
    redPath.moveTo(centerX, centerY);
    redPath.lineTo(centerX + radius * 0.7, centerY - radius * 0.7);
    redPath.arcTo(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        -math.pi / 4, // start angle
        -math.pi / 2, // sweep angle (counterclockwise)
        false);
    redPath.close();
    canvas.drawPath(redPath, paint);

    // Yellow arc (right portion)
    paint.color = yellow;
    final Path yellowPath = Path();
    yellowPath.moveTo(centerX, centerY);
    yellowPath.lineTo(centerX + radius * 0.7, centerY + radius * 0.7);
    yellowPath.arcTo(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        math.pi / 4, // start angle
        math.pi / 2, // sweep angle
        false);
    yellowPath.close();
    canvas.drawPath(yellowPath, paint);

    // Green arc (bottom portion)
    paint.color = green;
    final Path greenPath = Path();
    greenPath.moveTo(centerX, centerY);
    greenPath.lineTo(centerX - radius * 0.7, centerY + radius * 0.7);
    greenPath.arcTo(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        math.pi * 3 / 4, // start angle
        math.pi / 2, // sweep angle
        false);
    greenPath.close();
    canvas.drawPath(greenPath, paint);

    // White center circle
    paint.color = Colors.white;
    canvas.drawCircle(
        Offset(centerX, centerY),
        radius * 0.5, // slightly larger white circle for modern look
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Widget để tạo hiệu ứng chạy chữ không bị overflow
class MarqueeText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double speed;
  final AnimationController controller;

  const MarqueeText({
    Key? key,
    required this.text,
    required this.style,
    this.speed = 25, // Tốc độ mặc định (pixel/giây)
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textWidth = _getTextWidth(text, style);
        final containerWidth = constraints.maxWidth;

        // Nếu text ngắn hơn container, không cần animation
        if (textWidth < containerWidth) {
          return Text(text, style: style);
        }

        // Tạo hiệu ứng chạy chữ
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: const [0.0, 0.05, 0.95, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              // Tính toán offset dựa trên thời gian và tốc độ
              final offset =
                  (controller.value * textWidth) % (textWidth + containerWidth);

              return ClipRect(
                child: SizedBox(
                  height: 30,
                  width: containerWidth,
                  child: Stack(
                    children: [
                      // Text cơ bản
                      Positioned(
                        left: containerWidth - offset,
                        child: Text(text, style: style),
                      ),
                      // Text thứ hai để tạo liên tục
                      Positioned(
                        left: containerWidth * 2 - offset - textWidth,
                        child: Text(text, style: style),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Hàm ước tính chiều rộng của text
  double _getTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    return textPainter.width;
  }
}
