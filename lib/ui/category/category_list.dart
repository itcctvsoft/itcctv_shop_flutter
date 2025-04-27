import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/providers/category_provider.dart';
import 'package:shoplite/providers/product_provider.dart';
import 'package:shoplite/providers/wishlist_provider.dart';
import '../../../constants/color_data.dart';
import '../../../constants/constant.dart';
import '../../../constants/size_config.dart';
import '../../constants/widget_utils.dart';
import '../product/product_detail.dart';
import '../product/all_product_list.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';
import 'package:shoplite/constants/utils.dart';
import 'package:shoplite/utils/auth_helpers.dart';
import 'package:shoplite/ui/widgets/auth_action_view.dart';
import 'package:shoplite/ui/widgets/notification_dialog.dart';
import 'package:shoplite/ui/home/home_screen.dart';
import 'package:shoplite/widgets/optimized_image.dart';

class CategoryList extends ConsumerStatefulWidget {
  final int? initialCategoryId;
  final String? initialCategoryName;

  const CategoryList({
    Key? key,
    this.initialCategoryId,
    this.initialCategoryName,
  }) : super(key: key);

  @override
  _CategoryListState createState() => _CategoryListState();
}

class _CategoryListState extends ConsumerState<CategoryList> {
  bool isDarkMode = false;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int? _selectedCategoryId;
  String _selectedCategoryName = "";

  @override
  void initState() {
    super.initState();
    isDarkMode = ThemeController.isDarkMode;
    ThemeController.addListener(_onThemeChanged);

    // Add scroll listener for infinite scrolling
    _scrollController.addListener(_scrollListener);

    // If initial category is provided, load its products
    if (widget.initialCategoryId != null &&
        widget.initialCategoryName != null) {
      // Use a short delay to allow the widget to fully initialize
      Future.delayed(Duration.zero, () {
        if (mounted) {
          _loadCategoryProducts(
              widget.initialCategoryId!, widget.initialCategoryName!);
        }
      });
    }
  }

