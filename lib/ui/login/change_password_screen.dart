// ignore: file_names
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/ui/intro/splash_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/constants/enum.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:shoplite/constants/widget_utils.dart';
import 'package:shoplite/providers/auth_provider.dart';
import 'package:shoplite/ui/login/reset_password_dialog_box.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoplite/constants/pref_data.dart';
import 'package:shoplite/providers/auth_service_provider.dart';
import 'package:shoplite/ui/login/login_screen.dart';
import 'package:shoplite/ui/home/home_screen.dart';
import 'package:shoplite/ui/widgets/notification_dialog.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isGoogleAccount = false;
  bool isDarkMode = ThemeController.isDarkMode;

  @override
  void initState() {
    super.initState();
    _checkIfGoogleAccount();
    ThemeController.addListener(_handleThemeChanged);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    ThemeController.removeListener(_handleThemeChanged);
    super.dispose();
  }

  void _handleThemeChanged() {
    setState(() {
      isDarkMode = ThemeController.isDarkMode;
    });
  }

  // Kiểm tra nếu tài khoản đăng nhập từ Google
  Future<void> _checkIfGoogleAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final isGoogle = prefs.getBool('isGoogleAccount') ?? false;

    if (isGoogle) {
      setState(() {
        _isGoogleAccount = true;
      });

      // Hiển thị thông báo nếu tài khoản Google
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ModernNotification.showWarning(
            context, 'Tài khoản Google không thể thay đổi mật khẩu');
        Navigator.pop(context);
      });
    }
  }

  void _toggleCurrentPasswordVisibility() {
    setState(() {
      _showCurrentPassword = !_showCurrentPassword;
    });
  }

  void _toggleNewPasswordVisibility() {
    setState(() {
      _showNewPassword = !_showNewPassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _showConfirmPassword = !_showConfirmPassword;
    });
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(changePasswordProvider.notifier);

      bool result = await notifier.changePassword(
          _currentPasswordController.text,
          _newPasswordController.text,
          _confirmPasswordController.text);

      if (result) {
        // Hiển thị dialog báo thành công
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return ResetPasswordDialogBox(
              func: () async {
                // Đóng dialog
                Navigator.pop(context);

                // Đăng xuất sau khi thay đổi mật khẩu thành công
                await _performLogout();
              },
            );
          },
        );
      } else {
        // Hiển thị thông báo lỗi
        ModernNotification.showError(
            context, notifier.message ?? 'Có lỗi xảy ra khi thay đổi mật khẩu');
      }
    }
  }

  // Phương thức thực hiện đăng xuất
  Future<void> _performLogout() async {
    try {
      // Use comprehensive logout through authStateProvider
      if (ref.exists(authStateProvider)) {
        // This will handle both logout and navigation
        await ref.read(authStateProvider.notifier).logoutAndNavigate(context);
      } else {
        // Fallback if provider doesn't exist
        await PrefData.logout();
        g_token = '';

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

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double appBarPadding = getAppBarPadding();
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double screenWidth = SizeConfig.safeBlockHorizontal! * 100;

    final changePasswordState = ref.watch(changePasswordProvider);
    bool isLoading = changePasswordState == ChangePasswordStatus.loading;

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
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Thay đổi mật khẩu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
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
          // Original content
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                top: 65 +
                    MediaQuery.of(context).padding.top +
                    16, // Account for AppBar + status bar + extra padding
                left: appBarPadding,
                right: appBarPadding,
                bottom: appBarPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon và thông tin
                  Container(
                    width: screenWidth * 0.22,
                    height: screenWidth * 0.22,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.lock_rounded,
                        size: screenWidth * 0.11,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'Đổi mật khẩu',
                    style: TextStyle(
                      fontSize: screenHeight * 0.028,
                      fontWeight: FontWeight.bold,
                      color: AppColors.fontBlack,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: appBarPadding),
                    child: Text(
                      'Để bảo mật tài khoản, vui lòng không chia sẻ mật khẩu cho người khác',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenHeight * 0.02,
                        color: AppColors.greyFont,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),

                  // Form đổi mật khẩu
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: ShapeDecoration(
                      color: AppColors.cardColor,
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(
                          cornerRadius: 20,
                          cornerSmoothing: 0.6,
                        ),
                      ),
                      shadows: [
                        BoxShadow(
                          color: AppColors.shadowColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Mật khẩu hiện tại
                          _buildPasswordField(
                            controller: _currentPasswordController,
                            label: "Mật khẩu hiện tại",
                            isVisible: _showCurrentPassword,
                            toggleVisibility: _toggleCurrentPasswordVisibility,
                          ),
                          SizedBox(height: 16),

                          // Mật khẩu mới
                          _buildPasswordField(
                            controller: _newPasswordController,
                            label: "Mật khẩu mới",
                            isVisible: _showNewPassword,
                            toggleVisibility: _toggleNewPasswordVisibility,
                          ),
                          SizedBox(height: 16),

                          // Xác nhận mật khẩu mới
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: "Xác nhận mật khẩu mới",
                            isVisible: _showConfirmPassword,
                            toggleVisibility: _toggleConfirmPasswordVisibility,
                          ),

                          SizedBox(height: 25),

                          // Nút xác nhận
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      "Xác nhận thay đổi",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback toggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withOpacity(0.4)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dividerColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Vui lòng nhập $label';
          }
          if (controller == _confirmPasswordController &&
              value != _newPasswordController.text) {
            return 'Mật khẩu xác nhận không khớp';
          }
          return null;
        },
        style: TextStyle(
          fontSize: 16,
          color: AppColors.fontBlack,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          hintText: label,
          hintStyle: TextStyle(
            color: AppColors.greyFont.withOpacity(0.7),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: AppColors.iconColor,
            size: 22,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.iconColor,
              size: 22,
            ),
            onPressed: toggleVisibility,
          ),
        ),
      ),
    );
  }
}
