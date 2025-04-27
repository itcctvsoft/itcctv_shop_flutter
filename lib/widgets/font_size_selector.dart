import 'package:flutter/material.dart';
import '../constants/color_data.dart';
import 'font_size_controller.dart';

class FontSizeSelector extends StatefulWidget {
  const FontSizeSelector({Key? key}) : super(key: key);

  @override
  State<FontSizeSelector> createState() => _FontSizeSelectorState();
}

class _FontSizeSelectorState extends State<FontSizeSelector> {
  double _currentFontSize = FontSizeController.fontSizeFactor;

  @override
  void initState() {
    super.initState();
    FontSizeController.addListener(_handleFontSizeChanged);
  }

  @override
  void dispose() {
    FontSizeController.removeListener(_handleFontSizeChanged);
    super.dispose();
  }

  void _handleFontSizeChanged() {
    setState(() {
      _currentFontSize = FontSizeController.fontSizeFactor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Font size slider
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Kích thước chữ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.fontBlack,
                ),
              ),
            ),
            Slider(
              value: _currentFontSize,
              min: FontSizeController.minFontSize,
              max: FontSizeController.maxFontSize,
              divisions: 7,
              activeColor: AppColors.primaryColor,
              inactiveColor: AppColors.primaryColor.withOpacity(0.3),
              onChanged: (value) {
                setState(() {
                  _currentFontSize = value;
                });
              },
              onChangeEnd: (value) {
                FontSizeController.setFontSizeFactor(value);
              },
            ),
          ],
        ),

        // Font size presets
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: FontSizeController.fontSizeLevels.entries.map((entry) {
              final isSelected = (_currentFontSize - entry.value).abs() < 0.05;

              return GestureDetector(
                onTap: () => FontSizeController.setFontSizeByPreset(entry.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.greyFont.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 14 * entry.value,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.fontBlack,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
