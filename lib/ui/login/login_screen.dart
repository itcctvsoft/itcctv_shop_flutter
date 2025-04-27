import 'dart:convert';
import 'dart:ui'; // Import for ImageFilter
import 'dart:math' as math;
import 'package:country_state_city_picker/model/select_status_model.dart'
    as status;
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/constants/enum.dart';
import 'package:shoplite/constants/pref_data.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/ui/login/verify_screen.dart';
import 'package:shoplite/ui/auth/login_screen.dart';
import 'package:shoplite/ui/home/home_screen.dart';
import 'package:shoplite/providers/auth_service_provider.dart';
import 'package:shoplite/ui/widgets/notification_dialog.dart'; // Import ModernNotification
import '../../constants/constant.dart';
import '../../constants/widget_utils.dart';
import '../../providers/auth_provider.dart';
import 'forgot_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../repositories/google_auth_repository.dart';
import '../../utils/auth_helpers.dart';
import 'package:flutter/services.dart'; // Đã có import cho SystemChrome, cũng sử dụng cho HapticFeedback
import 'package:shoplite/providers/order_provider.dart';
import 'package:shoplite/utils/refresh_utils.dart';

// Animated Glow Particle
class AnimatedGlowParticle extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;
  final Offset position;
  final bool randomStart;

  const AnimatedGlowParticle({
    Key? key,
    required this.color,
    required this.size,
    required this.duration,
    required this.position,
    this.randomStart = true,
  }) : super(key: key);

  @override
  State<AnimatedGlowParticle> createState() => _AnimatedGlowParticleState();
}

class _AnimatedGlowParticleState extends State<AnimatedGlowParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late double initialScale;
  late double randomDelay;

  @override
  void initState() {
    super.initState();

    randomDelay = widget.randomStart ? math.Random().nextDouble() * 0.8 : 0.0;
    initialScale = 0.6 + math.Random().nextDouble() * 0.4;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = Tween<double>(begin: 0.1, end: 0.7)
        .chain(CurveTween(
            curve: Interval(randomDelay, 1.0, curve: Curves.easeInOut)))
        .animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: initialScale, end: initialScale * 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: initialScale * 1.2, end: initialScale * 0.8)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: initialScale * 0.8, end: initialScale)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ])
        .chain(
            CurveTween(curve: Interval(randomDelay, 1.0, curve: Curves.linear)))
        .animate(_controller);

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.5),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: widget.size * 1.5,
                      spreadRadius: widget.size * 0.2,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Animated Gradient Background
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;

  const AnimatedGradientBackground({
    Key? key,
    required this.child,
    required this.colors,
    this.duration = const Duration(seconds: 8),
  }) : super(key: key);

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.colors,
              stops: [
                0.0,
                _controller.value * 0.3 + 0.3,
                _controller.value * 0.2 + 0.6,
                1.0,
              ],
              transform: GradientRotation(_controller.value * 2 * math.pi),
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// Animated Border Container with Glowing Effect
class AnimatedBorderContainer extends StatefulWidget {
  final Widget child;
  final Color
      borderColor; // We'll keep this for compatibility but use rainbow colors instead
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry margin;
  final bool blurBackground;
  final bool useRainbowColors; // New property to enable rainbow mode

  const AnimatedBorderContainer({
    Key? key,
    required this.child,
    this.borderColor = Colors.green,
    this.borderRadius = 30.0,
    this.borderWidth = 1.5,
    this.margin = EdgeInsets.zero,
    this.blurBackground = true,
    this.useRainbowColors = true, // Default to rainbow colors
  }) : super(key: key);

  @override
  State<AnimatedBorderContainer> createState() =>
      _AnimatedBorderContainerState();
}

