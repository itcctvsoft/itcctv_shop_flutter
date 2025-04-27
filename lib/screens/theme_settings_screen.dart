import 'package:flutter/material.dart';
import '../constants/color_data.dart';
import '../widgets/theme_selector.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  _ThemeSettingsScreenState createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  bool isDarkMode = ThemeController.isDarkMode;

  @override
  void initState() {
    super.initState();
    ThemeController.addListener(_handleThemeChanged);
  }

  @override
  void dispose() {
    ThemeController.removeListener(_handleThemeChanged);
    super.dispose();
  }

  void _handleThemeChanged() {
    setState(() {
      isDarkMode = ThemeController.isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        title: Text(
          'Tùy chỉnh giao diện',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme color selector
            ThemeSelector(),

            Divider(color: AppColors.dividerColor, thickness: 1, height: 32),

            // Dark mode toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chế độ tối',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.fontBlack,
                    ),
                  ),
                  Switch(
                    value: isDarkMode,
                    activeColor: AppColors.accentColor,
                    onChanged: (value) {
                      ThemeController.toggleTheme();
                    },
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Chế độ tối giúp giảm mỏi mắt và tiết kiệm pin trên thiết bị OLED.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.greyFont,
                ),
              ),
            ),

            SizedBox(height: 20),

            // Preview section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Xem trước',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.fontBlack,
                ),
              ),
            ),

            // UI Element previews
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: AppColors.cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.palette, color: AppColors.iconColor),
                          SizedBox(width: 8),
                          Text(
                            'Tiêu đề',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.fontBlack,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nội dung văn bản sẽ hiển thị như thế này.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.fontBlack,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Nút bấm'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16), // Add bottom padding
          ],
        ),
      ),
    );
  }
}
