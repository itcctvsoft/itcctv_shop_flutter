import 'package:flutter/material.dart';
import '../../../constants/color_data.dart';
import '../../../widgets/theme_selector.dart';
import '../../../widgets/font_size_selector.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  _ThemeSettingsScreenState createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen>
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: Container(
          height: 65 + MediaQuery.of(context).padding.top,
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
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tùy chỉnh giao diện',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Spacer(),
                  _buildDarkModeToggle(),
                ],
              ),
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

          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: 65 + MediaQuery.of(context).padding.top + 16,
                bottom: 24,
                left: 16,
                right: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme color selector
                  Card(
                    elevation: 4,
                    shadowColor: AppColors.shadowColor.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: AppColors.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.palette,
                                  color: AppColors.iconColor, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Màu sắc chủ đề',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.fontBlack,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Theme selector widget
                          ThemeSelector(),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Font size section
                  Card(
                    elevation: 4,
                    shadowColor: AppColors.shadowColor.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: AppColors.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.text_fields,
                                  color: AppColors.iconColor, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Kích thước chữ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.fontBlack,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Font size selector widget
                          FontSizeSelector(),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Preview section
                  Card(
                    elevation: 4,
                    shadowColor: AppColors.shadowColor.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: AppColors.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.visibility,
                                  color: AppColors.iconColor, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Xem trước',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.fontBlack,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.backgroundColor.withOpacity(0.5)
                                  : AppColors.primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.dividerColor,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Sample UI elements
                                Text(
                                  'Tiêu đề',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.fontBlack,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Nội dung văn bản sẽ hiển thị như thế này.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.fontBlack,
                                    height: 1.5,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.info,
                                        size: 18, color: AppColors.iconColor),
                                    SizedBox(width: 8),
                                    Text(
                                      'Thông tin phụ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.greyFont,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.buttonColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text('Nút bấm'),
                                    ),
                                    OutlinedButton(
                                      onPressed: () {},
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryColor,
                                        side: BorderSide(
                                            color: AppColors.primaryColor),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text('Hủy'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