class _AnimatedBorderContainerState extends State<AnimatedBorderContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // List of colors for rainbow effect - same as text animation
  final List<Color> rainbowColors = [
    Colors.red,
    Colors.deepOrange,
    Colors.amber,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000), // Match text animation speed
    );
    _controller.repeat(); // Chạy liên tục vô hạn
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Tính toán cường độ phát sáng, đảm bảo không vượt quá 1.0
        final glowValue = 0.6 * math.sin(_controller.value * math.pi * 2) +
            0.7; // More intense glow value

        return Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: Colors.transparent,
              width: widget.borderWidth,
            ),
          ),
          child: CustomPaint(
            painter: AnimatedBorderPainter(
              progress: _controller.value,
              color: widget.borderColor,
              colors: widget.useRainbowColors ? rainbowColors : null,
              borderRadius: widget.borderRadius,
              glowIntensity: glowValue,
            ),
            child: widget.blurBackground
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(
                        widget.borderRadius - widget.borderWidth / 2),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: child,
                    ),
                  )
                : child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// Custom painter để vẽ viền animation
class AnimatedBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final List<Color>? colors; // Optional list of colors for rainbow effect
  final double borderRadius;
  final double glowIntensity;

  AnimatedBorderPainter({
    required this.progress,
    required this.color,
    this.colors,
    required this.borderRadius,
    this.glowIntensity = 1.0,
  });

  // Get color based on position along the path
  Color getColorForPosition(double position) {
    if (colors == null || colors!.isEmpty) return color;

    // Shift colors based on progress and position
    final int colorIndex =
        (((progress * 5) + (position * 0.5)) % colors!.length).floor();
    final int nextColorIndex = (colorIndex + 1) % colors!.length;

    // Interpolate between colors for smoother transitions
    final double colorMix = ((progress * 5) + (position * 0.5)) % 1.0;

    return Color.lerp(colors![colorIndex], colors![nextColorIndex], colorMix) ??
        color;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Tạo PathMetric để lấy vị trí trên đường viền
    final path = Path()..addRRect(rrect);
    final PathMetrics pathMetrics = path.computeMetrics();
    final PathMetric pathMetric = pathMetrics.first;
    final double pathLength = pathMetric.length;

    // Vẽ đường viền tĩnh với màu nhạt
    final Paint borderPaint = Paint()
      ..color = colors != null
          ? getColorForPosition(0.0).withOpacity(0.35) // Use rainbow colors
          : color.withOpacity(0.3) // Use single color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // Increase border width for more visibility
    canvas.drawRRect(rrect, borderPaint);

    // Tính toán vị trí của tia sáng
    final double startPos = (progress % 1.0) * pathLength;

    // Độ dài của tia sáng (30% độ dài của viền) - tăng từ 25% lên 30%
    double beamLength = pathLength * 0.3;

    // Vẽ tia sáng chính
    final beamPath = pathMetric.extractPath(
        startPos, math.min(startPos + beamLength, pathLength));

    // Nếu tia sáng chạy qua điểm cuối của đường viền, cần vẽ phần còn lại từ đầu
    if (startPos + beamLength > pathLength) {
      final remainingLength = startPos + beamLength - pathLength;
      final remainingPath = pathMetric.extractPath(0, remainingLength);
      // Kết hợp hai đường path
      beamPath.addPath(remainingPath, Offset.zero);
    }

    // Đảm bảo giá trị opacity không vượt quá 1.0
    final double safeGlowIntensity = math.min(glowIntensity, 1.0);

    // Determine gradient colors for beam
    List<Color> gradientColors = [];
    List<double> stops = [];

    if (colors != null) {
      // Create gradient with multiple colors for rainbow effect
      final int numSegments = 5; // Number of color segments
      final int middleSegment = 2; // Middle segment (index 2 in 0-5 range)

      for (int i = 0; i <= numSegments; i++) {
        final double position = i / numSegments;
        // Use the center segment for highest opacity
        final double opacity = (i == middleSegment)
            ? math.min(safeGlowIntensity, 1.0)
            : math.min(safeGlowIntensity * 0.7, 1.0);

        gradientColors.add(
            getColorForPosition(position * beamLength / pathLength)
                .withOpacity(opacity));
        stops.add(position);
      }
    } else {
      // Create gradient with single color
      gradientColors = [
        color.withOpacity(0.1),
        color.withOpacity(math.min(0.7 * safeGlowIntensity, 1.0)),
        color.withOpacity(math.min(safeGlowIntensity, 1.0)),
        color.withOpacity(math.min(0.7 * safeGlowIntensity, 1.0)),
        color.withOpacity(0.1),
      ];
      stops = [0.0, 0.2, 0.5, 0.8, 1.0];
    }

    // Vẽ phần tia sáng chính với hiệu ứng gradient
    final Paint beamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0 // Increase the beam width
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: gradientColors,
        stops: stops,
      ).createShader(beamPath.getBounds());

    canvas.drawPath(beamPath, beamPaint);

    // Thêm hiệu ứng glow cho phần giữa của tia sáng - làm to hơn
    final middlePoint = (startPos + beamLength / 2) % pathLength;
    final glowPoint = pathMetric.extractPath(
        math.max(
            0, middlePoint - pathLength * 0.08), // Tăng phạm vi của điểm sáng
        math.min(pathLength,
            middlePoint + pathLength * 0.08)); // Tăng phạm vi của điểm sáng

    // Get color for glow point
    final glowColor =
        colors != null ? getColorForPosition(middlePoint / pathLength) : color;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0 // Tăng độ dày của hiệu ứng glow
      ..maskFilter =
          MaskFilter.blur(BlurStyle.normal, 15) // Tăng độ mờ của hiệu ứng glow
      ..color = glowColor
          .withOpacity(math.min(safeGlowIntensity * 1.0, 1.0)); // Tăng độ đậm

    canvas.drawPath(glowPoint, glowPaint);

    // Add extra dramatic glow points at intervals along the path
    if (colors != null) {
      for (int i = 1; i <= 3; i++) {
        final accentPoint = (startPos + (beamLength * i / 3)) % pathLength;
        final accentGlowPath = pathMetric.extractPath(
            math.max(0, accentPoint - pathLength * 0.03),
            math.min(pathLength, accentPoint + pathLength * 0.03));

        final accentColor = getColorForPosition(accentPoint / pathLength);

        final accentPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12)
          ..color =
              accentColor.withOpacity(math.min(safeGlowIntensity * 0.8, 1.0));

        canvas.drawPath(accentGlowPath, accentPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  final bool fromLogout;

  const LoginScreen({Key? key, this.fromLogout = false}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabbar = 0;
  bool _isLoading = false;

  // Controllers for both sign-in and sign-up forms
  TextEditingController emailSignInController = TextEditingController();
  TextEditingController passSignInController = TextEditingController();
  TextEditingController emailSignUpController = TextEditingController();
  TextEditingController fullNameSignUpController = TextEditingController();
  TextEditingController phoneSignUpController = TextEditingController();
  TextEditingController addressSignUpController = TextEditingController();
  TextEditingController passSignUpController = TextEditingController();

  ValueNotifier<bool> isShowPass = ValueNotifier(false);
  bool chkVal = false;
  bool _rememberMe = false; // Remember Me checkbox state

  // Particle positions for animation
  final List<Offset> _particlePositions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 2);

    // Force dark mode for this screen
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Initialize particle positions
    // Top area particles
    _particlePositions.add(Offset(50, 100));
    _particlePositions.add(Offset(150, 80));
    _particlePositions.add(Offset(250, 120));
    _particlePositions.add(Offset(300, 60));
    _particlePositions.add(Offset(350, 150));

    // Side particles
    _particlePositions.add(Offset(20, 300));
    _particlePositions.add(Offset(380, 250));
    _particlePositions.add(Offset(15, 450));
    _particlePositions.add(Offset(370, 400));

    // Lower area particles
    _particlePositions.add(Offset(100, 600));
    _particlePositions.add(Offset(200, 630));
    _particlePositions.add(Offset(300, 580));

    // Show message if coming from logout
    if (widget.fromLogout) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ModernNotification.showSuccess(context, "Đăng xuất thành công");
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    emailSignInController.dispose();
    passSignInController.dispose();
    emailSignUpController.dispose();
    fullNameSignUpController.dispose();
    phoneSignUpController.dispose();
    addressSignUpController.dispose();
    passSignUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var loginState = ref.watch(loginProvider);
    var registerState = ref.watch(registerProvider);

    // Listen for login state changes
    ref.listen<LoginStatus>(loginProvider, (previous, next) {
      if (next == LoginStatus.success) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            // DIRECT FIX: Manually fix SharedPreferences with the exact keys
            final prefs = await SharedPreferences.getInstance();

            // Get token and ensure it's set
            final token = await PrefData.getToken();
            g_token = token;
            print("Current token is: ${token.isEmpty ? 'EMPTY' : 'PRESENT'}");

            // IMPORTANT: Always set ALL login flags to ensure proper authentication
            await prefs.setBool('com.example.shoppingisLoggedIn', true);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setBool(PrefData.isLoggedIn, true);
            await prefs.setBool('currentSessionLoggedIn', true);

            // AGGRESSIVE FIX: Handle userId type inconsistency
            if (prefs.containsKey('userId')) {
              try {
                var userId = prefs.get('userId');
                print(
                    "Current userId type: ${userId.runtimeType}, value: $userId");
                await prefs.remove('userId');

                if (userId != null) {
                  int userIdInt;
                  if (userId is int) {
                    userIdInt = userId;
                  } else {
                    userIdInt = int.tryParse(userId.toString()) ?? 0;
                  }

                  if (userIdInt > 0) {
                    await prefs.setInt('userId', userIdInt);
                    print("Fixed userId stored as INT: $userIdInt");
                    ref.read(userChangedProvider.notifier).state =
                        userIdInt.toString();
                  }
                }
              } catch (e) {
                print("Error fixing userId: $e");
                await prefs.remove('userId');
              }
            } else {
              ref.read(userChangedProvider.notifier).state = '';
            }

            // Làm mới tất cả dữ liệu cần thiết
            RefreshUtils.refreshAllData(ref);

            // IMPORTANT: Refresh the auth state provider
            await ref.read(authStateProvider.notifier).refreshAuthState();

            // Hiển thị thông báo đăng nhập thành công
            ModernNotification.showSuccess(context, "Đăng nhập thành công!");

            // Navigate to HomeScreen after a delay to ensure changes are saved
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                  (route) => false,
                );
              }
            });
          } catch (e) {
            print("CRITICAL ERROR during login completion: $e");
            ModernNotification.showError(context, "Đã xảy ra lỗi: $e");
          }
        });
      } else if (next == LoginStatus.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ModernNotification.showError(
              context, "Đăng nhập thất bại. Vui lòng kiểm tra thông tin!");
        });
      }
    });

    // Listen for register state changes
    ref.listen<RegisterStatus>(registerProvider, (previous, next) {
      if (next == RegisterStatus.success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ModernNotification.showSuccess(context, "Đăng ký thành công!");
          // Tự động chuyển đến tab đăng nhập sau khi đăng ký thành công
          _tabController.animateTo(0);
          _selectedTabbar = 0;
          setState(() {});
        });
      } else if (next == RegisterStatus.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ModernNotification.showError(
              context, "Đăng ký thất bại. Vui lòng kiểm tra lại thông tin!");
        });
      }
    });

    SizeConfig().init(context);
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double screenWidth = SizeConfig.safeBlockHorizontal! * 100;
    double appbarPadding = getAppBarPadding();

    // Use theme colors
    Color primaryColor = AppColors.primaryColor;
    Color accentColor = AppColors.accentColor;
    Color backgroundColor = AppColors.backgroundColor;
    Color cardColor = AppColors.cardColor;

    return WillPopScope(
      onWillPop: () async {
        // Navigate to HomeScreen instead of using default back behavior
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
        );
        return false; // Prevents default back behavior
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // Use gradient based on theme colors
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    backgroundColor,
                    ThemeController.isDarkMode
                        ? Color(0xFF0D1F23) // Darker shade for dark mode
                        : primaryColor
                            .withOpacity(0.8), // Lighter shade for light mode
                  ],
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Logo and App Name
                  Container(
                    padding: EdgeInsets.only(
                        top: screenHeight * 0.05, bottom: screenHeight * 0.03),
                    child: Column(
                      children: [
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 1200),
                          curve: Curves.elasticOut,
                          builder: (context, double value, child) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: Container(
                            width: screenWidth * 0.25,
                            height: screenWidth * 0.25,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: getSvgImage(
                                  "logo_img.svg", screenWidth * 0.12),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        AnimatedShopliteText(
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: screenHeight * 0.04,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: primaryColor.withOpacity(0.7),
                                offset: Offset(0, 0),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Card containing login/register forms with animated border
                  Expanded(
                    child: AnimatedBorderContainer(
                      borderColor: accentColor,
                      borderRadius: 30,
                      margin: EdgeInsets.symmetric(horizontal: appbarPadding),
                      child: Container(
                        decoration: ShapeDecoration(
                          color: ThemeController.isDarkMode
                              ? DarkThemeColors.secondaryBackground
                              : LightThemeColors.cardColor,
                          shadows: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 15,
                              offset: Offset(0, -5),
                            ),
                          ],
                          shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius.only(
                              topLeft: SmoothRadius(
                                cornerRadius: 30,
                                cornerSmoothing: 0.6,
                              ),
                              topRight: SmoothRadius(
                                cornerRadius: 30,
                                cornerSmoothing: 0.6,
                              ),
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            // TabBar for switching between Sign In and Register
                            Container(
                              margin: EdgeInsets.only(top: 20),
                              child: TabBar(
                                controller: _tabController,
                                onTap: (value) {
                                  HapticFeedback.lightImpact();
                                  _selectedTabbar = value;
                                  setState(() {});
                                },
                                tabs: [
                                  Tab(
                                    child: Text(
                                      "Sign in",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedTabbar == 0
                                            ? accentColor
                                            : ThemeController.isDarkMode
                                                ? Colors.grey
                                                : AppColors.greyFont,
                                      ),
                                    ),
                                  ),
                                  Tab(
                                    child: Text(
                                      "Register",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedTabbar == 1
                                            ? accentColor
                                            : ThemeController.isDarkMode
                                                ? Colors.grey
                                                : AppColors.greyFont,
                                      ),
                                    ),
                                  ),
                                ],
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicatorWeight: 3,
                                indicatorColor: accentColor,
                                labelPadding: EdgeInsets.zero,
                                padding: EdgeInsets.symmetric(horizontal: 20),
                              ),
                            ),

                            // Form content
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // Login Tab
                                  SingleChildScrollView(
                                    child: createLoginWidget(screenWidth,
                                        screenHeight, context, appbarPadding),
                                  ),

                                  // Register Tab
                                  SingleChildScrollView(
                                    child: createRegisterWidget(screenWidth,
                                        screenHeight, appbarPadding, context),
                                  ),
                                ],
                              ),
                            ),

                            // Loading indicators
                            loginState == LoginStatus.loading ||
                                    registerState == RegisterStatus.loading
                                ? Container(
                                    margin: EdgeInsets.only(bottom: 15),
                                    child: CircularProgressIndicator(
                                      color: accentColor,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Back button with improved glassmorphic effect
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: TweenAnimationBuilder(
                duration: Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0, end: 1),
                curve: Curves.elasticOut,
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.8),
                    border: Border.all(
                        color: accentColor.withOpacity(0.8), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                          (route) => false,
                        );
                      },
                      child: Center(
                        child: Icon(Icons.arrow_back,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for the Sign In screen
  Widget createLoginWidget(double screenWidth, double screenHeight,
      BuildContext context, double appbarPadding) {
    // Use theme colors
    Color primaryColor = AppColors.primaryColor;
    Color textColor = AppColors.fontBlack;
    Color accentColor = AppColors.accentColor;
    Color fieldColor = ThemeController.isDarkMode
        ? DarkThemeColors.secondaryBackground.withOpacity(0.7)
        : Colors.grey.withOpacity(0.1);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: Constant.getPercentSize(screenWidth, 4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getSpace(Constant.getPercentSize(screenHeight, 3)),

          // Custom styled fields
          Container(
            margin: EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: fieldColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  getSvgImage("email.svg", 24, color: primaryColor),
                  SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: emailSignInController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Email",
                        hintStyle: TextStyle(color: AppColors.greyFont),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            margin: EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: fieldColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: ValueListenableBuilder(
                valueListenable: isShowPass,
                builder: (context, value, child) {
                  return Row(
                    children: [
                      getSvgImage("Lock.svg", 24, color: primaryColor),
                      SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: passSignInController,
                          obscureText: !isShowPass.value,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: "Password",
                            hintStyle: TextStyle(color: AppColors.greyFont),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isShowPass.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.greyFont,
                        ),
                        onPressed: () {
                          isShowPass.value = !isShowPass.value;
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Remember Me checkbox
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  activeColor: accentColor,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                    HapticFeedback.lightImpact();
                  },
                ),
                Text(
                  "Nhớ đăng nhập",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Constant.sendToScreen(
                        const ForgotPasswordScreen(), context);
                  },
                  child: Text(
                    "Quên mật khẩu?",
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 10),

          // Sign In Button
          Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, accentColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();

                final email = emailSignInController.text;
                final password = passSignInController.text;

                // Use GoogleAuthRepository to completely sign out of Google
                final googleAuthRepo = GoogleAuthRepository();
                await googleAuthRepo.forceSignOut();

                // Now proceed with regular login
                ref.read(loginProvider.notifier).login(email, password);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                "SIGN IN",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          SizedBox(height: 30),

          Row(
            children: [
              Expanded(
                child: Divider(
                  color: AppColors.dividerColor,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Hoặc đăng nhập với",
                  style: TextStyle(
                    color: AppColors.greyFont,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: AppColors.dividerColor,
                  height: 1,
                ),
              ),
            ],
          ),

          SizedBox(height: 25),
          const GoogleSignInButton(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // Widget for the Register screen
  Widget createRegisterWidget(double screenWidth, double screenHeight,
      double appbarPadding, BuildContext context) {
    // Use theme colors
    Color primaryColor = AppColors.primaryColor;
    Color textColor = AppColors.fontBlack;
    Color accentColor = AppColors.accentColor;
    Color fieldColor = ThemeController.isDarkMode
        ? DarkThemeColors.secondaryBackground.withOpacity(0.7)
        : Colors.grey.withOpacity(0.1);

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: Constant.getPercentSize(screenWidth, 4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getSpace(Constant.getPercentSize(screenHeight, 2)),

          // Custom styled fields
          Container(
            margin: EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: fieldColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  getSvgImage("email.svg", 24, color: primaryColor),
                  SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: emailSignUpController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Email",
                        hintStyle: TextStyle(color: AppColors.greyFont),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            margin: EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: fieldColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  getSvgImage("User.svg", 24, color: primaryColor),
                  SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: fullNameSignUpController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Full Name",
                        hintStyle: TextStyle(color: AppColors.greyFont),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            margin: EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: fieldColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  getSvgImage("Call_Calling.svg", 24, color: primaryColor),
                  SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: phoneSignUpController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Phone",
                        hintStyle: TextStyle(color: AppColors.greyFont),
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            margin: EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: fieldColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  getSvgImage("shipping_location.svg", 24, color: primaryColor),
                  SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: addressSignUpController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Address",
                        hintStyle: TextStyle(color: AppColors.greyFont),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            margin: EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: fieldColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: ValueListenableBuilder(
                valueListenable: isShowPass,
                builder: (context, value, child) {
                  return Row(
                    children: [
                      getSvgImage("Lock.svg", 24, color: primaryColor),
                      SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: passSignUpController,
                          obscureText: !isShowPass.value,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: "Password",
                            hintStyle: TextStyle(color: AppColors.greyFont),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isShowPass.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.greyFont,
                        ),
                        onPressed: () {
                          isShowPass.value = !isShowPass.value;
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          SizedBox(height: 10),

          // Register Button
          Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, accentColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();

                final email = emailSignUpController.text;
                final password = passSignUpController.text;
                final fullName = fullNameSignUpController.text;
                final phone = phoneSignUpController.text;
                final address = addressSignUpController.text;

                ref
                    .read(registerProvider.notifier)
                    .register(email, password, fullName, phone, address);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                "REGISTER",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          SizedBox(height: 15),

          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _tabController.animateTo(0);
              _selectedTabbar = 0;
              setState(() {});
            },
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(
                      color: AppColors.greyFont,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: "Sign in",
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  void _handleLoginSuccess(String token) async {
    print('Login successful with token: $token');

    try {
      // Get SharedPreferences instance
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Always set ALL login flags to ensure consistent authentication
      await prefs.setBool(PrefData.isLoggedIn, true);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('com.example.shoppingisLoggedIn', true);
      await prefs.setBool('currentSessionLoggedIn', true);

      // Set token in both places to ensure consistency
      await PrefData.setToken(token);
      await prefs.setString(PrefData.token, token);

      // Update global token
      g_token = token;

      print('Checking login state after login attempt');
      bool isLoggedIn = await AuthHelpers.isLoggedIn();
      print('Is user logged in? $isLoggedIn');

      if (!mounted) return;

      // Refresh the auth state in the provider
      await ref.read(authStateProvider.notifier).refreshAuthState();

      // Show success notification
      ModernNotification.showSuccess(context, "Đăng nhập thành công!");

      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      print("Error during login completion: $e");
      ModernNotification.showError(context, "Đã xảy ra lỗi khi đăng nhập: $e");
    }
  }
}

// Add this new class at the end of the file
class AnimatedShopliteText extends StatefulWidget {
  final TextStyle textStyle;

  const AnimatedShopliteText({
    Key? key,
    required this.textStyle,
  }) : super(key: key);

  @override
  _AnimatedShopliteTextState createState() => _AnimatedShopliteTextState();
}

class _AnimatedShopliteTextState extends State<AnimatedShopliteText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  final String text = "SHOPLITE";

  // List of colors for rainbow effect with more saturated colors
  final List<Color> rainbowColors = [
    Colors.red,
    Colors.deepOrange,
    Colors.amber,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Repeat the animation forever
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Get color based on time and character position
  Color getColorForIndex(int index, double animValue) {
    // Shift through colors based on time and character position
    final int colorIndex =
        ((animValue * 5) + (index / text.length) * rainbowColors.length)
                .floor() %
            rainbowColors.length;
    return rainbowColors[colorIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        text.length,
        (index) => AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // For infinite animation, we need to handle the reveal only at the start
            final bool isFirstCycle = _controller.value < 1.0;

            // Staggered reveal for each letter (only for first cycle)
            final double delay = index / text.length;
            final double startTime = delay * 0.5; // Slightly faster reveal
            final double endTime = startTime + 0.15;

            // Calculate the visibility progress for this letter
            double visibilityProgress =
                1.0; // Default fully visible after first cycle

            if (isFirstCycle) {
              if (_controller.value < startTime) {
                visibilityProgress = 0.0;
              } else if (_controller.value > endTime) {
                visibilityProgress = 1.0;
              } else {
                visibilityProgress =
                    (_controller.value - startTime) / (endTime - startTime);
              }
            }

            // Enhanced bounce effect - bigger amplitude
            double bounceValue = 0.0;
            final double cyclicValue =
                (_controller.value * 2 + index * 0.2) % 1.0;

            if (cyclicValue < 0.3) {
              // Create a bounce effect at different times for each letter
              bounceValue = math.sin(cyclicValue * math.pi / 0.3) *
                  0.25; // Increased amplitude
            }

            // Add a slight scale effect for additional emphasis
            double scaleEffect = 1.0 +
                math.sin(_controller.value * math.pi * 2 + index * 0.5) * 0.1;

            // Get color based on animation progress
            final Color letterColor =
                getColorForIndex(index, _controller.value);

            // Calculate enhanced glow effect (pulsating)
            final double pulseRate = 2.5; // Faster pulse
            final double baseTime = _controller.value * pulseRate * math.pi * 2;
            final double letterOffset = index * (math.pi / text.length);
            final double glowIntensity = 0.6 +
                0.4 *
                    math.sin(
                        baseTime + letterOffset); // More pronounced difference

            // Create a more dramatic 3D-like rotation effect
            final double rotateY =
                math.sin(_controller.value * math.pi * 2 + index * 0.4) * 0.1;

            return Opacity(
              opacity: visibilityProgress,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Add perspective
                  ..rotateY(rotateY) // Add slight 3D rotation
                  ..scale(scaleEffect) // Pulsating scale
                  ..translate(0.0, -bounceValue * 20), // Enhanced bounce height
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: letterColor.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [
                          letterColor,
                          Colors.white,
                          letterColor,
                        ],
                        stops: [0.0, 0.5, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: Text(
                      text[index],
                      style: widget.textStyle.copyWith(
                        shadows: [
                          Shadow(
                            color: letterColor,
                            offset: Offset(0, 0),
                            blurRadius: 12,
                          ),
                          Shadow(
                            color: letterColor.withOpacity(0.7),
                            offset: Offset(0, 0),
                            blurRadius: 20,
                          ),
                        ],
                        fontWeight: FontWeight.w900, // Ultra bold
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
