import 'package:flutter/material.dart';
import '../constants/color_data.dart';

class ThemeSelector extends StatefulWidget {
  const ThemeSelector({Key? key}) : super(key: key);

  @override
  State<ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<ThemeSelector> {
  int selectedTheme = ThemeController.currentThemeIndex;

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
      selectedTheme = ThemeController.currentThemeIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Chọn màu chủ đề',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.fontBlack,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12),
            itemCount: ThemeController.themePalettes.length,
            itemBuilder: (context, index) {
              final theme = ThemeController.themePalettes[index];
              final isSelected = index == selectedTheme;

              String displayName = theme.name;
              if (displayName.length > 7) {
                displayName = displayName.substring(0, 7);
              }

              return GestureDetector(
                onTap: () {
                  ThemeController.setTheme(index);
                },
                child: Container(
                  width: 60,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isSelected ? theme.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                      SizedBox(height: 4),
                      Container(
                        width: 56,
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.greyFont,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
