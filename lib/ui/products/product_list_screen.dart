import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/models/product.dart';
import 'package:shoplite/providers/product_provider.dart';
import 'package:shoplite/repositories/product_repository.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/constants/utils.dart';
import 'package:shoplite/constants/widget_utils.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';
import 'package:shoplite/widgets/optimized_image.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final productProvider = ChangeNotifierProvider<ProductProvider>((ref) {
  final repository = ref.read(productRepositoryProvider);
  return ProductProvider(repository);
});

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    // Tải sản phẩm khi màn hình được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productProvider).fetchProducts(reset: true);
    });

    // Đăng ký lắng nghe scroll để tải thêm sản phẩm khi cuộn đến cuối danh sách
    _scrollController.addListener(_onScroll);

    // Khởi tạo trạng thái dark mode
    isDarkMode = ThemeController.isDarkMode;
    ThemeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    ThemeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {
      isDarkMode = ThemeController.isDarkMode;
    });
  }

  // Xử lý sự kiện khi người dùng cuộn đến cuối danh sách
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = ref.read(productProvider);
      if (!provider.isLoading) {
        provider.loadMore();
      }
    }
  }

  // Xử lý sự kiện tìm kiếm
  void _handleSearch() {
    final keyword = _searchController.text.trim();
    if (keyword.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });
      ref.read(productProvider).searchProducts(keyword);
    }
  }

  // Xóa tìm kiếm và hiển thị lại tất cả sản phẩm
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
    ref.read(productProvider).fetchProducts(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(productProvider);

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
                            'Sản phẩm',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.fontLight,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                  _isSearching
                      ? GestureDetector(
                          onTap: _clearSearch,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: AppColors.fontLight,
                              size: 22,
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSearching = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.search,
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
      body: _buildBody(provider),
      backgroundColor: AppColors.backgroundColor,
    );
  }

  Widget _buildBody(ProductProvider provider) {
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
                provider.fetchProducts(reset: true);
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
          'Không có sản phẩm nào.',
          style: TextStyle(color: AppColors.fontBlack),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await provider.fetchProducts(reset: true);
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount:
                  provider.products.length + (provider.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.products.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor),
                      ),
                    ),
                  );
                }

                final product = provider.products[index];
                return ProductCard(
                  product: product,
                  isDarkMode: isDarkMode,
                );
              },
            ),
          ),
        ),
        // Widget phân trang ở cuối màn hình
        Container(
          color: AppColors.cardColor,
          child: PaginationControls(
            currentPage: provider.currentPage,
            totalPages: provider.totalPages,
            isLoading: provider.isLoading,
            onPageChanged: (page) async {
              await provider.goToPage(page);
              await provider.fetchProducts(perPage: 10);
            },
          ),
        ),
      ],
    );
  }
}

// Widget hiển thị một sản phẩm
class ProductCard extends StatelessWidget {
  final Product product;
  final bool isDarkMode;

  const ProductCard({
    Key? key,
    required this.product,
    this.isDarkMode = false,
  }) : super(key: key);

  // Hàm lấy URL ảnh đúng
  String _getImageUrl(String url) {
    return getImageUrl(url);
  }

  // Hàm định dạng giá tiền
  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.cardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.photos.isNotEmpty
                  ? OptimizedImage(
                      imageUrl: _getImageUrl(product.photos.first),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      isDarkMode: isDarkMode,
                      borderRadius: 8,
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color:
                          isDarkMode ? AppColors.cardColor : Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppColors.greyFont,
                      ),
                    ),
            ),
            SizedBox(width: 16),
            // Thông tin sản phẩm
            Expanded(
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
                  SizedBox(height: 4),
                  Text(
                    _formatPrice(product.price),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.greyFont,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Còn ${product.stock}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.greyFont,
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
}
