// ignore: file_names
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/providers/product_provider.dart' as main_provider;
import 'package:shoplite/ui/product/product_detail.dart';
import 'package:shoplite/constants/utils.dart';

import 'package:shoplite/ui/search/filter_screen.dart';

import '../../constants/widget_utils.dart';
import '../../constants/color_data.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';
import 'package:shoplite/widgets/optimized_image.dart';
import 'package:intl/intl.dart';

// Đảm bảo sử dụng productProvider từ file product_list_screen.dart
import 'package:shoplite/ui/products/product_list_screen.dart';
import 'package:shoplite/models/product.dart';
import 'package:shoplite/providers/wishlist_provider.dart';
import 'package:shoplite/ui/widgets/notification_dialog.dart';
import 'package:shoplite/ui/home/home_screen.dart';
import 'package:shoplite/utils/auth_helpers.dart';
import 'package:shoplite/ui/login/login_screen.dart';
import 'package:shoplite/ui/widgets/auth_action_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<int> favouriteIds = [];
  late SharedPreferences prefs;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool isDarkMode = false;
  final NumberFormat _priceFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

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
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    ThemeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter < 200 && !_isLoadingMore) {
      final provider = ref.read(main_provider.productProvider);
      if (!provider.isLoading && provider.currentPage < provider.totalPages) {
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

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _searchQuery = query;
      });

      // Hiển thị loading indicator
      setState(() {
        _isLoadingMore = true;
      });

      // Thực hiện tìm kiếm
      ref
          .read(main_provider.productProvider)
          .searchProducts(
            query,
            perPage: 10,
          )
          .then((_) {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Có lỗi xảy ra: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final productProviderState = ref.watch(main_provider.productProvider);

    return Scaffold(
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
                color: AppColors.shadowColor,
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
                        color: AppColors.fontLight.withOpacity(0.2),
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
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.fontLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: AppColors.fontLight),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm sản phẩm...',
                          hintStyle: TextStyle(
                              color: AppColors.fontLight.withOpacity(0.7)),
                          border: InputBorder.none,
                          suffixIcon: GestureDetector(
                            onTap: _handleSearch,
                            child: Icon(
                              Icons.search,
                              color: AppColors.fontLight,
                              size: 22,
                            ),
                          ),
                        ),
                        onSubmitted: (value) {
                          _handleSearch();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const ChatIconBadge(size: 26),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _searchQuery.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 80,
                          color: AppColors.primaryColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nhập từ khóa để tìm kiếm sản phẩm',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.greyFont,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Gợi ý tìm kiếm:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildSuggestionChip('Laptop'),
                            _buildSuggestionChip('Điện thoại'),
                            _buildSuggestionChip('Máy tính bảng'),
                            _buildSuggestionChip('Tai nghe'),
                            _buildSuggestionChip('Smart watch'),
                          ],
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      _buildSearchResults(productProviderState),
                      if (_isLoadingMore &&
                          productProviderState.products.isEmpty)
                        Container(
                          color: AppColors.fontBlack.withOpacity(0.3),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryColor),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị chip gợi ý
  Widget _buildSuggestionChip(String suggestion) {
    return GestureDetector(
      onTap: () {
        _searchController.text = suggestion;
        _handleSearch();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          suggestion,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.fontBlack,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(main_provider.ProductProvider provider) {
    if (provider.isLoading && provider.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            SizedBox(height: 16),
            Text(
              'Đang tìm kiếm...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.greyFont,
              ),
            ),
          ],
        ),
      );
    }

    if (provider.errorMessage != null && provider.products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Không thể tìm kiếm sản phẩm',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.fontBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${provider.errorMessage}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.greyFont,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (_searchQuery.isNotEmpty) {
                    provider.searchProducts(_searchQuery, perPage: 10);
                  }
                },
                icon: Icon(Icons.refresh),
                label: Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.fontLight,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.greyFont.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Không tìm thấy sản phẩm nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.fontBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thử với từ khóa khác hoặc bỏ bớt bộ lọc',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.greyFont,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_searchQuery.isNotEmpty) {
                  provider.searchProducts(_searchQuery, perPage: 10);
                }
              },
              icon: Icon(Icons.filter_alt_off),
              label: Text('Bỏ tất cả bộ lọc'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.fontLight,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: provider.products.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.products.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              ),
            );
          }

          final product = provider.products[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            color: AppColors.cardColor,
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 12,
                cornerSmoothing: 0.6,
              ),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetail(product: product),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Ảnh sản phẩm
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: ThemeController.isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: product.photos.isNotEmpty
                            ? OptimizedImage(
                                imageUrl: getImageUrl(product.photos[0]),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                isDarkMode: isDarkMode,
                                borderRadius: 10,
                              )
                            : Icon(
                                Icons.image_not_supported,
                                color: AppColors.greyFont,
                                size: 40,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
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
                          const SizedBox(height: 6),
                          Text(
                            _priceFormat.format(product.price),
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Icon mũi tên bên phải
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.greyFont,
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
