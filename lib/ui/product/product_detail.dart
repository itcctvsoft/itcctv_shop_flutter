import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:shoplite/models/product.dart';
import 'package:shoplite/providers/cart_provider.dart';
import 'package:shoplite/constants/pref_data.dart';
import 'package:shoplite/providers/wishlist_provider.dart';
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/constants/utils.dart';
import 'package:shoplite/ui/product/comment_section.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/ui/widgets/notification_dialog.dart';
import 'package:shoplite/ui/home/home_screen.dart';
import 'package:shoplite/ui/product/all_product_list.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';
import 'package:shoplite/utils/auth_helpers.dart';
import 'package:shoplite/widgets/auth_required_wrapper.dart';
import 'package:shoplite/widgets/optimized_image.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'dart:math' as Math;

// Provider to check if a product has any ratings
final hasRatingsProvider =
    FutureProvider.family<bool, int>((ref, productId) async {
  final commentsState = ref.watch(commentsStateProvider(productId));
  return commentsState.when(
    data: (commentResponse) => commentResponse.totalComments > 0,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Provider to get the average rating for a product
final productRatingProvider =
    FutureProvider.family<double, int>((ref, productId) async {
  final commentsState = ref.watch(commentsStateProvider(productId));
  return commentsState.when(
    data: (commentResponse) => commentResponse.averageRating,
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

// Provider to get the total number of ratings
final ratingCountProvider =
    FutureProvider.family<int, int>((ref, productId) async {
  final commentsState = ref.watch(commentsStateProvider(productId));
  return commentsState.when(
    data: (commentResponse) => commentResponse.totalComments,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

class ProductDetail extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetail({Key? key, required this.product}) : super(key: key);

  @override
  ConsumerState<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends ConsumerState<ProductDetail> {
  int quantity = 1;
  bool _isLoading = false;
  int _currentImageIndex = 0;
  bool isDarkMode = false;
  bool? _isLoggedIn; // Cache for login state
  bool _isCheckingLogin = false; // Flag to prevent duplicate checks

  // Add global key for comment section
  final GlobalKey _commentSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    isDarkMode = ThemeController.isDarkMode;
    ThemeController.addListener(_onThemeChanged);
    _checkLoginStatus();
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

  Future<void> _checkLoginStatus() async {
    // Return early if already checking or if login state is already set
    if (_isCheckingLogin) return;

    _isCheckingLogin = true;
    try {
      final isLoggedIn = await AuthHelpers.isLoggedIn();
      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _isCheckingLogin = false;
        });
      } else {
        _isCheckingLogin = false;
      }
    } catch (e) {
      _isCheckingLogin = false;
      // Handle any errors silently
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chi tiết sản phẩm',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildWishlistButton(),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.white.withOpacity(0.2),
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
      body: Stack(
        children: [
          // Background gradient
          Container(
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
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    height: MediaQuery.of(context).padding.top +
                        80), // Dynamic height based on status bar + app bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildImprovedImageCarousel(),
                ),

                // Product title and price outside any container
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    widget.product.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.fontBlack,
                      height: 1.3,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                // Price and quantity selectors in a row
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 16, 20, 0), // Increased from 12 to 16
                  child: Row(
                    children: [
                      // Price container
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${_formatCurrency(widget.product.price)} VNĐ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),

                      Spacer(),

                      // Quantity selector
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Số lượng:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[850]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (quantity > 1) quantity--;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: EdgeInsets.all(5),
                                      child: Icon(
                                        Icons.remove,
                                        size: 15,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 28,
                                  child: Center(
                                    child: Text(
                                      quantity.toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        quantity++;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: EdgeInsets.all(5),
                                      child: Icon(
                                        Icons.add,
                                        size: 15,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Conditionally show ratings only if product has reviews
                Consumer(
                  builder: (context, ref, child) {
                    final hasRatingsAsync =
                        ref.watch(hasRatingsProvider(widget.product.id));

                    return hasRatingsAsync.when(
                      data: (hasRatings) {
                        if (!hasRatings)
                          return SizedBox.shrink(); // Hide if no ratings

                        // Show rating card if product has ratings
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Consumer(
                            builder: (context, ref, child) {
                              final ratingAsync = ref.watch(
                                  productRatingProvider(widget.product.id));
                              final countAsync = ref.watch(
                                  ratingCountProvider(widget.product.id));

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 16),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primaryColor
                                        .withOpacity(0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: AppColors.primaryColor,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    ratingAsync.when(
                                      data: (rating) => Text(
                                        rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.white
                                              : AppColors.fontBlack,
                                        ),
                                      ),
                                      loading: () => const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      error: (_, __) => Text(
                                        '0.0',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.white
                                              : AppColors.fontBlack,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    RatingBar.builder(
                                      initialRating: ratingAsync.when(
                                        data: (rating) => rating,
                                        loading: () => 0.0,
                                        error: (_, __) => 0.0,
                                      ),
                                      minRating: 0,
                                      direction: Axis.horizontal,
                                      allowHalfRating: true,
                                      itemCount: 5,
                                      itemSize: 18,
                                      ignoreGestures: true,
                                      unratedColor: isDarkMode
                                          ? Colors.grey[700]
                                          : Colors.grey[300],
                                      itemBuilder: (context, _) => Icon(
                                        Icons.star,
                                        color: AppColors.primaryColor,
                                      ),
                                      onRatingUpdate: (_) {},
                                    ),
                                    const Spacer(),
                                    countAsync.when(
                                      data: (count) => Text(
                                        '($count đánh giá)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.greyFont,
                                        ),
                                      ),
                                      loading: () => Container(),
                                      error: (_, __) => Text(
                                        '(0 đánh giá)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.greyFont,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                      loading: () => SizedBox.shrink(), // Hide while loading
                      error: (_, __) => SizedBox.shrink(), // Hide on error
                    );
                  },
                ),

                // Connecting line
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 18), // Increased from 12 to 18
                    height: 24,
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryColor.withOpacity(0.15),
                          AppColors.primaryColor.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),

                // Description Card
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                  child: _buildDescription(),
                ),

                // Connecting element
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 20), // Increased from 12 to 20
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        width: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor
                              .withOpacity(0.5 + (index * 0.15)),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ),

                // Comment Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildCommentSection(),
                ),
                const SizedBox(height: 100), // Space for the fixed button
              ],
            ),
          ),

          // Bottom add to cart button with enhanced shadow
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.15),
                    offset: const Offset(0, 3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: _buildAddToCartButton(context),
            ),
          ),
        ],
      ),
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
    );
  }

  // Improved image carousel
  Widget _buildImprovedImageCarousel() {
    if (widget.product.photos.isEmpty) {
      return Center(
        child: Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withOpacity(0.12),
                offset: const Offset(0, 5),
                blurRadius: 15,
              ),
            ],
          ),
          child: Icon(
            Icons.image_not_supported,
            size: 60,
            color: AppColors.greyFont,
          ),
        ),
      );
    }

    // Process photos
    List<String> processedPhotos =
        widget.product.photos.map((url) => _getImageUrl(url)).toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 0,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: CarouselSlider(
            options: CarouselOptions(
              height: 240, // Reduced height
              viewportFraction: 1.0,
              enlargeCenterPage: true,
              autoPlay: false, // Disable autoplay to prevent unwanted refreshes
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              onPageChanged: (index, reason) {
                if (reason != CarouselPageChangedReason.controller) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                }
              },
            ),
            items: processedPhotos.map((photoUrl) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowColor.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: OptimizedImage(
                        imageUrl: photoUrl,
                        width: MediaQuery.of(context).size.width -
                            40, // Subtract padding
                        height: 240, // Reduced height
                        fit: BoxFit.cover,
                        isDarkMode: isDarkMode,
                        borderRadius: 20,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
        if (processedPhotos.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: DotsIndicator(
              dotsCount: processedPhotos.length,
              position: _currentImageIndex,
              decorator: DotsDecorator(
                size: const Size(8.0, 8.0),
                activeSize: const Size(20.0, 8.0),
                activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                activeColor: AppColors.primaryColor,
                spacing: EdgeInsets.symmetric(horizontal: 4.0),
              ),
            ),
          ),
      ],
    );
  }

  /// Thông tin sản phẩm - Được cải thiện
  Widget _buildProductInfo() {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(isDarkMode ? 0.2 : 0.1),
            blurRadius: 15,
            spreadRadius: 0,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin chi tiết',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.fontBlack,
            ),
          ),
          const SizedBox(height: 12),
          // Additional product details would go here
          // For now, just a placeholder
          Text(
            'Xem thêm thông tin chi tiết ở phần mô tả sản phẩm bên dưới',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.greyFont,
            ),
          ),
        ],
      ),
    );
  }

  /// Mô tả sản phẩm
  Widget _buildDescription() {
    // Kiểm tra xem có mô tả hay không
    if (widget.product.description.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Thông tin sản phẩm"),
          const SizedBox(height: 4), // Giảm từ 8 xuống 4
          Container(
            padding: const EdgeInsets.all(12), // Giảm từ 16 xuống 12
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF121212)
                  : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Text(
              "Không có mô tả cho sản phẩm này",
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: AppColors.greyFont,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Thông tin sản phẩm"),
        const SizedBox(height: 4), // Giảm từ 8 xuống 4
        Container(
          decoration: BoxDecoration(
            color:
                isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(12), // Giảm từ 16 xuống 12
          child: HtmlWidget(
            widget.product.description,
            customStylesBuilder: (element) {
              if (element.localName == 'p') {
                return {
                  'margin': '0 0 8px 0',
                  'text-align': 'justify',
                  'line-height': '1.3',
                };
              } else if (element.localName == 'table') {
                return {
                  'display': 'none',
                  'margin': '0',
                  'padding': '0',
                };
              } else if (element.localName == 'h1' ||
                  element.localName == 'h2' ||
                  element.localName == 'h3') {
                return {
                  'margin': '8px 0 4px 0',
                  'line-height': '1.2',
                };
              } else if (element.localName == 'div' ||
                  element.localName == 'section') {
                return {
                  'margin': '0 0 4px 0',
                  'padding': '0',
                };
              } else if (element.localName == 'ul' ||
                  element.localName == 'ol') {
                return {
                  'margin': '0 0 4px 16px',
                  'padding': '0',
                };
              } else if (element.localName == 'li') {
                return {
                  'margin': '0 0 2px 0',
                };
              } else if (element.localName == 'img') {
                return {
                  'max-width': '100%',
                  'height': 'auto',
                  'display': 'block',
                  'margin': '10px auto',
                };
              }
              return null;
            },
            customWidgetBuilder: (element) {
              if (element.localName == 'table') {
                final rows = element.querySelectorAll('tr');
                if (rows.isEmpty) return SizedBox.shrink();

                // More aggressive skipping of header rows and empty rows
                int startIndex = 0;

                // First check if the table has a header row that should be removed
                // Often the first row contains the table title or is empty
                if (rows.length > 0) {
                  final firstRow = rows[0];
                  final firstRowCells = firstRow.children;

                  // Skip the first row if it's empty or looks like a header
                  if (firstRowCells.isEmpty ||
                      (firstRowCells.length == 1 &&
                          (firstRowCells[0].text?.trim().isEmpty ?? true))) {
                    startIndex = 1;
                  }
                }

                // Continue checking a few more rows to skip headers or empty rows
                for (int i = startIndex;
                    i < Math.min(startIndex + 3, rows.length);
                    i++) {
                  final row = rows[i];
                  final cells = row.children;

                  // Check if this row is empty or contains only headers/section titles
                  if (cells.isEmpty || cells.length <= 1) {
                    final text =
                        cells.isEmpty ? '' : (cells[0].text?.trim() ?? '');

                    // Skip if empty or contains header-like text
                    if (text.isEmpty ||
                        text.contains('Thông tin sản phẩm') ||
                        text.contains('Thông số kỹ thuật') ||
                        text.contains('Thông số chính') ||
                        text.contains('Chi tiết') ||
                        text.contains('Lưu trữ')) {
                      startIndex = i + 1;
                    }
                  }
                }

                // Skip rendering if we have no valid rows after filtering
                if (startIndex >= rows.length) {
                  return SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 0), // Tăng từ 4 lên 8
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: EdgeInsets.zero, // Xóa padding mặc định
                      itemCount: rows.length - startIndex,
                      itemBuilder: (context, index) {
                        final actualIndex = index + startIndex;
                        final row = rows[actualIndex];
                        final cells = row.children;

                        // Skip empty rows or redundant headers
                        if (cells.isEmpty || cells.length == 1) {
                          final cellText = cells.isEmpty
                              ? ''
                              : (cells[0].text?.trim() ?? '');
                          if (cellText.isEmpty ||
                              cellText.contains('Thông tin sản phẩm') ||
                              cellText.contains('Thông số kỹ thuật') ||
                              cellText.contains('Thông số chính') ||
                              cellText.contains('Chi tiết') ||
                              cellText.contains('Lưu trữ')) {
                            return SizedBox.shrink();
                          }
                        }

                        // Hàng tiêu đề đầy đủ
                        if (cells.length == 1) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal:
                                    12), // Tăng lại padding từ 6/8 lên 10/12
                            margin: const EdgeInsets.only(
                                bottom: 6), // Tăng lại margin bottom từ 2 lên 6
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border(
                                top: BorderSide(
                                  width: index == 0 ? 1 : 0,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                left: BorderSide(
                                  width: 1,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                right: BorderSide(
                                  width: 1,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                bottom: BorderSide(
                                  width: 1,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            child: Text(
                              cells[0].text ?? '',
                              style: TextStyle(
                                fontSize: 14, // Tăng lại font từ 13 lên 14
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          );
                        }

                        // Hàng thông thường với 2 cột
                        if (cells.length >= 2) {
                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: 1), // Thêm margin bottom
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border(
                                top: BorderSide(
                                  width: index == 0 ? 1 : 0,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                left: BorderSide(
                                  width: 1,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                right: BorderSide(
                                  width: 1,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                bottom: BorderSide(
                                  width: 0.7, // Tăng lại từ 0.5 lên 0.7
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Cột tiêu đề (bên trái)
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        0.35,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal:
                                            12), // Tăng lại từ 6/8 lên 10/12
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.grey[900]!.withOpacity(0.3)
                                          : Colors.grey[100]!.withOpacity(0.5),
                                      border: Border(
                                        right: BorderSide(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      cells[0].text ?? '',
                                      style: TextStyle(
                                        fontSize:
                                            14, // Tăng lại font từ 13 lên 14
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  // Cột nội dung (bên phải)
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal:
                                              12), // Tăng lại từ 6/8 lên 10/12
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        cells[1].text ?? '',
                                        style: TextStyle(
                                          fontSize:
                                              14, // Tăng lại font từ 13 lên 14
                                          height:
                                              1.4, // Tăng lại từ 1.2 lên 1.4
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                );
              }
              return null;
            },
            textStyle: TextStyle(
              fontSize: 14, // Giảm từ 15 xuống 14
              color: isDarkMode
                  ? Colors.white.withOpacity(0.95)
                  : AppColors.fontBlack,
              height: 1.3, // Giảm từ 1.5 xuống 1.3
              letterSpacing: 0, // Xóa letter spacing
            ),
            onTapImage: (metadata) {
              // Get the image URL
              final String imageUrl = metadata.sources.first.url;

              // Process the URL through our utility function to ensure it works in all environments
              final String processedUrl = _getImageUrl(imageUrl);

              // Show the fullscreen image viewer
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  insetPadding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  child: Stack(
                    children: [
                      // Interactive image viewer
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.black.withOpacity(0.9),
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 3.0,
                            child: Center(
                              child: OptimizedImage(
                                imageUrl: processedUrl,
                                fit: BoxFit.contain,
                                isDarkMode: true, // Always dark for overlay
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Close button for better UX
                      Positioned(
                        top: 40,
                        right: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            renderMode: RenderMode.column,
          ),
        ),
      ],
    );
  }

  // Section title helper
  Widget _buildSectionTitle(String title) {
    return Container(
      margin: EdgeInsets.only(
          bottom: 4, left: 4, top: 4), // Giảm margin từ 10/8 xuống 4
      child: Row(
        children: [
          Container(
            height: 18,
            width: 4,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 8), // Giảm từ 10 xuống 8
          Text(
            title,
            style: TextStyle(
              fontSize: 16, // Giảm từ 18 xuống 16
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.fontBlack,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the comment section
  Widget _buildCommentSection() {
    // Check login status if not yet determined
    if (_isLoggedIn == null && !_isCheckingLogin) {
      // Only check if not currently checking
      _checkLoginStatus();
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
      );
    }

    // If still checking login status, show loading
    if (_isLoggedIn == null) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
      );
    }

    // If not logged in, show login message with optional rating distribution
    if (!_isLoggedIn!) {
      return Consumer(
        builder: (context, ref, child) {
          final hasRatingsAsync =
              ref.watch(hasRatingsProvider(widget.product.id));

          return hasRatingsAsync.when(
            data: (hasRatings) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Conditionally show rating distribution only if there are ratings
                  if (hasRatings) _buildRatingDistribution(),

                  if (hasRatings) SizedBox(height: 16),

                  // Login message container
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowColor
                              .withOpacity(isDarkMode ? 0.2 : 0.1),
                          blurRadius: 15,
                          spreadRadius: 0,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          color: AppColors.primaryColor.withOpacity(0.6),
                          size: 40,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Vui lòng đăng nhập để đánh giá sản phẩm này',
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: AppColors.greyFont,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            elevation: 2,
                          ),
                          child: Text('Đăng nhập để đánh giá'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            ),
            error: (_, __) => Container(
              padding: EdgeInsets.all(20),
              child: Text(
                'Không thể tải thông tin đánh giá',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        },
      );
    }

    // If logged in, get userId and show comment section with optional rating distribution
    return Consumer(
      builder: (context, ref, child) {
        final hasRatingsAsync =
            ref.watch(hasRatingsProvider(widget.product.id));

        return hasRatingsAsync.when(
          data: (hasRatings) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Conditionally show rating distribution only if there are ratings
                if (hasRatings) _buildRatingDistribution(),

                if (hasRatings) SizedBox(height: 16),

                // Comment section
                FutureBuilder<SharedPreferences>(
                  future: SharedPreferences.getInstance(),
                  builder: (context, prefsSnapshot) {
                    if (prefsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      );
                    }

                    if (!prefsSnapshot.hasData) {
                      return Center(
                        child: Text(
                          'Không thể tải thông tin người dùng',
                          style: TextStyle(color: AppColors.fontBlack),
                        ),
                      );
                    }

                    final prefs = prefsSnapshot.data!;
                    final userId = prefs.getInt('userId') ?? 0;

                    // Show the comment section component with Focus protection
                    return FocusScope(
                      canRequestFocus: true,
                      child: CommentSection(
                        key: _commentSectionKey,
                        productId: widget.product.id,
                        userId: userId,
                      ),
                    );
                  },
                ),
              ],
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          ),
          error: (_, __) => FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, prefsSnapshot) {
              if (!prefsSnapshot.hasData) {
                return Center(
                  child: Text(
                    'Không thể tải thông tin người dùng',
                    style: TextStyle(color: AppColors.fontBlack),
                  ),
                );
              }

              final prefs = prefsSnapshot.data!;
              final userId = prefs.getInt('userId') ?? 0;

              // Show only comment section on error with rating data
              return FocusScope(
                canRequestFocus: true,
                child: CommentSection(
                  key: _commentSectionKey,
                  productId: widget.product.id,
                  userId: userId,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Build a visual chart showing rating distribution
  Widget _buildRatingDistribution() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(isDarkMode ? 0.2 : 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Consumer(
        builder: (context, ref, child) {
          final commentsAsync =
              ref.watch(commentsStateProvider(widget.product.id));

          return commentsAsync.when(
            data: (commentsData) {
              // Only show if there are ratings
              if (commentsData.totalComments == 0) {
                return SizedBox.shrink();
              }

              // Calculate percentages for each rating level
              final totalComments = commentsData.totalComments;

              // Count occurrences of each rating
              final Map<int, int> ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
              for (var comment in commentsData.comments) {
                if (comment.rating >= 1 && comment.rating <= 5) {
                  ratingCounts[comment.rating] =
                      (ratingCounts[comment.rating] ?? 0) + 1;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phân bổ đánh giá',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.fontBlack,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Generate 5 rating bars (5 stars to 1 star)
                  ...List.generate(5, (index) {
                    final ratingValue = 5 - index;
                    final count = ratingCounts[ratingValue] ?? 0;
                    final percent =
                        totalComments > 0 ? (count / totalComments) * 100 : 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // Star rating label
                          Row(
                            children: [
                              Text(
                                '$ratingValue',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.star,
                                size: 16,
                                color: AppColors.primaryColor,
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),

                          // Progress bar
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Stack(
                                children: [
                                  // Background
                                  Container(
                                    height: 8,
                                    color: isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                  ),
                                  // Foreground
                                  FractionallySizedBox(
                                    widthFactor: percent / 100,
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primaryColor,
                                            ratingValue >= 4
                                                ? AppColors.primaryColor
                                                : ratingValue >= 3
                                                    ? AppColors.primaryColor
                                                        .withOpacity(0.8)
                                                    : ratingValue >= 2
                                                        ? AppColors.primaryColor
                                                            .withOpacity(0.6)
                                                        : AppColors.primaryColor
                                                            .withOpacity(0.4),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Count and percentage
                          Container(
                            width: 70,
                            padding: EdgeInsets.only(left: 8),
                            child: Text(
                              '$count (${percent.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[700],
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            ),
            error: (_, __) => Center(
              child: Text(
                'Không thể tải thông tin đánh giá',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Nút Add to Cart
  Widget _buildAddToCartButton(BuildContext context) {
    return AuthRequiredButton(
      featureDescription: 'thêm sản phẩm vào giỏ hàng',
      onAuthenticated: () async {
        setState(() {
          _isLoading = true;
        });

        try {
          // Lấy token
          final token = await AuthHelpers.getValidToken();
          if (token == null) {
            setState(() {
              _isLoading = false;
            });
            return;
          }

          // Lấy CartProvider từ Riverpod
          final cartProviderNotifier = ref.read(cartProvider);

          // Thêm sản phẩm vào giỏ hàng
          await cartProviderNotifier.addToCart(
              token, widget.product.id, quantity);

          // Hiển thị thông báo thành công
          NotificationDialog.showSuccess(
            context: context,
            title: 'Thành công',
            message: 'Sản phẩm đã được thêm vào giỏ hàng!',
            autoDismiss: true,
            autoDismissDuration: const Duration(seconds: 1),
          );
        } catch (e) {
          print("Error adding to cart: $e");
          // Hiển thị thông báo lỗi
          NotificationDialog.showError(
            context: context,
            title: 'Lỗi',
            message:
                'Không thể thêm sản phẩm vào giỏ hàng. Vui lòng thử lại sau.',
            primaryButtonText: 'Đóng',
            primaryAction: () {
              // Không làm gì, dialog tự đóng
            },
          );
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 0, // Removed because we added our own shadow
      ),
      child: _isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart, size: 20),
                SizedBox(width: 10),
                Text(
                  'Thêm vào giỏ hàng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
    );
  }

  /// Nút yêu thích
  Widget _buildWishlistButton() {
    return Consumer(
      builder: (context, ref, _) {
        final isInWishlistAsync =
            ref.watch(isProductInWishlistProvider(widget.product.id));

        return Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: isInWishlistAsync.when(
            data: (isInWishlist) {
              return AuthRequiredIconButton(
                icon: isInWishlist ? Icons.favorite : Icons.favorite_border,
                color: isInWishlist ? Colors.red : AppColors.fontLight,
                featureDescription: 'thêm vào danh sách yêu thích',
                onAuthenticated: () async {
                  // Thực hiện toggle wishlist
                  try {
                    final token = await AuthHelpers.getValidToken();
                    if (token == null) return;

                    bool success = await ref
                        .read(wishlistProductIdsProvider.notifier)
                        .toggleWishlist(widget.product.id);

                    if (success && context.mounted) {
                      if (isInWishlist) {
                        // Hiển thị thông báo khi xóa khỏi yêu thích
                        NotificationDialog.showSuccess(
                          context: context,
                          title: 'Đã xóa khỏi yêu thích',
                          message: 'Đã xóa sản phẩm khỏi danh sách yêu thích',
                          autoDismiss: true,
                          autoDismissDuration: const Duration(seconds: 1),
                        );
                      } else {
                        // Hiển thị thông báo khi thêm vào yêu thích
                        NotificationDialog.showSuccess(
                          context: context,
                          title: 'Thành công',
                          message: 'Đã thêm vào danh sách yêu thích',
                          autoDismiss: true,
                          autoDismissDuration: const Duration(seconds: 1),
                        );
                      }
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Không thể cập nhật danh sách yêu thích'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Lỗi xử lý yêu thích: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi xử lý yêu thích: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              );
            },
            loading: () => IconButton(
              icon: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.fontLight),
                strokeWidth: 2,
              ),
              onPressed: null,
            ),
            error: (_, __) => IconButton(
              icon: Icon(
                Icons.favorite_border,
                color: AppColors.fontLight,
              ),
              onPressed: null,
            ),
          ),
        );
      },
    );
  }

  /// Định dạng tiền tệ Việt Nam
  String _formatCurrency(double amount) {
    return formatCurrency(amount);
  }

  /// Thay đổi URL để hoạt động trên giả lập Android
  String _getImageUrl(String url) {
    return getImageUrl(url);
  }
}

// Create a separate stateful widget for the image carousel
class ProductImageCarousel extends StatefulWidget {
  final List<String> photos;
  final bool isDarkMode;
  final String Function(String) getImageUrl;

  const ProductImageCarousel({
    Key? key,
    required this.photos,
    required this.isDarkMode,
    required this.getImageUrl,
  }) : super(key: key);

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return Center(
        child: Icon(
          Icons.image_not_supported,
          size: 100,
          color: AppColors.greyFont,
        ),
      );
    }

    // Process photos
    List<String> processedPhotos =
        widget.photos.map((url) => widget.getImageUrl(url)).toList();

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 250,
            viewportFraction: 0.95,
            enlargeCenterPage: true,
            autoPlay: processedPhotos.length > 1,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
          items: processedPhotos.map((photoUrl) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: OptimizedImage(
                      imageUrl: photoUrl,
                      width: MediaQuery.of(context).size.width,
                      height: 250,
                      fit: BoxFit.cover,
                      isDarkMode: widget.isDarkMode,
                      borderRadius: 10,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        if (processedPhotos.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: DotsIndicator(
              dotsCount: processedPhotos.length,
              position: _currentImageIndex,
              decorator: DotsDecorator(
                size: const Size(8.0, 8.0),
                activeSize: const Size(24.0, 8.0),
                activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                color: AppColors.greyFont.withOpacity(0.5),
                activeColor: AppColors.appBarColor,
              ),
            ),
          ),
      ],
    );
  }
}

// Factory tùy chỉnh để xử lý tốt hơn các bảng HTML
class _FixedTableHtmlWidgetFactory extends WidgetFactory {
  @override
  bool get enableCaching => true;

  @override
  void reset(State state) {
    // Reset state để tránh lỗi cached widgets
    super.reset(state);
  }
}
