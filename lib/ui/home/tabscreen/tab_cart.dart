import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/constants/pref_data.dart';
import 'package:shoplite/models/Cart.dart';
import 'package:shoplite/repositories/cart_repository.dart';
import 'package:shoplite/ui/checkout/checkout_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../constants/utils.dart';
import 'package:shoplite/ui/product/all_product_list.dart';
import 'package:shoplite/utils/auth_helpers.dart';
import 'package:shoplite/ui/widgets/auth_action_view.dart';
import 'package:shoplite/ui/widgets/notification_dialog.dart';

import '../../../constants/constant.dart';

class TabCart extends ConsumerStatefulWidget {
  const TabCart({Key? key}) : super(key: key);

  @override
  ConsumerState<TabCart> createState() => _TabCartState();
}

class _TabCartState extends ConsumerState<TabCart> {
  Future<List<CartItem>>? _cartItems;
  double cartTotal = 0;
  bool isDarkMode = false;

  final NumberFormat currencyFormatter =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _loadCartData();

    // Đồng bộ trạng thái dark mode
    isDarkMode = ThemeController.isDarkMode;
    ThemeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  // Handle theme changes
  void _onThemeChanged() {
    setState(() {
      isDarkMode = ThemeController.isDarkMode;
    });
  }

  void _loadCartData() {
    setState(() {
      _cartItems = _loadCartItems();
    });
  }

  Future<List<CartItem>> _loadCartItems() async {
    final token = await _getValidToken();
    if (token != null) {
      try {
        final items = await CartRepository().getCartItems(token);
        _calculateCartTotal(items);
        return items;
      } catch (error) {
        debugPrint('Error fetching cart items: $error');
        return [];
      }
    }
    return [];
  }

  void _calculateCartTotal(List<CartItem> items) {
    setState(() {
      cartTotal = items.fold(
        0,
        (total, item) => total + (item.price * item.quantity),
      );
    });
  }

