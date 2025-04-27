import 'package:flutter/material.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/ui/intro/splash_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shoplite/ui/blog/blog_screen.dart';
import 'package:shoplite/providers/blog_provider.dart';
import 'package:shoplite/ui/login/login_screen.dart';
import 'package:shoplite/widgets/font_size_controller.dart';

// Create a provider for BlogProvider
final blogProvider = ChangeNotifierProvider((ref) => BlogProvider());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize theme controller
  await ThemeController.init();

  // Initialize font size controller
  await FontSizeController.initialize();

  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = ThemeController.isDarkMode;

  @override
  void initState() {
    super.initState();
    // Listen for theme changes
    ThemeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    // Remove listener when app is disposed
    ThemeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  // Update UI when theme changes
  void _onThemeChanged() {
    setState(() {
      _isDarkMode = ThemeController.isDarkMode;
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Define theme based on current mode
    ThemeData themeData = _isDarkMode
        ? ThemeData(
            primaryColor: AppColors.primaryColor,
            primaryColorDark: AppColors.primaryDarkColor,
            primaryColorLight: AppColors.accentColor,
            scaffoldBackgroundColor: AppColors.backgroundColor,
            brightness: Brightness.dark,
            cardColor: AppColors.cardColor,
            dividerColor: AppColors.dividerColor,
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryColor,
              secondary: AppColors.accentColor,
              background: AppColors.backgroundColor,
              surface: AppColors.cardColor,
              onPrimary: AppColors.fontLight,
              onSecondary: AppColors.fontLight,
              onBackground: AppColors.fontBlack,
              onSurface: AppColors.fontBlack,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.appBarColor,
              foregroundColor: AppColors.fontLight,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.fontLight),
              actionsIconTheme: IconThemeData(color: AppColors.iconColor),
            ),
            iconTheme: IconThemeData(color: AppColors.iconColor),
            buttonTheme: ButtonThemeData(
              buttonColor: AppColors.buttonColor,
              textTheme: ButtonTextTheme.primary,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(AppColors.buttonColor),
                foregroundColor: MaterialStateProperty.all(AppColors.fontLight),
              ),
            ),
            textTheme: Typography.material2021().white.copyWith(
                  bodyMedium: TextStyle(color: AppColors.fontBlack),
                  bodyLarge: TextStyle(color: AppColors.fontBlack),
                  titleMedium: TextStyle(color: AppColors.fontBlack),
                ),
          )
        : ThemeData(
            primaryColor: AppColors.primaryColor,
            primaryColorDark: AppColors.primaryDarkColor,
            primaryColorLight: AppColors.accentColor,
            scaffoldBackgroundColor: AppColors.backgroundColor,
            brightness: Brightness.light,
            cardColor: AppColors.cardColor,
            dividerColor: AppColors.dividerColor,
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              secondary: AppColors.accentColor,
              background: AppColors.backgroundColor,
              surface: AppColors.cardColor,
              onPrimary: AppColors.fontLight,
              onSecondary: AppColors.fontLight,
              onBackground: AppColors.fontBlack,
              onSurface: AppColors.fontBlack,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.appBarColor,
              foregroundColor: AppColors.fontLight,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.fontLight),
              actionsIconTheme: IconThemeData(color: AppColors.iconColor),
            ),
            iconTheme: IconThemeData(color: AppColors.iconColor),
            buttonTheme: ButtonThemeData(
              buttonColor: AppColors.buttonColor,
              textTheme: ButtonTextTheme.primary,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(AppColors.buttonColor),
                foregroundColor: MaterialStateProperty.all(AppColors.fontLight),
              ),
            ),
            textTheme: Typography.material2021().black.copyWith(
                  bodyMedium: TextStyle(color: AppColors.fontBlack),
                  bodyLarge: TextStyle(color: AppColors.fontBlack),
                  titleMedium: TextStyle(color: AppColors.fontBlack),
                ),
          );

    return MaterialApp(
      key: ThemeController.appKey,
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: FontSizeWrapper(
        child: const SplashScreen(),
      ),
      // Định nghĩa các route cho ứng dụng
      builder: (context, child) {
        return FontSizeWrapper(child: child!);
      },
    );
  }
}
