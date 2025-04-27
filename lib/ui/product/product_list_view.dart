import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoplite/constants/apilist.dart';

enum SortOption { nameAsc, nameDesc, priceAsc, priceDesc }

class ProductListView extends ConsumerStatefulWidget {
  final String categorySlug;
  final String categoryName;

  const ProductListView({
    Key? key,
    required this.categorySlug,
    required this.categoryName,
  }) : super(key: key);

  @override
  ConsumerState<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends ConsumerState<ProductListView> {
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  List<int> favouriteIds = [];
  late SharedPreferences prefs;
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = true; // Mặc định hiển thị dạng grid
  SortOption _currentSortOption = SortOption.nameAsc;
  bool _isLoadingMore = false;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadFavourites();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = ref.read(main_provider.productProvider);
      provider.reset();
      provider.fetchProducts(perPage: 10);
    });

    _scrollController.addListener(_scrollListener);
    isDarkMode = ThemeController.isDarkMode;
    ThemeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    ThemeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> _loadFavourites() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      favouriteIds =
          prefs.getStringList('favourites')?.map(int.parse).toList() ?? [];
    });
  }

  void _onThemeChanged() {
    setState(() {
      isDarkMode = ThemeController.isDarkMode;
    });
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter < 200 && !_isLoadingMore) {
      final provider = ref.read(main_provider.productProvider);
      if (!provider.isLoading) {
        setState(() {
          _isLoadingMore = true;
        });
        provider.loadMore().then((_) {
          if (mounted) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }

  Future<void> _handlePageChange(int page) async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await ref.read(main_provider.productProvider).goToPage(page);
      await ref.read(main_provider.productProvider).fetchProducts(perPage: 10);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProviderState = ref.watch(main_provider.productProvider);
    final categoryId = int.tryParse(widget.categorySlug) ?? 0;

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
                        color: AppColors.fontLight,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.categoryName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.fontLight,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isGridView ? Icons.view_list : Icons.grid_view,
                        color: AppColors.fontLight,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Sort button
                  GestureDetector(
                    onTap: () {
                      _showSortMenu(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sort,
                        color: AppColors.fontLight,
                        size: 22,
                      ),
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
          Column(
            children: [
              Expanded(
                child: _buildProductList(productProviderState),
              ),
              // Widget phân trang ở cuối màn hình
              Container(
                color: AppColors.cardColor,
                child: PaginationControls(
                  currentPage: productProviderState.currentPage,
                  totalPages: productProviderState.totalPages,
                  isLoading: productProviderState.isLoading || _isLoadingMore,
                  onPageChanged: _handlePageChange,
                ),
              ),
            ],
          ),
          // Overlay loading khi đang chuyển trang
          if (_isLoadingMore)
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

  // Sắp xếp sản phẩm theo lựa chọn
  void _sortProducts(SortOption option) {
    final provider = ref.read(main_provider.productProvider);
    final products = List<Product>.from(provider.products);

    switch (option) {
      case SortOption.nameAsc:
        products.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.nameDesc:
        products.sort((a, b) => b.title.compareTo(a.title));
        break;
      case SortOption.priceAsc:
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceDesc:
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
    }

    // Cập nhật UI với danh sách đã sắp xếp (mô phỏng)
    setState(() {});
  }

  // Show the sort menu dialog
  void _showSortMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Sắp xếp theo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.fontBlack,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortOption(context, SortOption.nameAsc, 'Tên (A-Z)'),
              _buildSortOption(context, SortOption.nameDesc, 'Tên (Z-A)'),
              _buildSortOption(context, SortOption.priceAsc, 'Giá (Thấp-Cao)'),
              _buildSortOption(context, SortOption.priceDesc, 'Giá (Cao-Thấp)'),
            ],
          ),
        );
      },
    );
  }

  // Build a sort option item for the dialog
  Widget _buildSortOption(
      BuildContext context, SortOption option, String title) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.fontBlack,
          fontWeight: _currentSortOption == option
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      leading: Radio<SortOption>(
        value: option,
        groupValue: _currentSortOption,
        activeColor: AppColors.primaryColor,
        onChanged: (SortOption? value) {
          Navigator.pop(context);
          if (value != null) {
            setState(() {
              _currentSortOption = value;
              _sortProducts(value);
            });
          }
        },
      ),
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _currentSortOption = option;
          _sortProducts(option);
        });
      },
    );
  }

  Widget _buildProductList(main_provider.ProductProvider provider) {
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
                final categoryId = int.tryParse(widget.categorySlug) ?? 0;
                provider.fetchProductsByCategory(categoryId);
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

    return _isGridView
        ? _buildGridView(provider.products)
        : _buildListView(provider.products);
  }

  // Hiển thị sản phẩm dạng lưới
  Widget _buildGridView(List<Product> products) {
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == products.length) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          );
        }

        final product = products[index];
        return _buildGridItem(product);
      },
    );
  }

  // Widget sản phẩm dạng lưới
  Widget _buildGridItem(Product product) {
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
            // Ảnh sản phẩm
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(10)),
                    child: product.photos.isNotEmpty
                        ? Image.network(
                      _getImageUrl(product.photos.first),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDarkMode
                              ? AppColors.cardColor
                              : Colors.grey[300],
                          child: Icon(Icons.image_not_supported,
                              color: AppColors.greyFont),
                        );
                      },
                    )
                        : Container(
                      color: isDarkMode
                          ? AppColors.cardColor
                          : Colors.grey[300],
                      child: Icon(Icons.image, color: AppColors.greyFont),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: _buildWishlistButton(product.id),
                  ),
                ],
              ),
            ),
            // Thông tin sản phẩm
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  SizedBox(height: 5),
                  Text(
                    _formatPrice(product.price),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hiển thị sản phẩm dạng danh sách
  Widget _buildListView(List<Product> products) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(12),
      itemCount: products.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == products.length) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          );
        }

        final product = products[index];
        return _buildListItem(product);
      },
    );
  }

  // Widget sản phẩm dạng danh sách
  Widget _buildListItem(Product product) {
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
        elevation: 2,
        color: AppColors.cardColor,
        margin: EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: product.photos.isNotEmpty
                  ? Image.network(
                product.photos.first,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 120,
                    height: 120,
                    color: isDarkMode
                        ? AppColors.cardColor
                        : Colors.grey[300],
                    child: Icon(Icons.image_not_supported,
                        color: AppColors.greyFont),
                  );
                },
              )
                  : Container(
                width: 120,
                height: 120,
                color:
                isDarkMode ? AppColors.cardColor : Colors.grey[300],
                child: Icon(Icons.image, color: AppColors.greyFont),
              ),
            ),
            // Thông tin sản phẩm
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.fontBlack,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.greyFont,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(0)} đ',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Còn 10',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.greyFont,
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

  String _getImageUrl(String url) {
    return getImageUrl(url);
  }

  String _formatPrice(double price) {
    // Format with thousands separator
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  // Widget để hiển thị biểu tượng yêu thích
  Widget _buildWishlistButton(int productId) {
    return Consumer(
      builder: (context, ref, _) {
        final isInWishlistAsync =
        ref.watch(isProductInWishlistProvider(productId));

        return isInWishlistAsync.when(
          data: (isInWishlist) {
            return InkWell(
              onTap: () async {
                // Kiểm tra đăng nhập trước khi thao tác với yêu thích
                bool isLoggedIn = await AuthHelpers.isLoggedIn();
                if (!isLoggedIn) {
                  // Hiển thị thông báo yêu cầu đăng nhập
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

                // Thực hiện toggle wishlist
                bool success = await ref
                    .read(wishlistProductIdsProvider.notifier)
                    .toggleWishlist(productId);

                if (success) {
                  // Hiển thị thông báo thành công nếu cần
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isInWishlist
                          ? 'Đã xóa sản phẩm khỏi danh sách yêu thích'
                          : 'Đã thêm sản phẩm vào danh sách yêu thích'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.fontLight,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  isInWishlist ? Icons.favorite : Icons.favorite_border,
                  color: isInWishlist ? Colors.red : AppColors.greyFont,
                  size: 20,
                ),
              ),
            );
          },
          loading: () => SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
          error: (_, __) => SizedBox(), // Hiển thị rỗng nếu có lỗi
        );
      },
    );
  }
}
