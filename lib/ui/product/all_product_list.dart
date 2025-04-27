import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/utils.dart';
import 'package:shoplite/constants/widget_utils.dart';
import 'package:shoplite/models/product.dart';
import 'package:shoplite/providers/product_provider.dart' as main_provider;
import 'package:shoplite/providers/wishlist_provider.dart';
import 'package:shoplite/ui/product/product_detail.dart';
import 'package:shoplite/ui/products/product_list_screen.dart';
import 'package:shoplite/ui/widgets/notification_dialog.dart';
import 'package:shoplite/ui/home/home_screen.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';
import 'package:shoplite/utils/auth_helpers.dart';
import 'package:shoplite/ui/login/login_screen.dart';
import 'package:shoplite/ui/widgets/auth_action_view.dart';
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/widgets/optimized_image.dart';
import 'package:intl/intl.dart';

class AllProductList extends ConsumerStatefulWidget {
  const AllProductList({Key? key}) : super(key: key);

  @override
  ConsumerState<AllProductList> createState() => _AllProductListState();
}

class _AllProductListState extends ConsumerState<AllProductList> {
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  List<int> favouriteIds = []; // Lưu danh sách ID sản phẩm yêu thích
  late SharedPreferences prefs;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false; // Biến theo dõi trạng thái tải thêm sản phẩm
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadFavourites(); // Load danh sách yêu thích từ SharedPreferences

