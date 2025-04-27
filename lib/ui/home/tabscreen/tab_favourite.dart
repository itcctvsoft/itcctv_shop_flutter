import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shoplite/models/product.dart';
import 'package:shoplite/providers/product_provider.dart';
import 'package:shoplite/providers/wishlist_provider.dart';
import 'package:shoplite/ui/product/product_detail.dart';
import 'package:shoplite/ui/product/all_product_list.dart';
import 'package:shoplite/ui/widgets/notification_dialog.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';
import 'package:shoplite/widgets/optimized_image.dart';
import '../../../constants/apilist.dart';
import '../../../constants/constant.dart';
import '../../../constants/size_config.dart';
import '../../../constants/widget_utils.dart';
import '../../../constants/color_data.dart';

class TabFavourite extends ConsumerStatefulWidget {
  const TabFavourite({Key? key}) : super(key: key);

  @override
  ConsumerState<TabFavourite> createState() => _TabFavouriteState();
}

class _TabFavouriteState extends ConsumerState<TabFavourite>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = false;
  List<Product> _favouriteProducts = [];
  bool isDarkMode = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Đảm bảo danh sách yêu thích được tải khi mở tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWishlistProducts();
    });

    // Đồng bộ trạng thái dark mode
    isDarkMode = ThemeController.isDarkMode;
    ThemeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {
      isDarkMode = ThemeController.isDarkMode;
    });
  }

  // Tải danh sách sản phẩm yêu thích
  Future<void> _loadWishlistProducts() async {
    if (g_token.isEmpty) {
      print('TabFavourite: Token trống, không thể tải danh sách yêu thích');
      setState(() {
        _favouriteProducts = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('TabFavourite: Bắt đầu tải sản phẩm yêu thích');
      // Lấy repository
      final productRepository = ref.read(productRepositoryProvider);

      // Tải danh sách sản phẩm yêu thích trực tiếp từ API
      final products = await productRepository.getWishlistProducts();

      print('TabFavourite: Đã tải ${products.length} sản phẩm yêu thích');

      // Lọc bỏ sản phẩm có stock = 0
      final filteredProducts =
          products.where((product) => product.stock > 0).toList();
      print(
          'TabFavourite: Sau khi lọc bỏ sản phẩm hết hàng, còn ${filteredProducts.length} sản phẩm');

      // Kiểm tra dữ liệu ảnh
      for (var product in filteredProducts) {
        if (product.photos.isNotEmpty) {
          print(
              'TabFavourite: Ảnh sản phẩm ${product.id}: ${product.photos.first}');
        } else {
          print('TabFavourite: Sản phẩm ${product.id} không có ảnh');
        }
      }

      if (mounted) {
        setState(() {
          _favouriteProducts = filteredProducts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('TabFavourite: Lỗi khi tải danh sách yêu thích: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Hiển thị thông báo với NotificationDialog thay vì Snackbar
  void _showNotification(String message, bool isSuccess) {
    if (isSuccess) {
      NotificationDialog.showSuccess(
        context: context,
        title: 'Thành công',
        message: message,
        autoDismiss: true,
        autoDismissDuration: const Duration(seconds: 1),
      );
    } else {
      NotificationDialog.showError(
        context: context,
        title: 'Lỗi',
        message: message,
        autoDismiss: true,
        autoDismissDuration: const Duration(seconds: 1),
      );
    }
  }

  /// Hiển thị thông báo xóa khỏi danh sách yêu thích
  void _showRemoveFromWishlistNotification() {
    NotificationDialog.showSuccess(
      context: context,
      title: 'Đã xóa khỏi yêu thích',
      message: 'Đã xóa sản phẩm khỏi danh sách yêu thích',
      autoDismiss: true,
      autoDismissDuration: const Duration(seconds: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    SizeConfig().init(context);

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.favorite,
                            color: AppColors.fontLight,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "Danh Sách Yêu Thích",
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 360
                                  ? 16
                                  : 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.fontLight,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _loadWishlistProducts,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.refresh,
                            color: AppColors.fontLight,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const ChatIconBadge(size: 22),
                      ),
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
            child: CustomScrollView(
              slivers: [
                // Cung cấp không gian cho nội dung bắt đầu dưới app bar
                SliverPadding(
                  padding: EdgeInsets.only(
                    top: 65 + MediaQuery.of(context).padding.top + 5,
                  ),
                  sliver: SliverToBoxAdapter(child: SizedBox()),
                ),

                // Nội dung - danh sách yêu thích
                _isLoading
                    ? _buildLoadingShimmerSliver()
                    : _favouriteProducts.isEmpty
                        ? SliverToBoxAdapter(child: _buildEmptyWishlist())
                        : _buildWishlistSliver(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmerSliver() {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, __) => Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 10,
                          color: AppColors.cardColor,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 10,
                          color: AppColors.cardColor,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 15,
                              color: AppColors.cardColor,
                            ),
                            const Spacer(),
                            Container(
                              width: 40,
                              height: 15,
                              color: AppColors.cardColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          childCount: 4,
        ),
      ),
    );
  }

  Widget _buildEmptyWishlist() {
    // Calculate appropriate text sizes based on device width
    final deviceWidth = MediaQuery.of(context).size.width;
    final titleSize = deviceWidth < 360 ? 18.0 : 20.0;
    final descSize = deviceWidth < 360 ? 14.0 : 16.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                Icons.favorite_border,
                size: 60,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Danh sách yêu thích trống",
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: AppColors.fontBlack,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "Hãy thêm sản phẩm yêu thích để xem và mua sau",
                style: TextStyle(
                  fontSize: descSize,
                  color: AppColors.greyFont,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 25),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
              ),
              child: Text(
                "Khám phá sản phẩm",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistSliver() {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 10),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio:
              MediaQuery.of(context).textScaleFactor > 1.2 ? 0.65 : 0.75,
          crossAxisSpacing: 15,
          mainAxisSpacing: 18,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = _favouriteProducts[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetail(product: product),
                  ),
                ).then((_) {
                  _loadWishlistProducts();
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor.withOpacity(0.1),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ảnh sản phẩm với nút yêu thích
                    Stack(
                      children: [
                        Hero(
                          tag: 'product_image_${product.id}',
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: product.photos.isNotEmpty
                                ? OptimizedImage(
                                    imageUrl: _processImageUrl(
                                        product.photos.first.trim()),
                                    width: double.infinity,
                                    height: 140,
                                    fit: BoxFit.cover,
                                    isDarkMode: isDarkMode,
                                    borderRadius: 0,
                                  )
                                : Container(
                                    height: 140,
                                    width: double.infinity,
                                    color: AppColors.primaryColor
                                        .withOpacity(0.05),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image,
                                          color: AppColors.primaryColor,
                                          size: 36,
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Text(
                                            product.title,
                                            style: TextStyle(
                                              color: AppColors.primaryColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        // Badge giảm giá nếu có
                        if (product.price < 3000000)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red.shade700, Colors.red],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                "SALE",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        // Nút xóa khỏi yêu thích
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              ref
                                  .read(wishlistProductIdsProvider.notifier)
                                  .toggleWishlist(product.id)
                                  .then((success) {
                                if (success) {
                                  _showRemoveFromWishlistNotification();
                                  setState(() {
                                    _favouriteProducts
                                        .removeWhere((p) => p.id == product.id);
                                  });
                                } else {
                                  _loadWishlistProducts();
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Chi tiết sản phẩm
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tên sản phẩm
                            Text(
                              product.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.fontBlack,
                                height: 1.2,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Tồn kho
                            Container(
                              constraints: BoxConstraints(maxWidth: 80),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? AppColors.primaryColor.withOpacity(0.15)
                                    : AppColors.primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 10,
                                    color: product.stock > 5
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Còn ${product.stock}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: product.stock > 5
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Giá
                            Text(
                              '${_formatNumber(product.price)} đ',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),

                            // Nút Xem chi tiết
                            SizedBox(
                              width: double.infinity,
                              height: 28,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProductDetail(product: product),
                                    ),
                                  ).then((_) {
                                    _loadWishlistProducts();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.buttonColor,
                                  foregroundColor: AppColors.fontLight,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 2,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Xem chi tiết',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 10,
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
              ),
            );
          },
          childCount: _favouriteProducts.length,
        ),
      ),
    );
  }

  // Format số với dấu phân cách hàng nghìn
  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  // Helper method to build consistent error display for images
  Widget _buildImageErrorWidget(String title) {
    return Container(
      height: 160,
      color: AppColors.primaryColor.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: AppColors.primaryColor,
            size: 36,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Xử lý URL ảnh trước khi sử dụng
  String _processImageUrl(String url) {
    if (url.isEmpty) return '';

    // Cắt bỏ khoảng trắng
    url = url.trim();

    // Kiểm tra URL có hợp lệ không
    try {
      final uri = Uri.parse(url);
      if (!uri.isAbsolute) return '';

      // Xử lý URL cho giả lập Android
      if (url.contains('127.0.0.1') || url.contains('localhost')) {
        url = url
            .replaceAll('127.0.0.1', '10.0.2.2')
            .replaceAll('localhost', '10.0.2.2');
      }

      return url;
    } catch (e) {
      print('URL không hợp lệ trong tab_favourite: $url - Lỗi: $e');
      return '';
    }
  }
}
