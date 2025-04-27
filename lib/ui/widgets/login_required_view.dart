import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:shoplite/ui/home/home_screen.dart';

class LoginRequiredView extends StatefulWidget {
  final VoidCallback onLoginPressed;
  final VoidCallback? onHomePressed;
  final String featureDescription;
  final IconData featureIcon;

  const LoginRequiredView({
    Key? key,
    required this.onLoginPressed,
    this.onHomePressed,
    this.featureDescription = "tính năng này",
    this.featureIcon = Icons.lock_outline,
  }) : super(key: key);

  @override
  State<LoginRequiredView> createState() => _LoginRequiredViewState();
}

class _LoginRequiredViewState extends State<LoginRequiredView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _buttonScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Start the animation when the widget is built
    _animationController.forward();

    // Añadir vibración para mejorar la experiencia
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double screenWidth = SizeConfig.safeBlockHorizontal! * 100;
    double buttonHeight = Constant.getPercentSize(screenHeight, 7);
    double iconSize = Constant.getPercentSize(screenHeight, 20);

    // Get current brightness
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    // Use appropriate colors based on theme
    final backgroundColor = isDarkMode
        ? DarkThemeColors.backgroundColor
        : LightThemeColors.backgroundColor;
    final primaryColor = isDarkMode
        ? DarkThemeColors.primaryColor
        : LightThemeColors.primaryColor;
    final accentColor =
        isDarkMode ? DarkThemeColors.accentColor : LightThemeColors.accentColor;

    // Text colors based on current theme
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode
                      ? [
                          backgroundColor,
                          Color(0xFF0A1822),
                        ]
                      : [
                          backgroundColor,
                          backgroundColor.withOpacity(0.9),
                        ],
                ),
              ),
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // Feature icon with glow effect
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                widget.featureIcon,
                                size: iconSize * 0.5,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Title
                        Text(
                          "Đăng nhập để tiếp tục",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            "Bạn cần đăng nhập để truy cập ${widget.featureDescription}",
                            style: TextStyle(
                              fontSize: 16,
                              color: secondaryTextColor,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Buttons container
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 30),
                          child: Column(
                            children: [
                              // Login button with animation and gradient
                              Transform.scale(
                                scale: _buttonScaleAnimation.value,
                                child: ElevatedButton(
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    widget.onLoginPressed();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 8,
                                    shadowColor: accentColor.withOpacity(0.5),
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [primaryColor, accentColor],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      width: screenWidth * 0.8,
                                      height: buttonHeight,
                                      alignment: Alignment.center,
                                      child: Text(
                                        "ĐĂNG NHẬP",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Browse products button
                              Transform.scale(
                                scale: _buttonScaleAnimation.value,
                                child: OutlinedButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    if (widget.onHomePressed != null) {
                                      widget.onHomePressed!();
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textColor,
                                    side: BorderSide(
                                        color: textColor.withOpacity(0.3),
                                        width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Container(
                                    width: screenWidth * 0.8,
                                    height: buttonHeight,
                                    alignment: Alignment.center,
                                    child: Text(
                                      "XEM SẢN PHẨM",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
