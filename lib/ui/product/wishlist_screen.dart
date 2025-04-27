import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shoplite/models/product.dart';
import 'package:shoplite/providers/product_provider.dart';
import 'package:shoplite/providers/wishlist_provider.dart';
import 'package:shoplite/ui/product/product_detail.dart';
import 'package:shoplite/ui/search/filter_screen.dart';
import 'package:shoplite/constants/apilist.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  bool _isLoading = false;
  List<Product> _favouriteProducts = [];

  @override
  void initState() {
    super.initState();
    // Đảm bảo danh sách yêu thích được tải khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWishlistProducts();
    });
  }

  // Tải danh sách sản phẩm yêu thích
  Future<void> _loadWishlistProducts() async {
    if (g_token.isEmpty) {
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
      print('WishlistScreen: Bắt đầu tải sản phẩm yêu thích');
      // Lấy repository
      final productRepository = ref.read(productRepositoryProvider);

      // Tải danh sách sản phẩm yêu thích trực tiếp từ API
      final products = await productRepository.getWishlistProducts();

      print('WishlistScreen: Đã tải ${products.length} sản phẩm yêu thích');

      // Kiểm tra dữ liệu ảnh
      for (var product in products) {
        if (product.photos.isNotEmpty) {
          print(
              'WishlistScreen: Ảnh sản phẩm ${product.id}: ${product.photos.first}');
        } else {
          print('WishlistScreen: Sản phẩm ${product.id} không có ảnh');
        }
      }

      if (mounted) {
        setState(() {
          _favouriteProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('WishlistScreen: Lỗi khi tải danh sách yêu thích: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Hiển thị thông báo Snackbar
  void _showSnackbar(String message, bool isSuccess) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 150,
        left: 10,
        right: 10,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF007B66),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sản phẩm yêu thích',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadWishlistProducts,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingShimmer()
          : _favouriteProducts.isEmpty
              ? _buildEmptyWishlist()
              : _buildWishlistGrid(),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.6,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 160,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
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
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 10,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 15,
                          color: Colors.white,
                        ),
                        const Spacer(),
                        Container(
                          width: 40,
                          height: 15,
                          color: Colors.white,
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
    );
  }

  Widget _buildEmptyWishlist() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F3),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 80,
              color: Color(0xFF007B66),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            "Danh sách yêu thích trống",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Hãy thêm sản phẩm yêu thích để xem và mua sau",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
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
                  builder: (context) => const FilterScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007B66),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 3,
            ),
            child: const Text(
              "Khám phá sản phẩm",
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

  Widget _buildWishlistGrid() {
    return RefreshIndicator(
      onRefresh: _loadWishlistProducts,
      color: const Color(0xFF007B66),
      child: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.6,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: _favouriteProducts.length,
        itemBuilder: (context, index) {
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ảnh sản phẩm và nút yêu thích
                  Stack(
                    children: [
                      Hero(
                        tag: 'product_image_${product.id}',
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                          child: product.photos.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: product.photos.first,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    height: 160,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Color(0xFF007B66)),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
                                    print(
                                        'WishlistScreen: Lỗi tải ảnh $url: $error');
                                    return Container(
                                      height: 160,
                                      color: const Color(0xFFE8F5F3),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.image_not_supported,
                                            color: Color(0xFF007B66),
                                            size: 36,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            product.title,
                                            style: const TextStyle(
                                              color: Color(0xFF007B66),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  height: 160,
                                  color: const Color(0xFFE8F5F3),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.image,
                                        color: Color(0xFF007B66),
                                        size: 36,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        product.title,
                                        style: const TextStyle(
                                          color: Color(0xFF007B66),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
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
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                            child: const Text(
                              "SALE",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
                                _showSnackbar(
                                    "Đã xóa sản phẩm khỏi danh sách yêu thích",
                                    true);
                                _loadWishlistProducts();
                              }
                            });
                          },
                          child: Material(
                            elevation: 4,
                            shape: const CircleBorder(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Chi tiết sản phẩm
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tên sản phẩm
                          Text(
                            product.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Giá và tồn kho
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${_formatNumber(product.price)} đ',
                                    style: const TextStyle(
                                      color: Color(0xFF007B66),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5F3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Còn 10',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF6E7897),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Nút Xem chi tiết
                              SizedBox(
                                width: double.infinity,
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
                                    backgroundColor: const Color(0xFF007B66),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Xem chi tiết',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
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
    );
  }

  // Format số với dấu phân cách hàng nghìn
  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
