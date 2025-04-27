import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeController {
  static const String _fontSizeKey = 'app_font_size_factor';
  static const double _defaultFontSize = 1.0;
  static const double _minFontSize = 0.8;
  static const double _maxFontSize = 1.5;

  // Predefined font size levels for Vietnamese text
  static const Map<String, double> _fontSizeLevels = {
    'Nhỏ': 0.85,
    'Vừa': 1.0,
    'Lớn': 1.2,
    'Rất lớn': 1.4,
  };

  static double _fontSizeFactor = _defaultFontSize;
  static final List<VoidCallback> _listeners = [];

  // Getter for font size factor
  static double get fontSizeFactor => _fontSizeFactor;

  // Getter for predefined font size levels
  static Map<String, double> get fontSizeLevels => _fontSizeLevels;

  // Min/max values
  static double get minFontSize => _minFontSize;
  static double get maxFontSize => _maxFontSize;

  // Initialize by loading saved font size
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSizeFactor = prefs.getDouble(_fontSizeKey) ?? _defaultFontSize;
    _notifyListeners();
  }

  // Set font size factor and save to preferences
  static Future<void> setFontSizeFactor(double factor) async {
    if (factor < _minFontSize) factor = _minFontSize;
    if (factor > _maxFontSize) factor = _maxFontSize;

    if (_fontSizeFactor != factor) {
      _fontSizeFactor = factor;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, factor);
      _notifyListeners();
    }
  }

  // Set font size by preset name
  static Future<void> setFontSizeByPreset(String presetName) async {
    if (_fontSizeLevels.containsKey(presetName)) {
      await setFontSizeFactor(_fontSizeLevels[presetName]!);
    }
  }

  // Add listener for font size changes
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  // Remove listener
  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  // Notify all listeners
  static void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}

// Widget that applies the font size factor to its children
class FontSizeWrapper extends StatefulWidget {
  final Widget child;

  const FontSizeWrapper({Key? key, required this.child}) : super(key: key);

  @override
  _FontSizeWrapperState createState() => _FontSizeWrapperState();
}

class _FontSizeWrapperState extends State<FontSizeWrapper> {
  double _fontSizeFactor = FontSizeController.fontSizeFactor;

  @override
  void initState() {
    super.initState();
    FontSizeController.addListener(_updateFontSize);
  }

  @override
  void dispose() {
    FontSizeController.removeListener(_updateFontSize);
    super.dispose();
  }

  void _updateFontSize() {
    setState(() {
      _fontSizeFactor = FontSizeController.fontSizeFactor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: _fontSizeFactor,
      ),
      child: widget.child,
    );
  }
}