  Future<String?> _getValidToken() async {
    final token = await PrefData.getToken();
    if (token == null || token.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuthActionView(
            featureDescription: "truy cập giỏ hàng",
            featureIcon: Icons.shopping_cart_outlined,
          ),
        ),
      );
      return null;
    }
    return token;
  }

  Future<void> _updateCartItemQuantity(int productId, int quantity) async {
    final token = await _getValidToken();
    if (token != null) {
      try {
        await CartRepository().updateCartItem(token, productId, quantity);
        _loadCartData();
        NotificationDialog.showSuccess(
          context: context,
          title: 'Thành công',
          message: 'Số lượng sản phẩm đã được cập nhật',
          autoDismiss: true,
          autoDismissDuration: const Duration(seconds: 1),
        );
      } catch (e) {
        NotificationDialog.showError(
          context: context,
          title: 'Lỗi',
          message: 'Lỗi khi cập nhật số lượng: ${e.toString()}',
          autoDismiss: true,
          autoDismissDuration: const Duration(seconds: 1),
        );
      }
    }
  }

  Future<void> _removeCartItem(int productId) async {
    final token = await _getValidToken();
    if (token != null) {
      try {
        await CartRepository().removeFromCart(token, productId);
        _loadCartData();
        NotificationDialog.showSuccess(
          context: context,
          title: 'Thành công',
          message: 'Sản phẩm đã được xóa khỏi giỏ hàng',
          autoDismiss: true,
          autoDismissDuration: const Duration(seconds: 1),
        );
      } catch (e) {
        NotificationDialog.showError(
          context: context,
          title: 'Lỗi',
          message: 'Lỗi khi xóa sản phẩm: ${e.toString()}',
          autoDismiss: true,
          autoDismissDuration: const Duration(seconds: 1),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          Icons.shopping_bag_outlined,
                          color: AppColors.fontLight,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Giỏ Hàng",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.fontLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const ChatIconBadge(size: 26),
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
            child: CustomScrollView(
              slivers: [
                // Cung cấp không gian cho nội dung bắt đầu dưới app bar
                SliverPadding(
                  padding: EdgeInsets.only(
                    top: 65 + MediaQuery.of(context).padding.top + 5,
                  ),
                  sliver: SliverToBoxAdapter(child: SizedBox()),
                ),

                // Tổng giỏ hàng
                SliverToBoxAdapter(child: _buildCartTotal()),

                // Nội dung - danh sách giỏ hàng
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: FutureBuilder<List<CartItem>>(
                      future: _cartItems,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryColor),
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: TextStyle(color: AppColors.fontBlack),
                              ),
                            ),
                          );
                        } else if (snapshot.hasData &&
                            snapshot.data!.isNotEmpty) {
                          return Column(
                            children: List.generate(
                              snapshot.data!.length,
                              (index) => _buildCartItem(snapshot.data![index]),
                            ),
                          );
                        } else {
                          return _buildEmptyCart();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Nút mua hàng ở dưới cùng
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: AppColors.backgroundColor,
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor,
                  foregroundColor: AppColors.fontLight,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  if (cartTotal == 0) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AllProductList(),
                      ),
                    );
                  } else {
                    Constant.sendToScreen(const CheckoutScreen(), context);
                  }
                },
                child: Text(
                  "Mua hàng",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.fontLight,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 25),
          Text(
            "Giỏ hàng trống",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.fontBlack,
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Hãy thêm sản phẩm vào giỏ hàng để tiến hành mua hàng",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.greyFont,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AllProductList(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonColor,
              foregroundColor: AppColors.fontLight,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 3,
            ),
            child: const Text(
              "Tiếp tục mua sắm",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Card(
      color: AppColors.cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: _getImageUrl(item.photo),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 200),
                maxHeightDiskCache: 300,
                maxWidthDiskCache: 300,
                memCacheWidth: 300,
                placeholderFadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 300),
                imageBuilder: (context, imageProvider) => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                placeholder: (context, url) => Container(
                  width: 80,
                  height: 80,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) {
                  debugPrint('Cart: Lỗi tải ảnh $url: $error');

                  // Try alternative URL: use HTTPS if using HTTP or vice versa
                  String alternativeUrl = url;
                  if (url.startsWith('http://')) {
                    alternativeUrl = url.replaceFirst('http://', 'https://');
                  } else if (url.startsWith('https://')) {
                    alternativeUrl = url.replaceFirst('https://', 'http://');
                  }

                  // Also try transforming localhost URL if needed
                  if (url.contains('127.0.0.1:8000')) {
                    alternativeUrl =
                        url.replaceFirst('127.0.0.1:8000', '10.0.2.2:8000');
                  } else if (url.contains('localhost:8000')) {
                    alternativeUrl =
                        url.replaceFirst('localhost:8000', '10.0.2.2:8000');
                  }

                  // If the URL was changed, try one more time with the alternative URL
                  if (alternativeUrl != url) {
                    return CachedNetworkImage(
                      imageUrl: alternativeUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryColor),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        // Final fallback: show error UI
                        return _buildImageErrorWidget(item.title);
                      },
                    );
                  }

                  // Fallback to error display
                  return _buildImageErrorWidget(item.title);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.fontBlack,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormatter.format(item.price),
                    style: TextStyle(
                      color: AppColors.appBarColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, color: AppColors.appBarColor),
                        onPressed: () {
                          if (item.quantity > 1) {
                            _updateCartItemQuantity(item.id, item.quantity - 1);
                          }
                        },
                      ),
                      Text(
                        item.quantity.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.fontBlack,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: AppColors.appBarColor),
                        onPressed: () {
                          _updateCartItemQuantity(item.id, item.quantity + 1);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                await _removeCartItem(item.id);
              },
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartTotal() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Tổng cộng:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.fontBlack,
            ),
          ),
          Text(
            currencyFormatter.format(cartTotal),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.appBarColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getImageUrl(dynamic photo) {
    // Default placeholder image
    const String placeholderImage =
        'https://via.placeholder.com/150/cccccc/000000?text=No+Image';

    if (photo == null) {
      return placeholderImage;
    }

    // Nếu photo là String
    if (photo is String) {
      // Check if it's empty
      if (photo.isEmpty) {
        return placeholderImage;
      }

      // Kiểm tra nếu là chuỗi chứa nhiều URL phân cách bằng dấu phẩy
      if (photo.contains(',')) {
        // Lấy URL đầu tiên trong chuỗi phân cách bằng dấu phẩy
        String url = photo.split(',')[0];
        return getImageUrl(url);
      }

      // Nếu là chuỗi JSON chứa mảng
      if (photo.startsWith('[') && photo.endsWith(']')) {
        try {
          List<dynamic> photoList = jsonDecode(photo);
          if (photoList.isNotEmpty) {
            return getImageUrl(photoList[0].toString());
          }
          return placeholderImage;
        } catch (e) {
          // Nếu không parse được, trả về chuỗi ban đầu
          return getImageUrl(photo);
        }
      }

      // Chuỗi URL đơn giản
      return getImageUrl(photo);
    }

    // Nếu photo là List (từ API Laravel)
    if (photo is List) {
      if (photo.isNotEmpty) {
        return getImageUrl(photo[0].toString());
      }
      return placeholderImage;
    }

    // Trường hợp khác, trả về ảnh placeholder
    return placeholderImage;
  }

  // Helper method to build consistent error display for images
  Widget _buildImageErrorWidget(String title) {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.primaryColor.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: AppColors.primaryColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
