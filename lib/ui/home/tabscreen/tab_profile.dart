// tab_profile.dart
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/constants/pref_data.dart';
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/providers/auth_service_provider.dart';
import 'package:shoplite/ui/login/login_screen.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:shoplite/constants/widget_utils.dart';
import '../../../utils/auth_helpers.dart';
import '../../../constants/constant.dart';
import 'package:shoplite/ui/home/home_screen.dart';
import 'package:shoplite/ui/profile/profile_screen.dart';
import 'package:shoplite/ui/profile/setting_screen.dart';
import 'package:shoplite/ui/order/order_history_screen.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';
import 'package:shoplite/ui/blog/blog_screen.dart';
import '../../intro/splash_screen.dart';
import '../../policy/policy_screen.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shoplite/providers/order_provider.dart';
import 'package:shoplite/models/profile.dart';
import 'package:shoplite/utils/refresh_utils.dart';
import 'package:shoplite/ui/login/change_password_screen.dart';
import '../../theme/theme_settings_screen.dart';
import 'package:shoplite/ui/widgets/notification_dialog.dart';
import 'package:flutter/scheduler.dart';

class TabProfile extends ConsumerStatefulWidget {
  final String email;
  final String fullName;
  final bool isLoggedIn;
  final Function()? onLoginPressed;

  const TabProfile({
    Key? key,
    required this.email,
    required this.fullName,
    this.isLoggedIn = true,
    this.onLoginPressed,
  }) : super(key: key);

  @override
  ConsumerState<TabProfile> createState() => _TabProfileState();
}

