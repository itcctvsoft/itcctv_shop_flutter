import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/providers/cart_provider.dart';
import 'package:shoplite/ui/home/home_screen.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/utils/auth_helpers.dart';
import 'package:shoplite/ui/widgets/auth_action_view.dart';

class CartIconBadge extends ConsumerStatefulWidget {
  final double size;
  final Color? iconColor;
  final Color? badgeColor;
  final bool useGradient;

  const CartIconBadge({
    Key? key,
    this.size = 24.0,
    this.iconColor,
    this.badgeColor,
    this.useGradient = true,
  }) : super(key: key);

  @override
  ConsumerState<CartIconBadge> createState() => _CartIconBadgeState();
}

class _CartIconBadgeState extends ConsumerState<CartIconBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _vibrateAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Subtle vibration animation
    _vibrateAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
          tween: Tween(begin: Offset.zero, end: const Offset(0.02, 0)),
          weight: 1),
      TweenSequenceItem(
          tween:
              Tween(begin: const Offset(0.02, 0), end: const Offset(-0.02, 0)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(-0.02, 0), end: Offset.zero),
          weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Thiết lập hoạt ảnh nếu có sản phẩm trong giỏ hàng
    _setupVibrationAnimation();
  }

  void _setupVibrationAnimation() {
    // Kiểm tra nếu có sản phẩm trong giỏ hàng, thực hiện hiệu ứng nhắc nhở
    final cartItemCount = ref.read(cartItemCountProvider);
    if (cartItemCount > 0 && !_isAnimating) {
      _isAnimating = true;
      _animationController.repeat();
    } else if (cartItemCount == 0 && _isAnimating) {
      _isAnimating = false;
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void didUpdateWidget(CartIconBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setupVibrationAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupVibrationAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Đọc số sản phẩm trong giỏ hàng từ provider
    final cartItemCount = ref.watch(cartItemCountProvider);
    final isDarkMode = ThemeController.isDarkMode;

    // Cập nhật animation nếu cần
    if (cartItemCount > 0 && !_isAnimating) {
      _isAnimating = true;
      _animationController.repeat();
    } else if (cartItemCount == 0 && _isAnimating) {
      _isAnimating = false;
      _animationController.stop();
      _animationController.reset();
    }

    // Màu mặc định của icon và badge dựa trên dark mode
    final Color defaultIconColor = widget.iconColor ?? AppColors.fontLight;
    final Color effectiveBadgeColor = widget.badgeColor ??
        (isDarkMode ? DarkThemeColors.accentColor : AppColors.buttonColor);

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () async {
          // Vibración para mejor experiencia
          HapticFeedback.lightImpact();

          // Dừng animation khi nút được nhấn
          if (_isAnimating) {
            _isAnimating = false;
            _animationController.stop();
            _animationController.reset();
          }

          // Kiểm tra đăng nhập trước khi mở màn hình giỏ hàng
          bool isLoggedIn = await AuthHelpers.isLoggedIn();
          if (!isLoggedIn) {
            // Chuyển đến AuthActionView nếu chưa đăng nhập
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AuthActionView(
                  featureDescription: "sử dụng giỏ hàng",
                  featureIcon: Icons.shopping_bag_outlined,
                ),
              ),
            );
            return;
          }

          // Nếu đã đăng nhập, mở màn hình giỏ hàng
          Constant.sendToScreen(HomeScreen(selectedTab: 2), context);
        },
        splashColor: effectiveBadgeColor.withOpacity(0.3),
        highlightColor: effectiveBadgeColor.withOpacity(0.1),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: cartItemCount > 0
                        ? _vibrateAnimation.value
                        : Offset.zero,
                    child: child,
                  );
                },
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: defaultIconColor,
                  size: widget.size,
                ),
              ),
              if (cartItemCount > 0)
                Positioned(
                  top: -10,
                  right: -10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.useGradient
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                effectiveBadgeColor,
                                effectiveBadgeColor.withRed(
                                    (effectiveBadgeColor.red - 40)
                                        .clamp(0, 255)),
                              ],
                            )
                          : null,
                      color: widget.useGradient ? null : effectiveBadgeColor,
                      boxShadow: [
                        BoxShadow(
                          color: effectiveBadgeColor.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                      border: Border.all(
                        color: isDarkMode
                            ? DarkThemeColors.appBarColor
                            : Colors.white,
                        width: 2,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      cartItemCount > 99 ? '99+' : cartItemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Provider para la cantidad de elementos en el carrito
final cartItemCountProvider = StateProvider<int>((ref) {
  // Obtener la lista de elementos del provider del carrito
  try {
    final cart = ref.watch(cartProvider);
    // Tính tổng số lượng sản phẩm trong giỏ hàng (không phải số loại sản phẩm)
    return cart.cartItems.fold(0, (total, item) => total + item.quantity);
  } catch (e) {
    // En caso de error, devolver 0
    return 0;
  }
});