  @override
  void dispose() {
    ThemeController.removeListener(_onThemeChanged);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll listener to load more products when reaching bottom
  void _scrollListener() {
    if (_scrollController.position.extentAfter < 200 &&
        !_isLoadingMore &&
        _selectedCategoryId != null) {
      _loadMoreProducts();
    }
  }

  // Load more products for selected category
  void _loadMoreProducts() {
    final productProviderState = ref.read(productProvider);

    // Check if loading is in progress and if there are more pages to load
    if (!_isLoadingMore &&
        !productProviderState.isLoading &&
        productProviderState.currentPage < productProviderState.totalPages) {
      setState(() {
        _isLoadingMore = true;
      });

      // Load more products
      productProviderState.loadMore().then((_) {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  void _onThemeChanged() {
    setState(() {
      isDarkMode = ThemeController.isDarkMode;
    });
  }

  // Load products for a specific category
  void _loadCategoryProducts(int categoryId, String categoryName) {
    print('Loading products for category: $categoryId - $categoryName');
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = categoryName;
    });

    // Reset and fetch products for the selected category
    final productProviderState = ref.read(productProvider);
    productProviderState.reset();
    // Đảm bảo lấy dữ liệu mới từ server thay vì cache
    productProviderState.fetchProductsByCategory(categoryId,
        forceRefresh: true, perPage: 10);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Tải lại dữ liệu nếu có categoryId được chọn và quay lại từ màn hình khác
    if (_selectedCategoryId != null &&
        _selectedCategoryName != null &&
        _selectedCategoryName!.isNotEmpty) {
      final productProviderState = ref.read(productProvider);
      if (productProviderState.products.isEmpty ||
          productProviderState.currentCategoryId != _selectedCategoryId) {
        print(
            'Reloading products in didChangeDependencies for category: $_selectedCategoryId - $_selectedCategoryName');
        Future.microtask(() {
          productProviderState.reset();
          productProviderState.fetchProductsByCategory(_selectedCategoryId!,
              forceRefresh: true, perPage: 10);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    double screenWidth = SizeConfig.safeBlockHorizontal! * 100;
    double marginPopular = 10;
    int crossAxisCountPopular = 2;
    double popularWidth =
        (screenWidth - ((crossAxisCountPopular - 1) * marginPopular)) /
            crossAxisCountPopular;
    double popularHeight = popularWidth * 1.2;

    return Consumer(
      builder: (context, ref, child) {
        final categoryListAsync = ref.watch(categoryListProvider);
        final productProviderState = ref.watch(productProvider);

        return WillPopScope(
          onWillPop: () async {
            if (_selectedCategoryId != null) {
              // Go back to category selection
              setState(() {
                _selectedCategoryId = null;
                _selectedCategoryName = "";
              });
              return false;
            }
            Constant.backToFinish(context);
            return false;
          },
          child: Scaffold(
            backgroundColor: AppColors.backgroundColor,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_selectedCategoryId != null) {
                              // Go back to category selection
                              setState(() {
                                _selectedCategoryId = null;
                                _selectedCategoryName = "";
                              });
                            } else {
                              Constant.backToFinish(context);
                            }
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
                        Expanded(
                          child: Text(
                            _selectedCategoryId != null
                                ? _selectedCategoryName
                                : "Danh mục",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.fontLight,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                        stops:
                            isDarkMode ? const [0.0, 0.35] : const [0.0, 0.3],
                      ),
                    ),
                  ),
                ),
                // Content
                _selectedCategoryId != null
                    ? _buildProductList(productProviderState)
                    : categoryListAsync.when(
                        data: (categories) {
                          return GridView.builder(
                            padding: const EdgeInsets.all(10),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCountPopular,
                              crossAxisSpacing: marginPopular,
                              mainAxisSpacing: marginPopular,
                              childAspectRatio: popularWidth / popularHeight,
                            ),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];

                              return InkWell(
                                onTap: () {
                                  _loadCategoryProducts(
                                      category.id, category.title);
                                },
                                child: Column(
                                  children: [
                                    // Hình ảnh danh mục bo góc kiểu elip
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: OptimizedImage(
                                        imageUrl: _getImageUrl(
                                            category.photos.isNotEmpty
                                                ? category.photos[0]
                                                : ''),
                                        width: popularWidth * 0.7,
                                        height: popularWidth * 0.7,
                                        fit: BoxFit.cover,
                                        isDarkMode: isDarkMode,
                                        borderRadius: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // Tên danh mục
                                    Text(
                                      category.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.fontBlack,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => Center(
                            child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryColor),
                        )),
                        error: (error, stackTrace) => Center(
                            child: Text(
                          'Error: ${error.toString()}',
                          style: TextStyle(color: AppColors.fontBlack),
                        )),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductList(ProductProvider provider) {
    if (provider.isLoading && provider.products.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
        ),
      );
    }

    if (provider.errorMessage != null && provider.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Đã xảy ra lỗi: ${provider.errorMessage}',
              style: TextStyle(color: AppColors.fontBlack),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_selectedCategoryId != null) {
                  provider.fetchProductsByCategory(_selectedCategoryId!);
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
      );
    }

    if (provider.products.isEmpty) {
      return Center(
        child: Text(
          'Không có sản phẩm nào trong danh mục này.',
          style: TextStyle(color: AppColors.fontBlack),
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: provider.products.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.products.length) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          );
        }

        final product = provider.products[index];
        return _buildProductItem(product);
      },
    );
  }

  Widget _buildProductItem(product) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetail(product: product),
          ),
        );
      },
      child: Card(
        elevation: 3,
        color: AppColors.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(10)),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(10)),
                      child: product.photos.isNotEmpty
                          ? OptimizedImage(
                              imageUrl: _getImageUrl(product.photos.first),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              isDarkMode: isDarkMode,
                              borderRadius: 10,
                            )
                          : Container(
                              color: isDarkMode
                                  ? AppColors.cardColor
                                  : Colors.grey[300],
                              child:
                                  Icon(Icons.image, color: AppColors.greyFont),
                            ),
                    ),
                  ),
                  // Wishlist button
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final isInWishlistAsync =
                            ref.watch(isProductInWishlistProvider(product.id));

                        return isInWishlistAsync.when(
                          data: (isInWishlist) => GestureDetector(
                            onTap: () async {
                              // Check login status before wishlist operation
                              bool isLoggedIn = await AuthHelpers.isLoggedIn();
                              if (!isLoggedIn) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AuthActionView(
                                      featureDescription: "yêu thích sản phẩm",
                                      featureIcon: Icons.favorite_border,
                                      onBackPressed: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                );
                                return;
                              }

                              // Add/remove product from wishlist
                              try {
                                bool success = await ref
                                    .read(wishlistProductIdsProvider.notifier)
                                    .toggleWishlist(product.id);

                                if (success) {
                                  if (isInWishlist) {
                                    // Notification when removing from wishlist
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
                                    // Notification when adding to wishlist
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Không thể cập nhật danh sách yêu thích'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('Lỗi xử lý yêu thích: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi xử lý yêu thích: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColors.fontLight.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isInWishlist
                                    ? Colors.red
                                    : AppColors.greyFont,
                                size: 20,
                              ),
                            ),
                          ),
                          loading: () => Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.fontLight.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.greyFont),
                              ),
                            ),
                          ),
                          error: (_, __) => Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.fontLight.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_border,
                              color: AppColors.greyFont,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.fontBlack,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Flexible(
                          flex: 3,
                          child: Text(
                            '${product.price.toStringAsFixed(0)} đ',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          flex: 2,
                          child: Text(
                            'Còn ${product.stock}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.greyFont,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
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
  }

  /// Thay đổi URL để hoạt động trên giả lập Android
  String _getImageUrl(String url) {
    return getImageUrl(url);
  }
}
