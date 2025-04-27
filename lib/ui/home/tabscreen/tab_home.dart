// ignore: file_names
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/data_file.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:shoplite/constants/widget_utils.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/models/model_banner.dart';
import 'package:shoplite/models/model_category.dart';
import 'package:shoplite/models/model_trending.dart';
import 'package:shoplite/models/product.dart';
import 'package:shoplite/ui/home/home_screen.dart';
import 'package:shoplite/ui/product/all_product_list.dart';
import 'package:shoplite/ui/category/category_list.dart';
import 'package:shoplite/ui/search/search_screen.dart';
import 'package:shoplite/providers/category_provider.dart';
import 'package:shoplite/providers/product_provider.dart';
import '../../product/product_detail.dart';
import 'package:shoplite/constants/utils.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';
import 'package:shoplite/widgets/cart_icon_badge.dart';
import 'package:shoplite/widgets/optimized_image.dart';
import 'package:shoplite/widgets/product_card.dart';
import 'package:shoplite/widgets/product_list_item.dart';

class TabHome extends StatefulWidget {
  const TabHome({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TabHome();
  }
}

class _TabHome extends State<TabHome> with SingleTickerProviderStateMixin {
  List<ModelBanner> bannerList = DataFile.getAllBanner();
  int selectedSlider = 0;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  Timer? _debounce;
  bool isDarkMode = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    isDarkMode = ThemeController.isDarkMode;
    ThemeController.addListener(_onThemeChanged);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    _animationController.dispose();
    ThemeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {
      isDarkMode = ThemeController.isDarkMode;
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          searchQuery = query;
        });
        if (query.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchScreen(),
            ),
          );
        }
      }
    });
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.fontBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side:
                    BorderSide(color: AppColors.primaryColor.withOpacity(0.3)),
              ),
            ),
            child: Text(
              "Xem tất cả",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double screenWidth = SizeConfig.safeBlockHorizontal! * 100;
    double carousalHeight = 200;

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
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.2)
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          Constant.sendToScreen(const SearchScreen(), context);
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Tìm kiếm sản phẩm...",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.camera,
                              color: Colors.white.withOpacity(0.7),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const ChatIconBadge(size: 26),
                      ),
                      SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const CartIconBadge(size: 22),
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
          // Background gradient covering the whole screen
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Consumer(
                builder: (context, ref, _) {
                  return RefreshIndicator(
                    color: AppColors.primaryColor,
                    onRefresh: () async {
                      // Now we have access to ref inside the Consumer
                      ref.refresh(categoryListProvider);
                      ref.refresh(productListProvider);
                      ref.refresh(randomProductsProvider);
                      return Future.value();
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Provide space for content to start below the app bar
                        SliverPadding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 5,
                          ),
                          sliver: SliverToBoxAdapter(child: SizedBox()),
                        ),

                        // Carousel
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Column(
                              children: [
                                CarouselSlider(
                                  options: CarouselOptions(
                                    height: carousalHeight,
                                    autoPlay: true,
                                    viewportFraction: 0.92,
                                    enlargeCenterPage: true,
                                    onPageChanged: (index, _) {
                                      setState(() {
                                        selectedSlider = index;
                                      });
                                    },
                                    autoPlayInterval: Duration(seconds: 4),
                                    autoPlayAnimationDuration:
                                        Duration(milliseconds: 800),
                                    autoPlayCurve: Curves.fastOutSlowIn,
                                    pauseAutoPlayOnTouch: true,
                                  ),
                                  items: bannerList
                                      .map((item) => Container(
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 5),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDarkMode
                                                      ? Colors.black
                                                          .withOpacity(0.2)
                                                      : Colors.grey
                                                          .withOpacity(0.3),
                                                  blurRadius: 10,
                                                  offset: Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Image.asset(
                                                    Constant.assetImagePath +
                                                        item.image!,
                                                    fit: BoxFit.cover,
                                                  ),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        colors: [
                                                          Colors.transparent,
                                                          Colors.black
                                                              .withOpacity(0.5),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  if (item.title != null &&
                                                      item.title!.isNotEmpty)
                                                    Positioned(
                                                      bottom: 20,
                                                      left: 20,
                                                      child: Container(
                                                        width:
                                                            screenWidth * 0.6,
                                                        child: Text(
                                                          item.title!,
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            shadows: [
                                                              Shadow(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.5),
                                                                offset: Offset(
                                                                    1, 1),
                                                                blurRadius: 3,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                                SizedBox(height: 16),
                                DotsIndicator(
                                  dotsCount: bannerList.length,
                                  position: selectedSlider,
                                  decorator: DotsDecorator(
                                    size: const Size(8, 8),
                                    activeSize: const Size(24, 8),
                                    activeShape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                    color: AppColors.greyFont.withOpacity(0.3),
                                    activeColor: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Categories
                        SliverToBoxAdapter(
                          child: _buildSectionHeader("Danh mục", () {
                            Constant.sendToScreen(
                                const CategoryList(), context);
                          }),
                        ),

                        SliverToBoxAdapter(
                          child: SizedBox(
                            height:
                                120 * MediaQuery.of(context).textScaleFactor,
                            child: Consumer(
                              builder: (context, ref, child) {
                                final categoryListAsync =
                                    ref.watch(categoryListProvider);

                                return categoryListAsync.when(
                                  data: (categories) {
                                    return ListView.builder(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 16),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: categories.length,
                                      itemBuilder: (context, index) {
                                        final category = categories[index];
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CategoryList(
                                                  initialCategoryId:
                                                      category.id,
                                                  initialCategoryName:
                                                      category.title,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 90,
                                            margin: EdgeInsets.only(right: 16),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  height: 70,
                                                  width: 70,
                                                  decoration: BoxDecoration(
                                                    color: isDarkMode
                                                        ? AppColors.primaryColor
                                                            .withOpacity(0.2)
                                                        : AppColors.primaryColor
                                                            .withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: AppColors
                                                            .shadowColor,
                                                        blurRadius: 5,
                                                        offset: Offset(0, 3),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            35),
                                                    child: category
                                                            .photos.isNotEmpty
                                                        ? CachedNetworkImage(
                                                            imageUrl: _getImageUrl(
                                                                category
                                                                    .photos[0]),
                                                            fit: BoxFit.cover,
                                                            placeholder:
                                                                (context,
                                                                        url) =>
                                                                    Center(
                                                              child:
                                                                  CircularProgressIndicator(
                                                                color: AppColors
                                                                    .primaryColor,
                                                                strokeWidth:
                                                                    2.0,
                                                              ),
                                                            ),
                                                            errorWidget:
                                                                (context, url,
                                                                        error) =>
                                                                    Container(
                                                              color: isDarkMode
                                                                  ? AppColors
                                                                      .cardColor
                                                                  : Colors.grey[
                                                                      200],
                                                              child: Icon(
                                                                Icons.category,
                                                                size: 30,
                                                                color: AppColors
                                                                    .primaryColor,
                                                              ),
                                                            ),
                                                          )
                                                        : Icon(
                                                            Icons.category,
                                                            size: 30,
                                                            color: AppColors
                                                                .primaryColor,
                                                          ),
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Flexible(
                                                  child: Text(
                                                    category.title,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          AppColors.fontBlack,
                                                    ),
                                                    maxLines: 2,
                                                    textAlign: TextAlign.center,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  loading: () => Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                  error: (error, _) => Center(
                                    child: Text(
                                      'Không thể tải danh mục: $error',
                                      style:
                                          TextStyle(color: AppColors.fontBlack),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Trending Products
                        SliverToBoxAdapter(
                          child: _buildSectionHeader("Sản phẩm mới nhất", () {
                            Constant.sendToScreen(
                                const AllProductList(), context);
                          }),
                        ),

                        SliverToBoxAdapter(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final productListAsync =
                                  ref.watch(productListProvider);

                              return productListAsync.when(
                                data: (products) {
                                  return HorizontalProductList(
                                    products: products,
                                    isDarkMode: isDarkMode,
                                    onProductTap: (product) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetail(
                                            product: product,
                                          ),
                                        ),
                                      );
                                    },
                                    getImageUrl: _getImageUrl,
                                    formatPrice: _formatPrice,
                                  );
                                },
                                loading: () => Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                                error: (error, _) => Center(
                                  child: Text(
                                    'Không thể tải sản phẩm: $error',
                                    style:
                                        TextStyle(color: AppColors.fontBlack),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Popular Products
                        SliverToBoxAdapter(
                          child: _buildSectionHeader("Sản phẩm phổ biến", () {
                            Constant.sendToScreen(
                                const AllProductList(), context);
                          }),
                        ),

                        SliverToBoxAdapter(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final randomProductsAsync =
                                  ref.watch(randomProductsProvider);

                              return randomProductsAsync.when(
                                data: (products) {
                                  if (products.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: 100,
                                          maxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.2,
                                        ),
                                        child: SingleChildScrollView(
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.shopping_basket_outlined,
                                                size: 36,
                                                color: AppColors.greyFont,
                                              ),
                                              SizedBox(height: 12),
                                              Text(
                                                'Không có sản phẩm nào',
                                                style: TextStyle(
                                                  color: AppColors.greyFont,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  return VerticalProductList(
                                    products: products,
                                    isDarkMode: isDarkMode,
                                    onProductTap: (product) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetail(
                                            product: product,
                                          ),
                                        ),
                                      );
                                    },
                                    getImageUrl: _getImageUrl,
                                    formatPrice: _formatPrice,
                                    showDescription: false,
                                  );
                                },
                                loading: () => Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                error: (error, stack) => Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: 100,
                                      maxHeight:
                                          MediaQuery.of(context).size.height *
                                              0.25,
                                    ),
                                    child: SingleChildScrollView(
                                      physics: NeverScrollableScrollPhysics(),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 36,
                                            color: Colors.red.shade300,
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Không thể tải sản phẩm: ${error.toString().split(":").first}',
                                            style: TextStyle(
                                              color: AppColors.fontBlack,
                                              fontSize: 13,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 12),
                                          ElevatedButton(
                                            onPressed: () {
                                              // Refresh the provider
                                              ref.refresh(
                                                  randomProductsProvider);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primaryColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12.0,
                                                vertical: 6.0,
                                              ),
                                              child: Text('Thử lại'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Extra space at bottom
                        SliverToBoxAdapter(
                          child: SizedBox(height: 20),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0)} đ'.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  String _getImageUrl(String url) {
    try {
      // Handle empty or null URLs
      if (url.isEmpty) {
        return '';
      }
      return getImageUrl(url);
    } catch (e) {
      print("Error processing URL: $e");
      return '';
    }
  }
}
