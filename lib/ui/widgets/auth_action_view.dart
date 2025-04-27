import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:shoplite/ui/login/login_screen.dart';

class AuthActionView extends StatefulWidget {
  final String featureDescription;
  final IconData featureIcon;
  final VoidCallback? onBackPressed;
  final bool showAppBar;

  const AuthActionView({
    Key? key,
    this.featureDescription = "sử dụng tính năng này",
    this.featureIcon = Icons.lock_outline,
    this.onBackPressed,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  State<AuthActionView> createState() => _AuthActionViewState();
}

class _AuthActionViewState extends State<AuthActionView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

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
    double iconSize = Constant.getPercentSize(screenHeight, 15);

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
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () {
                  if (widget.onBackPressed != null) {
                    widget.onBackPressed!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            )
          : null,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 24),
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
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon animation with glow effect
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
                        child: Icon(
                          widget.featureIcon,
                          size: iconSize * 0.5,
                          color: accentColor,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),

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
                    SizedBox(height: 16),

                    // Description
                    Text(
                      "Bạn cần đăng nhập để ${widget.featureDescription}",
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryTextColor,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.08),

                    // Login button with gradient
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                        );
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
                          height: 56,
                          alignment: Alignment.center,
                          child: Text(
                            'ĐĂNG NHẬP',
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
                    SizedBox(height: 24),

                    // Back to shopping button
                    OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        if (widget.onBackPressed != null) {
                          widget.onBackPressed!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(
                            color: textColor.withOpacity(0.3), width: 1),
                        minimumSize: Size(screenWidth * 0.8, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'XEM SẢN PHẨM',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
