import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/constants/pref_data.dart';
import 'package:shoplite/ui/home/tabscreen/tab_cart.dart';
import 'package:shoplite/ui/home/tabscreen/tab_favourite.dart';
import 'package:shoplite/ui/home/tabscreen/tab_home.dart';
import 'package:shoplite/ui/home/tabscreen/tab_profile.dart';
import 'package:shoplite/ui/login/login_screen.dart';
import 'package:shoplite/models/profile.dart';
import 'package:shoplite/providers/profile_provider.dart';
import 'package:shoplite/providers/product_provider.dart';
import 'package:shoplite/ui/widgets/login_required_view.dart';
import 'package:shoplite/ui/blog/blog_screen.dart';
import '../../constants/custom_animated_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int selectedTab;

  HomeScreen({Key? key, this.selectedTab = 0}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _HomeScreen();
  }
}

class _HomeScreen extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  int currentPos = 0;
  final Color _activeColor = AppColors.primaryColor;
  late Color _inactiveColor;
  bool isDarkMode = false;
  bool _isLoggedIn = false;

  // Các tên icon
  final Map<String, String> _iconNames = {
    'home': 'Home.svg',
    'favourite': 'heart.svg',
    'cart': 'Bag.svg',
    'blog': 'Document.svg',
    'profile': 'User.svg',
  };

  @override
  void initState() {
    super.initState();
    // Nếu không chỉ định tab, mặc định chọn Home (vị trí 2)
    currentPos = widget.selectedTab == 0 ? 2 : widget.selectedTab;
    isDarkMode = ThemeController.isDarkMode;
    _updateInactiveColor();
    ThemeController.addListener(_onThemeChanged);

    // Add as a WidgetsBinding observer to detect app resume
    WidgetsBinding.instance.addObserver(this);

    // Check login status on startup
    _checkLoginStatus();
  }

  @override
  void dispose() {
    ThemeController.removeListener(_onThemeChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // This will be called when the app is resumed from background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh login status when app is resumed
      _checkLoginStatus();
    }
  }

  // Check if the user is logged in
  Future<void> _checkLoginStatus() async {
    print("=========== CHECKING AUTHENTICATION STATUS ===========");
    // First, check token
    String token = await PrefData.getToken();
    print("Token exists: ${token.isNotEmpty} (length: ${token.length})");

    // Then check login flag
    bool loginFlag = await PrefData.isLogIn();
    print("Login flag: $loginFlag");

    // Finally check full authentication
    bool isAuthenticated = await PrefData.isAuthenticated();
    print("Full authentication: $isAuthenticated");

    // If just logged in, also refresh the profile provider data
    if (isAuthenticated && !_isLoggedIn) {
      print("User just logged in, refreshing profile data");
      _refreshProfileData();
    }

    print("=====================================================");

    // Update UI if needed
    if (mounted) {
      if (_isLoggedIn != isAuthenticated) {
        print("Authentication state changed: $_isLoggedIn -> $isAuthenticated");
        setState(() {
          _isLoggedIn = isAuthenticated;
        });
      }
    }
  }

  // Method to refresh profile data from SharedPreferences
  Future<void> _refreshProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail');
      final userName = prefs.getString('userName');

      print("Home: Refreshing profile data");
      print("- userEmail from SharedPreferences: $userEmail");
      print("- userName from SharedPreferences: $userName");

      // Since we can't directly call the private method, simulate a profile update
      // by updating the SharedPreferences and creating a temporary profile
      if (userEmail != null && userName != null) {
        final profile = Profile(
            email: userEmail,
            full_name: userName,
            phone: prefs.getString('userPhone') ?? '',
            address: prefs.getString('userAddress') ?? '',
            photo: prefs.getString('userPhoto') ?? '',
            username: prefs.getString('username') ?? userEmail.split('@')[0]);

        // Update the profile in provider
        ref.read(profileProvider.notifier).updateProfile(profile);
      }
    } catch (e) {
      print("Error refreshing profile data: $e");
    }
  }

  // Check if tab requires authentication
  bool _tabRequiresAuth(int index) {
    // Favourite (0) và Cart (1) tabs yêu cầu xác thực
    // Home (2), Blog (3) và Profile (4) không yêu cầu xác thực
    return index < 2;
  }

  // Handle tab selection with authentication check
  void _onTabSelected(int index) {
    // Cho phép người dùng chọn tab ngay cả khi chưa đăng nhập
    // LoginRequiredView sẽ hiển thị trong tab đó
    setState(() => currentPos = index);

    // Khi người dùng chưa đăng nhập và cố chọn tab yêu cầu đăng nhập,
    // hiển thị dialog đăng nhập cho trải nghiệm tốt hơn
    if (_tabRequiresAuth(index) && !_isLoggedIn) {
      _showLoginRequiredDialog(index);
    }
  }

  // Update inactive color based on dark mode
  void _updateInactiveColor() {
    _inactiveColor = isDarkMode
        ? Colors.white.withOpacity(0.7)
        : Colors.black.withOpacity(0.7);
  }

  // Handle theme changes
  void _onThemeChanged() {
    setState(() {
      isDarkMode = ThemeController.isDarkMode;
      _updateInactiveColor();
    });

    // Force rebuild bottom navigation bar with new colors
    if (mounted) {
      setState(() {});
    }
  }

  // Navigate to login screen
  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    ).then((_) {
      // Refresh login status when returning from login screen
      _checkLoginStatus();

      // Force UI update with a small delay to ensure SharedPreferences is updated
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _checkLoginStatus();
        }
      });
    });
  }

  // Placeholder method to satisfy the compiler
  void _loadUserData() {
    // This method is a placeholder to fix compilation issues
    // It should not be called
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double bottomHeight = Constant.getPercentSize(screenHeight, 8.5);
    double iconHeight = Constant.getPercentSize(bottomHeight, 28);

    // Force refresh login status on each build (this helps catch changes made externally)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });

    // Update colors based on current theme
    _updateInactiveColor();
    final activeColor = AppColors.primaryColor;

    // Lấy thông tin Profile từ profileProvider
    final Profile userProfile = ref.watch(profileProvider).profile;

    // Tạo danh sách các Tab với authentication check
    final List<Widget> listImages = [
      // For restricted tabs, show login required view if not logged in
      _isLoggedIn
          ? const TabFavourite()
          : LoginRequiredView(
              onLoginPressed: _navigateToLogin,
              onHomePressed: () =>
                  setState(() => currentPos = 2), // Cập nhật vị trí Home
              featureDescription: "danh sách yêu thích",
              featureIcon: Icons.favorite_border,
            ),
      _isLoggedIn
          ? const TabCart()
          : LoginRequiredView(
              onLoginPressed: _navigateToLogin,
              onHomePressed: () =>
                  setState(() => currentPos = 2), // Cập nhật vị trí Home
              featureDescription: "giỏ hàng",
              featureIcon: Icons.shopping_cart_outlined,
            ),
      const TabHome(), // Home ở vị trí giữa (2)
      // Tab Blog tạm thời dùng Scaffold đơn giản
      const BlogScreen(),
      // Always show TabProfile, but pass isLoggedIn status
      TabProfile(
        email: _isLoggedIn ? userProfile.email : '',
        fullName: _isLoggedIn ? userProfile.full_name : '',
        isLoggedIn: _isLoggedIn,
        onLoginPressed: _navigateToLogin,
      ),
    ];

    return WillPopScope(
      onWillPop: () async {
        Constant.closeApp();
        return false;
      },
      child: Scaffold(
        body: listImages[currentPos],
        bottomNavigationBar: CustomAnimatedBottomBar(
          containerHeight: bottomHeight,
          backgroundColor: AppColors.cardColor,
          selectedIndex: currentPos,
          showElevation: true,
          itemCornerRadius: 24,
          curve: Curves.easeIn,
          totalItemCount: 5,
          onItemSelected: (index) {
            if (_tabRequiresAuth(index) && !_isLoggedIn) {
              // Show login notification when trying to access restricted tabs
              _showLoginRequiredDialog(index);
            } else {
              setState(() => currentPos = index);
            }
          },
          items: <BottomNavyBarItem>[
            BottomNavyBarItem(
              title: 'Favourite',
              activeColor: activeColor,
              inactiveColor: _inactiveColor,
              textAlign: TextAlign.center,
              iconSize: iconHeight,
              imageName: _iconNames['favourite']!,
              useDarkModeColor: isDarkMode,
            ),
            BottomNavyBarItem(
              title: 'Cart',
              activeColor: activeColor,
              inactiveColor: _inactiveColor,
              textAlign: TextAlign.center,
              iconSize: iconHeight,
              imageName: _iconNames['cart']!,
              useDarkModeColor: isDarkMode,
            ),
            BottomNavyBarItem(
              title: 'Home',
              activeColor: activeColor,
              inactiveColor: _inactiveColor,
              textAlign: TextAlign.center,
              iconSize: iconHeight,
              imageName: _iconNames['home']!,
              useDarkModeColor: isDarkMode,
            ),
            BottomNavyBarItem(
              title: 'Blog',
              activeColor: activeColor,
              inactiveColor: _inactiveColor,
              textAlign: TextAlign.center,
              iconSize: iconHeight,
              imageName: _iconNames['blog']!,
              useDarkModeColor: isDarkMode,
            ),
            BottomNavyBarItem(
              title: 'Profile',
              activeColor: activeColor,
              inactiveColor: _inactiveColor,
              textAlign: TextAlign.center,
              iconSize: iconHeight,
              imageName: _iconNames['profile']!,
              useDarkModeColor: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  // Show login required dialog
  void _showLoginRequiredDialog(int tabIndex) {
    String tabName;
    IconData tabIcon;

    switch (tabIndex) {
      case 0:
        tabName = "danh sách yêu thích";
        tabIcon = Icons.favorite_border;
        break;
      case 1:
        tabName = "giỏ hàng";
        tabIcon = Icons.shopping_cart_outlined;
        break;
      case 3:
        tabName = "blog";
        tabIcon = Icons.article_outlined;
        break;
      case 4:
        tabName = "hồ sơ cá nhân";
        tabIcon = Icons.person_outline;
        break;
      default:
        tabName = "chức năng này";
        tabIcon = Icons.lock_outline;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 15,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon container
              TweenAnimationBuilder(
                duration: Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        tabIcon,
                        color: AppColors.primaryColor,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),

              // Title with animation
              TweenAnimationBuilder(
                duration: Duration(milliseconds: 1000),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: child,
                  );
                },
                child: Text(
                  'Đăng nhập yêu cầu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.fontBlack,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Description with animation
              TweenAnimationBuilder(
                duration: Duration(milliseconds: 1200),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: child,
                  );
                },
                child: Text(
                  'Bạn cần đăng nhập để truy cập $tabName',
                  style: TextStyle(
                    color: AppColors.greyFont,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 30),

              // Buttons with animation
              TweenAnimationBuilder(
                duration: Duration(milliseconds: 1400),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Text(
                        'Để sau',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _navigateToLogin();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 3,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.login_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