class _TabProfileState extends ConsumerState<TabProfile>
    with SingleTickerProviderStateMixin {
  String userEmail = '';
  String userName = '';
  String userPhoto = '';
  bool isLoading = true;
  bool isDarkMode = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller first
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create animation
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Then load user data and initialize dark mode
    _loadUserData();
    _initDarkMode();

    // Add theme change listener
    ThemeController.addListener(_onThemeChanged);

    // Đảm bảo cập nhật thông tin người dùng sau khi build hoàn tất
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getLatestUserData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    ThemeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(TabProfile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If login status changed or user info changed, reload data
    if (oldWidget.isLoggedIn != widget.isLoggedIn ||
        oldWidget.email != widget.email ||
        oldWidget.fullName != widget.fullName) {
      print("TabProfile: Widget props changed, reloading user data");
      print(
          "- Old isLoggedIn: ${oldWidget.isLoggedIn}, New: ${widget.isLoggedIn}");
      print("- Old email: ${oldWidget.email}, New: ${widget.email}");
      print("- Old fullName: ${oldWidget.fullName}, New: ${widget.fullName}");
      _loadUserData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Đơn giản hóa - chỉ kiểm tra thông tin người dùng khi tab được hiển thị
    if (widget.isLoggedIn) {
      _getLatestUserData();
    }
  }

  // Phương thức đơn giản để lấy và cập nhật thông tin người dùng mới nhất
  Future<void> _getLatestUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedName = prefs.getString('userName');
      final String? storedEmail = prefs.getString('userEmail');
      final String? storedPhoto = prefs.getString('userPhoto');

      if (mounted) {
        setState(() {
          if (storedName != null && storedName.isNotEmpty) {
            userName = storedName;
          }
          if (storedEmail != null && storedEmail.isNotEmpty) {
            userEmail = storedEmail;
          }
          if (storedPhoto != null) {
            userPhoto = storedPhoto;
          }
        });
      }
    } catch (e) {
      print("TabProfile: Lỗi khi cập nhật thông tin người dùng: $e");
    }
  }

  // Handle theme changes
  void _onThemeChanged() {
    setState(() {
      isDarkMode = ThemeController.isDarkMode;
    });
  }

  // Initialize dark mode state
  Future<void> _initDarkMode() async {
    setState(() {
      isDarkMode = ThemeController.isDarkMode;
    });

    if (isDarkMode) {
      _animationController.value = 1.0;
    } else {
      _animationController.value = 0.0;
    }
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    if (!widget.isLoggedIn) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    print("TabProfile: Loading user data from SharedPreferences");
    setState(() {
      isLoading = true;
    });

    try {
      await _getLatestUserData();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("TabProfile: Error loading user data: $e");
      setState(() {
        userEmail = widget.email;
        userName = widget.fullName;
        userPhoto = '';
        isLoading = false;
      });
    }
  }

  // Toggle dark mode
  Future<void> _toggleDarkMode() async {
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

  // Helper method to ensure screen dimensions are initialized
  void _initScreenDimensions() {
    SizeConfig().init(context);
  }

  @override
  Widget build(BuildContext context) {
    _initScreenDimensions();
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double screenWidth = SizeConfig.safeBlockHorizontal! * 100;
    double appBarPadding = getAppBarPadding();
    double imgHeight = Constant.getPercentSize(screenHeight, 16);

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          color: AppColors.fontLight,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Tài Khoản",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.fontLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const ChatIconBadge(size: 26),
                      ),
                      const SizedBox(width: 12),
                      buildDarkModeToggle(),
                    ],
                  ),
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
            child: RefreshIndicator(
              onRefresh: () async {
                // Cập nhật thông tin người dùng ngay lập tức
                await _getLatestUserData();
              },
              color: AppColors.primaryColor,
              backgroundColor: AppColors.cardColor,
              child: CustomScrollView(
                slivers: [
                  // Cung cấp không gian cho nội dung bắt đầu dưới app bar
                  SliverPadding(
                    padding: EdgeInsets.only(
                      top: 65 + MediaQuery.of(context).padding.top + 5,
                    ),
                    sliver: SliverToBoxAdapter(child: SizedBox()),
                  ),

                  // Profile section
                  SliverToBoxAdapter(
                    child: widget.isLoggedIn
                        ? buildProfileSection(
                            imgHeight, screenHeight, appBarPadding)
                        : buildLoginSection(
                            imgHeight, screenHeight, appBarPadding),
                  ),

                  // Settings list
                  SliverToBoxAdapter(
                    child: buildSettingsList(appBarPadding, screenHeight),
                  ),

                  // Logout button
                  SliverToBoxAdapter(
                    child: widget.isLoggedIn
                        ? getLoginButton()
                        : SizedBox(
                            height: Constant.getPercentSize(screenHeight, 2.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Profile section for logged in users
  Widget buildProfileSection(
      double imgHeight, double screenHeight, double appBarPadding) {
    return Column(
      children: [
        isLoading
            ? CircularProgressIndicator(color: primaryColor)
            : buildProfileImage(imgHeight),
        getSpace(appBarPadding),
        isLoading
            ? Text("Loading...", style: TextStyle(color: greyFont))
            : buildProfileName(screenHeight),
        getSpace(Constant.getPercentSize(appBarPadding, 50)),
        isLoading ? SizedBox() : buildProfileEmail(screenHeight),
        getSpace(appBarPadding),
      ],
    );
  }

  // Login section for non-logged in users
  Widget buildLoginSection(
      double imgHeight, double screenHeight, double appBarPadding) {
    return Column(
      children: [
        // Generic profile icon
        Container(
          width: imgHeight,
          height: imgHeight,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.dividerColor.withOpacity(0.3),
            border: Border.all(color: AppColors.dividerColor, width: 2),
          ),
          child: Icon(
            Icons.person_outline,
            color: AppColors.primaryColor,
            size: imgHeight * 0.6,
          ),
        ),
        getSpace(appBarPadding),
        Text(
          "Chào mừng bạn đến với ShopLite",
          style: TextStyle(
            fontSize: Constant.getPercentSize(screenHeight, 2.3),
            fontWeight: FontWeight.bold,
            color: fontBlack,
          ),
        ),
        getSpace(Constant.getPercentSize(appBarPadding, 30)),
        Text(
          "Đăng nhập để quản lý tài khoản và mua sắm",
          style: TextStyle(
            fontSize: Constant.getPercentSize(screenHeight, 1.8),
            color: greyFont,
          ),
          textAlign: TextAlign.center,
        ),
        getSpace(appBarPadding),
        // Login button
        Container(
          width: screenHeight * 0.25,
          height: screenHeight * 0.06,
          margin: EdgeInsets.symmetric(vertical: 5),
          child: ElevatedButton(
            onPressed: widget.onLoginPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenHeight * 0.015),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login,
                    color: Colors.white, size: screenHeight * 0.025),
                SizedBox(width: 10),
                Text(
                  "Đăng nhập",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: screenHeight * 0.018,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Register button
        Container(
          width: screenHeight * 0.25,
          height: screenHeight * 0.06,
          margin: EdgeInsets.symmetric(vertical: 5),
          child: OutlinedButton(
            onPressed: widget.onLoginPressed, // Use same action for now
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenHeight * 0.015),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add,
                    color: AppColors.primaryColor, size: screenHeight * 0.025),
                SizedBox(width: 10),
                Text(
                  "Đăng ký",
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: screenHeight * 0.018,
                  ),
                ),
              ],
            ),
          ),
        ),
        getSpace(appBarPadding),
      ],
    );
  }

  Widget buildDarkModeToggle() {
    return GestureDetector(
      onTap: _toggleDarkMode,
      child: Container(
        width: 60,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: isDarkMode ? DarkThemeColors.cardColor : Colors.grey.shade200,
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.1),
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
                color:
                    isDarkMode ? Colors.grey.shade500 : AppColors.primaryColor,
              ),
            ),
            // Moon icon
            Positioned(
              right: 5,
              top: 5,
              child: Icon(
                Icons.nightlight_round,
                size: 20,
                color:
                    isDarkMode ? AppColors.primaryColor : Colors.grey.shade500,
              ),
            ),
            // Animated toggle
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned(
                  left: Tween<double>(begin: 5, end: 30).evaluate(_animation),
                  top: 5,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode
                          ? AppColors.accentColor
                          : AppColors.primaryColor,
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

  Widget buildProfileImage(double imgHeight) {
    return Hero(
      tag: 'profile_image',
      child: Container(
        width: imgHeight,
        height: imgHeight,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.dividerColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: userPhoto.isNotEmpty && userPhoto != 'null'
              ? Image.network(
                  userPhoto,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fall back to default image on error
                    return Image.asset(
                      Constant.assetImagePath + "Profile.png",
                      fit: BoxFit.cover,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor,
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                )
              : Image.asset(
                  Constant.assetImagePath + "Profile.png",
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }

  Widget buildProfileName(double screenHeight) {
    return getCustomText(userName, fontBlack, 1, TextAlign.center,
        FontWeight.bold, Constant.getPercentSize(screenHeight, 2.7));
  }

  Widget buildProfileEmail(double screenHeight) {
    return getCustomText(userEmail, greyFont, 1, TextAlign.center,
        FontWeight.w400, Constant.getPercentSize(screenHeight, 2.2));
  }

  Widget buildSettingsList(double appBarPadding, double screenHeight) {
    return Container(
      margin: EdgeInsets.all(getAppBarPadding()),
      padding: EdgeInsets.only(left: appBarPadding, right: appBarPadding),
      constraints: BoxConstraints(
        maxHeight: screenHeight *
            0.41, // Giảm chiều cao xuống để đưa nút đăng xuất lên cao hơn
      ),
      decoration: ShapeDecoration(
          color: cardColor,
          shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                  cornerRadius: Constant.getPercentSize(screenHeight, 2),
                  cornerSmoothing: 0.5)),
          shadows: [
            BoxShadow(
                color: shadowColor.withOpacity(0.08),
                blurRadius: 8,
                spreadRadius: 2)
          ]),
      child: ListView(
        padding: EdgeInsets.zero,
        primary: false,
        shrinkWrap: true,
        children: buildSettingItems(appBarPadding),
      ),
    );
  }

  List<Widget> buildSettingItems(double appBarPadding) {
    // Full list of settings
    List<Map<String, dynamic>> allSettings = [
      {
        "icon": "User.svg",
        "title": "Thông tin cá nhân",
        "screen": const ProfileScreen(),
        "requiresLogin": true
      },
      {
        "icon": "Document.svg",
        "title": "Lịch sử đơn hàng",
        "screen": const OrderHistoryScreen(),
        "requiresLogin": true
      },
      {
        "icon": "security.svg",
        "title": "Chính sách bảo mật",
        "screen": const PolicyScreen(policyType: PolicyType.privacy),
        "requiresLogin": false
      },
      {
        "icon": "Document.svg",
        "title": "Điều khoản và quy định",
        "screen": const PolicyScreen(policyType: PolicyType.terms),
        "requiresLogin": false
      },
      {
        "icon": "Rotate_Left.svg",
        "title": "Chính sách hoàn trả",
        "screen": const PolicyScreen(policyType: PolicyType.returns),
        "requiresLogin": false
      },
      {
        "icon": "Question.svg",
        "title": "Chính sách bảo hành",
        "screen": const PolicyScreen(policyType: PolicyType.warranty),
        "requiresLogin": false
      },
      {
        "icon": "shipping_location.svg",
        "title": "Chính sách giao vận",
        "screen": const PolicyScreen(policyType: PolicyType.shipping),
        "requiresLogin": false
      },
      {
        "icon": "Setting.svg",
        "title": "Cài đặt",
        "screen": const SettingScreen(),
        "requiresLogin": false
      },
    ];

    // Filter settings based on login status
    List<Map<String, dynamic>> settings = allSettings
        .where((setting) => widget.isLoggedIn || !setting["requiresLogin"])
        .toList();

    List<Widget> items = [];
    for (var setting in settings) {
      items.add(buildSettingRow(setting["icon"], setting["title"], () {
        if (setting["requiresLogin"] && !widget.isLoggedIn) {
          // Show login dialog if user tries to access a restricted setting
          widget.onLoginPressed?.call();
        } else {
          // Xử lý đặc biệt cho ProfileScreen để cập nhật thông tin tức thì
          if (setting["title"] == "Thông tin cá nhân") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => setting["screen"]),
            ).then((result) async {
              // Lấy thông tin hồ sơ mới từ SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              final String? storedName = prefs.getString('userName');
              final String? storedEmail = prefs.getString('userEmail');
              final String? storedPhoto = prefs.getString('userPhoto');

              // Cập nhật state ngay lập tức
              if (mounted &&
                  (storedName != null ||
                      storedEmail != null ||
                      storedPhoto != null)) {
                setState(() {
                  if (storedName != null && storedName.isNotEmpty) {
                    userName = storedName;
                  }
                  if (storedEmail != null && storedEmail.isNotEmpty) {
                    userEmail = storedEmail;
                  }
                  if (storedPhoto != null) {
                    userPhoto = storedPhoto;
                  }
                  print(
                      "TabProfile: Cập nhật thông tin tức thì sau khi quay về từ ProfileScreen");
                  print("- userName: $userName");
                  print("- userPhoto: $userPhoto");
                });
              }
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => setting["screen"]),
            );
          }
        }
      }));
      items.add(getSeparatorWidget());
    }
    items.add(getSpace(appBarPadding));
    return items;
  }

  Widget buildSettingRow(String icon, String title, Function() onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      splashColor: primaryColor.withOpacity(0.1),
      highlightColor: primaryColor.withOpacity(0.05),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            getSvgImage(icon, 24.0, color: AppColors.primaryColor),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: fontBlack,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget getLoginButton() {
    // Define the missing variables here
    SizeConfig().init(context);
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double screenWidth = SizeConfig.safeBlockHorizontal! * 100;

    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: Constant.getPercentSize(screenWidth, 4),
          vertical: Constant.getPercentSize(screenHeight, 2.5)),
      height: Constant.getPercentSize(screenHeight, 6.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(Constant.getPercentSize(screenHeight, 1.5)),
        ),
      ),
      child: ElevatedButton(
        onPressed: () async {
          // Show confirmation dialog before logout only if user is logged in
          if (widget.isLoggedIn) {
            _showLogoutConfirmationDialog();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(Constant.getPercentSize(screenHeight, 1.5)),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout,
              color: Colors.white,
              size: Constant.getPercentSize(screenHeight, 3),
            ),
            SizedBox(
              width: Constant.getPercentSize(screenWidth, 4),
            ),
            getCustomText('Đăng Xuất', Colors.white, 1, TextAlign.center,
                FontWeight.w500, Constant.getPercentSize(screenHeight, 2.3)),
          ],
        ),
      ),
    );
  }

  Widget getSeparatorWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Divider(height: 1, color: AppColors.dividerColor),
    );
  }

  // Thêm phương thức hiển thị hộp thoại xác nhận đăng xuất
  void _showLogoutConfirmationDialog() {
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
          padding: EdgeInsets.all(24),
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
              // Icon animation
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
                        Icons.logout_rounded,
                        color: AppColors.primaryColor,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),

              // Title animation
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
                  'Xác nhận đăng xuất',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.fontBlack,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Description animation
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
                  'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?',
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
                        'Hủy',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop(); // Đóng dialog

                        // Xử lý đăng xuất
                        await _performLogout();
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
                          Icon(Icons.logout_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Đăng xuất',
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

  // Phương thức thực hiện đăng xuất
  Future<void> _performLogout() async {
    try {
      // Use comprehensive logout through authStateProvider
      if (ref.exists(authStateProvider)) {
        // This will handle both logout and navigation
        await ref.read(authStateProvider.notifier).logoutAndNavigate(context);

        // Success notification is shown in LoginScreen, don't show it here
      } else {
        // Fallback if provider doesn't exist
        await PrefData.logout();
        g_token = "";

        // Navigate to LoginScreen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => LoginScreen(fromLogout: true)),
          );
        }
      }
    } catch (e) {
      print("Lỗi khi đăng xuất: $e");

      // Still try to navigate to LoginScreen on error
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => LoginScreen(fromLogout: true)),
        );
      }
    }
  }
}
