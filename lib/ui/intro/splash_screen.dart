// ignore: file_names
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/pref_data.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:shoplite/constants/widget_utils.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/ui/home/home_screen.dart';
import '../../repositories/sitesetting_repository.dart';
import '../login/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/providers/auth_service_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final ProfileRepository _repository = ProfileRepository();
  String? siteName;
  String? logoUrl;
  @override
  void initState() {
    super.initState();
    _loadDataAndNavigate();
  }

  Future<void> _loadDataAndNavigate() async {
    // Gọi API để lấy site setting và lưu trữ
    final settings = await _repository.loadSiteSetting();
    siteName = settings['site_name'];
    logoUrl = settings['logo_url'];

    if (siteName != null && logoUrl != null) {
      // Nếu đã có dữ liệu, hiển thị ngay thông tin đã lưu
      setState(() {});
    }

    await _repository.fetchAndSaveSiteSetting();

    // After settings are loaded, check authentication status
    await _checkAuth();
  }

  Future<void> _checkAuth() async {
    print('Checking authentication status at splash screen...');
    try {
      final isAuthenticated = await PrefData.isAuthenticated();
      print('Authentication check result: $isAuthenticated');

      // Lấy token nếu có (không bắt buộc)
      final token = await PrefData.getToken();
      if (token.isNotEmpty) {
        // Cập nhật token toàn cục nếu có
        g_token = token;
        print('Token retrieved: PRESENT');

        // Nếu đã đăng nhập, cập nhật trạng thái session
        if (isAuthenticated) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('currentSessionLoggedIn', true);

          // Log trạng thái đăng nhập để debug
          bool loginFlag1 = prefs.getBool(PrefData.isLoggedIn) ?? false;
          bool loginFlag2 = prefs.getBool('isLoggedIn') ?? false;
          bool loginFlag3 =
              prefs.getBool('com.example.shoppingisLoggedIn') ?? false;
          bool currentSessionFlag =
              prefs.getBool('currentSessionLoggedIn') ?? false;

          print('Login flags check:');
          print('- Standard key: $loginFlag1');
          print('- Simple key: $loginFlag2');
          print('- Full key: $loginFlag3');
          print('- Current session: $currentSessionFlag');
        }
      } else {
        print('Token retrieved: EMPTY');
      }

      // Cập nhật trạng thái xác thực trong provider
      if (mounted) {
        await ref.read(authStateProvider.notifier).refreshAuthState();
      }

      // THAY ĐỔI QUAN TRỌNG: Luôn chuyển người dùng đến HomeScreen bất kể trạng thái đăng nhập
      if (mounted) {
        print('Navigating to HomeScreen regardless of authentication status');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      print('Error during authentication check: $e');
      // Vẫn chuyển đến HomeScreen ngay cả khi có lỗi
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double screenHeight = SizeConfig.safeBlockVertical! * 100;

    double iconSize = Constant.getPercentSize(screenHeight, 10);

    return PopScope(
      onPopInvokedWithResult: (context, result) {
        // Handle back navigation
        Constant.backToFinish(context as BuildContext);
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(Constant.getPercentSize(iconSize, 25)),
                child: logoUrl == null
                    ? getSvgImage("logo_img.svg", iconSize, color: fontBlack)
                    : Image.network(
                        logoUrl!,
                        width: iconSize,
                        height: iconSize,
                        fit: BoxFit.fill,
                        color: fontBlack,
                      ),
              ),
              getCustomText(
                  siteName ?? "SHOPPING",
                  fontBlack,
                  1,
                  TextAlign.center,
                  FontWeight.w900,
                  Constant.getPercentSize(screenHeight, 5.5)),
            ],
          ),
        ),
      ),
    );
  }
}