    // Tải danh sách sản phẩm ban đầu, reset hoàn toàn provider và cache
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProviderState = ref.read(main_provider.productProvider);
      productProviderState
          .clearCache(); // Xóa bộ nhớ đệm trước để đảm bảo tải mới
      productProviderState.reset();
      productProviderState.fetchProducts(
          reset: true, perPage: 100); // Tải nhiều sản phẩm hơn
    });

    // Thêm lắng nghe sự kiện cuộn để tải thêm sản phẩm khi cuộn đến cuối
    _scrollController.addListener(_scrollListener);

    isDarkMode = ThemeController.isDarkMode;
    ThemeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    ThemeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  // Hàm lắng nghe sự kiện cuộn và tải thêm sản phẩm khi cần thiết
  void _scrollListener() {
    // Kiểm tra nếu đã cuộn đến gần cuối danh sách (còn khoảng 200 pixel)
    if (_scrollController.position.pixels > 0 &&
        _scrollController.position.extentAfter < 500) {
      _loadMoreProducts();
    }
  }

  // Hàm tải thêm sản phẩm
  void _loadMoreProducts() {
    final productProviderState = ref.read(main_provider.productProvider);

    // Kiểm tra xem có đang tải không và còn trang tiếp theo không
    if (!_isLoadingMore &&
        !productProviderState.isLoading &&
        productProviderState.currentPage < productProviderState.totalPages) {
      setState(() {
        _isLoadingMore = true;
      });

      // Tải thêm sản phẩm
      if (_isSearching && _searchQuery.isNotEmpty) {
        // Tăng trang và tìm kiếm tiếp
        productProviderState.loadMore(perPage: 20).then((_) {
          if (mounted) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        });
      } else {
        // Tải thêm sản phẩm thông thường
        productProviderState.loadMore(perPage: 20).then((_) {
          if (mounted) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }

  void _onThemeChanged() {
    setState(() {
      isDarkMode = ThemeController.isDarkMode;
    });
  }

  /// Hàm load danh sách ID sản phẩm yêu thích theo token
  Future<void> _loadFavourites() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      favouriteIds =
          prefs.getStringList('favourites')?.map(int.parse).toList() ?? [];
    });
  }

  // Chuyển đổi URL ảnh sản phẩm
  String _getImageUrl(String url) {
    return getImageUrl(url);
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
    // Refresh danh sách sản phẩm khi hủy tìm kiếm
    ref.read(main_provider.productProvider).reset();
    ref.read(main_provider.productProvider).fetchProducts(perPage: 10);
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _searchQuery = query;
      });
      // Khi tìm kiếm, đặt số lượng sản phẩm mỗi trang là 10
      ref
          .read(main_provider.productProvider)
          .searchProducts(_searchQuery, perPage: 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng ProductProvider trực tiếp để lấy thông tin phân trang
    final productProviderState = ref.watch(main_provider.productProvider);

    // Sử dụng products từ productProvider hoặc kết quả tìm kiếm từ searchProductsProvider
    final productsAsync = _isSearching && _searchQuery.isNotEmpty
        ? AsyncValue.data(productProviderState.products)
        : AsyncValue.data(productProviderState.products);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          height: 70 + MediaQuery.of(context).padding.top,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDarkColor,
                AppColors.primaryColor,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withOpacity(0.2),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _isSearching
                        ? _stopSearch
                        : () {
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
                        color: AppColors.fontLight,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _isSearching
                      ? Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm sản phẩm...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                            color: AppColors.fontLight.withOpacity(0.8)),
                      ),
                      style: TextStyle(color: AppColors.fontLight),
                      onSubmitted: (_) => _handleSearch(),
                    ),
                  )
                      : Expanded(
                    child: Text(
                      'Tất cả sản phẩm',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.fontLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSearching ? _handleSearch : _startSearch,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isSearching ? Icons.search : Icons.search,
                        color: AppColors.fontLight,
                        size: 22,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  const ChatIconBadge(size: 26),
                ],
              ),
            ),
          ),
        ),
      ),
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
          _buildProductList(productsAsync, productProviderState.isLoading),

          // Overlay loading khi đang tải trang đầu tiên
          if (productProviderState.isLoading &&
              productProviderState.products.isEmpty)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: AppColors.backgroundColor,
    );
  }

  Widget _buildProductList(
      AsyncValue<List<Product>> productsAsync, bool isInitialLoading) {
    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Text(
              'Không tìm thấy sản phẩm nào',
              style: TextStyle(color: AppColors.fontBlack),
            ),
          );
        }

        return Stack(
          children: [
            GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 15,
                mainAxisSpacing: 18,
              ),
              itemCount: products.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Hiển thị loading indicator ở cuối danh sách
                if (index == products.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryColor,
                        ),
                      ),
                    ),
                  );
                }

                final product = products[index];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ProductDetail(product: product)));
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
                        // Ảnh sản phẩm với nút yêu thích và badge sale
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: product.photos.isNotEmpty
                                  ? OptimizedImage(
                                imageUrl:
                                _getImageUrl(product.photos.first),
                                width: double.infinity,
                                height: 140,
                                fit: BoxFit.cover,
                                isDarkMode: isDarkMode,
                                borderRadius: 0,
                              )
                                  : Container(
                                height: 140,
                                width: double.infinity,
                                color: isDarkMode
                                    ? AppColors.cardColor
                                    : AppColors.primaryColor
                                    .withOpacity(0.05),
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported,
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

                            // Badge giảm giá nếu giá dưới 3 triệu
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

                            // Nút yêu thích
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Consumer(
                                builder: (context, ref, child) {
                                  final isInWishlistAsync = ref.watch(
                                      isProductInWishlistProvider(product.id));

                                  return isInWishlistAsync.when(
                                    data: (isInWishlist) => GestureDetector(
                                      onTap: () async {
                                        // Kiểm tra đăng nhập trước khi thao tác với yêu thích
                                        bool isLoggedIn =
                                        await AuthHelpers.isLoggedIn();
                                        if (!isLoggedIn) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AuthActionView(
                                                    featureDescription:
                                                    "yêu thích sản phẩm",
                                                    featureIcon:
                                                    Icons.favorite_border,
                                                    onBackPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                            ),
                                          );
                                          return;
                                        }

                                        try {
                                          bool success = await ref
                                              .read(wishlistProductIdsProvider
                                              .notifier)
                                              .toggleWishlist(product.id);

                                          if (success) {
                                            if (isInWishlist) {
                                              NotificationDialog.showSuccess(
                                                context: context,
                                                title: 'Đã xóa khỏi yêu thích',
                                                message:
                                                'Đã xóa sản phẩm khỏi danh sách yêu thích',
                                                autoDismiss: true,
                                                autoDismissDuration:
                                                const Duration(seconds: 1),
                                              );
                                            } else {
                                              NotificationDialog.showSuccess(
                                                context: context,
                                                title: 'Thành công',
                                                message:
                                                'Đã thêm sản phẩm vào danh sách yêu thích',
                                                autoDismiss: true,
                                                autoDismissDuration:
                                                const Duration(seconds: 1),
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Không thể cập nhật danh sách yêu thích'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          print("Lỗi xử lý yêu thích: $e");
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Lỗi xử lý yêu thích: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                              Colors.black.withOpacity(0.1),
                                              blurRadius: 6,
                                              spreadRadius: 0,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          isInWishlist
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isInWishlist
                                              ? Colors.red
                                              : AppColors.greyFont,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    loading: () => Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                            Colors.black.withOpacity(0.1),
                                            blurRadius: 6,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              AppColors.primaryColor),
                                        ),
                                      ),
                                    ),
                                    error: (_, __) => Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                            Colors.black.withOpacity(0.1),
                                            blurRadius: 6,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.favorite_border,
                                        color: AppColors.greyFont,
                                        size: 18,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        // Chi tiết sản phẩm
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
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
                                const SizedBox(height: 6),

                                // Thông tin tồn kho - luôn ở vị trí cố định
                                Container(
                                  constraints:
                                  const BoxConstraints(maxWidth: 85),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? AppColors.primaryColor
                                        .withOpacity(0.15)
                                        : AppColors.primaryColor
                                        .withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 9,
                                        color: product.stock > 5
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 2),
                                      Flexible(
                                        child: Text(
                                          'Còn ${product.stock}',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color: product.stock > 5
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Spacer(),

                                // Phần dưới - giá và nút đều có vị trí cố định
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Giá
                                    Text(
                                      '${NumberFormat.decimalPattern().format(product.price)} VNĐ',
                                      style: TextStyle(
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),

                                    // Nút Xem chi tiết
                                    SizedBox(
                                      width: double.infinity,
                                      height: 26,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProductDetail(
                                                      product: product),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                          AppColors.buttonColor,
                                          foregroundColor: AppColors.fontLight,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(25),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Đã xảy ra lỗi: ${error.toString()}',
              style: TextStyle(color: AppColors.fontBlack),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_isSearching && _searchQuery.isNotEmpty) {
                  ref
                      .read(main_provider.productProvider)
                      .searchProducts(_searchQuery, perPage: 10);
                } else {
                  ref.read(main_provider.productProvider).reset();
                  ref
                      .read(main_provider.productProvider)
                      .fetchProducts(perPage: 10);
                }
              },
              child: Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.fontLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
