// ignore: file_names
import 'package:flutter/material.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/ui/login/change_password_screen.dart';
import 'package:shoplite/ui/theme/theme_settings_screen.dart';
import '../../../constants/constant.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SettingScreen();
  }
}

class _SettingScreen extends State<SettingScreen>
    with SingleTickerProviderStateMixin {
  bool isDarkMode = ThemeController.isDarkMode;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    ThemeController.addListener(_handleThemeChanged);

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create animation
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Set initial animation value based on theme
    if (isDarkMode) {
      _animationController.value = 1.0;
    } else {
      _animationController.value = 0.0;
    }
  }

  @override
  void dispose() {
    ThemeController.removeListener(_handleThemeChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _handleThemeChanged() {
    setState(() {
      isDarkMode = ThemeController.isDarkMode;
    });
  }

  // Toggle dark mode with animation
  void _toggleDarkMode() async {
    if (isDarkMode) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }

    await ThemeController.toggleTheme();
    setState(() {
      isDarkMode = ThemeController.isDarkMode;
    });
  }

  backClick() {
    Constant.backToFinish(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDarkMode
                      ? AppColors.primaryDarkColor.withOpacity(1.0)
                      : AppColors.primaryDarkColor,
                  isDarkMode
                      ? AppColors.primaryColor.withOpacity(1.0)
                      : AppColors.primaryColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor.withOpacity(0.3),
                  offset: const Offset(0, 3),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                "Tùy chỉnh giao diện",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: backClick,
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _buildDarkModeToggle(),
                ),
              ],
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDarkMode
                        ? AppColors.primaryColor.withOpacity(0.2)
                        : AppColors.primaryColor.withOpacity(0.05),
                    isDarkMode ? const Color(0xFF121212) : Colors.white,
                  ],
                  stops: isDarkMode ? const [0.0, 0.35] : const [0.0, 0.3],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                top: 56 + MediaQuery.of(context).padding.top + 16,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    context: context,
                    icon: Icons.lock,
                    title: "Đổi mật khẩu",
                    onTap: () {
                      Constant.sendToScreen(
                          const ChangePasswordScreen(), context);
                    },
                  ),
                  SizedBox(height: 12),
                  _buildSettingItem(
                    context: context,
                    icon: Icons.palette,
                    title: "Tùy chỉnh giao diện",
                    onTap: () {
                      Constant.sendToScreen(
                          const ThemeSettingsScreen(), context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.iconColor,
                  size: 24,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.fontBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.greyFont,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced dark mode toggle
  Widget _buildDarkModeToggle() {
    return GestureDetector(
      onTap: _toggleDarkMode,
      child: Container(
        width: 60,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: isDarkMode
              ? Colors.grey.shade800
              : Colors.white.withOpacity(0.15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Sun icon
            Positioned(
              left: 5,
              top: 5,
              child: Icon(
                Icons.wb_sunny_rounded,
                size: 20,
                color: isDarkMode ? Colors.grey.shade500 : Colors.white,
              ),
            ),
            // Moon icon
            Positioned(
              right: 5,
              top: 5,
              child: Icon(
                Icons.nightlight_round,
                size: 20,
                color: isDarkMode ? Colors.white : Colors.grey.shade400,
              ),
            ),
            // Animated toggle
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned(
                  left: Tween<double>(begin: 5, end: 35).evaluate(_animation),
                  top: 5,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode
                          ? AppColors.accentColor ?? AppColors.primaryColor
                          : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          spreadRadius: 0,
                          offset: Offset(0, 1),
                        ),
                      ],
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
}
