import 'package:flutter/material.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/models/product.dart';
import 'package:shoplite/widgets/optimized_image.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final bool isDarkMode;
  final Function(Product) onTap;
  final String Function(String) getImageUrl;
  final String Function(double) formatPrice;

  const ProductCard({
    Key? key,
    required this.product,
    required this.isDarkMode,
    required this.onTap,
    required this.getImageUrl,
    required this.formatPrice,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Use a precalculated image URL to avoid repeated processing
  String? _processedImageUrl;

  @override
  void initState() {
    super.initState();

    // Pre-process image URL
    if (widget.product.photos.isNotEmpty) {
      _processedImageUrl = widget.getImageUrl(widget.product.photos.first);
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onTap(widget.product),
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 180,
          margin: EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color:
                widget.isDarkMode ? AppColors.cardColor : AppColors.fontLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with Sale badge and New tag
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: _processedImageUrl != null &&
                            _processedImageUrl!.isNotEmpty
                        ? OptimizedImage(
                            imageUrl: _processedImageUrl!,
                            width: double.infinity,
                            height: 140,
                            fit: BoxFit.cover,
                            isDarkMode: widget.isDarkMode,
                            borderRadius: 0,
                          )
                        : Container(
                            height: 140,
                            width: double.infinity,
                            color: widget.isDarkMode
                                ? AppColors.cardColor
                                : AppColors.primaryColor.withOpacity(0.05),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(
                                    widget.product.title,
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

                  // Sale badge
                  if (widget.product.price < 3000000)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryDarkColor,
                              AppColors.primaryColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.4),
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

                  // New tag
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryDarkColor,
                            AppColors.primaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        "MỚI",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Product Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.product.title,
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

                      // Stock info
                      Container(
                        constraints: const BoxConstraints(maxWidth: 85),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode
                              ? AppColors.primaryColor.withOpacity(0.15)
                              : AppColors.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 9,
                              color: widget.product.stock > 5
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                'Còn ${widget.product.stock}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: widget.product.stock > 5
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

                      // Price
                      Text(
                        widget.formatPrice(widget.product.price),
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

                      // View Detail Button
                      SizedBox(
                        width: double.infinity,
                        height: 26,
                        child: ElevatedButton(
                          onPressed: () => widget.onTap(widget.product),
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
      ),
    );
  }
}

class HorizontalProductList extends StatelessWidget {
  final List<Product> products;
  final bool isDarkMode;
  final Function(Product) onProductTap;
  final String Function(String) getImageUrl;
  final String Function(double) formatPrice;

  const HorizontalProductList({
    Key? key,
    required this.products,
    required this.isDarkMode,
    required this.onProductTap,
    required this.getImageUrl,
    required this.formatPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Adjust the height dynamically based on text scale factor
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final dynamicHeight =
        280.0 + (textScaleFactor > 1.0 ? (textScaleFactor - 1.0) * 50.0 : 0.0);

    if (products.isEmpty) {
      return SizedBox(
        height: dynamicHeight,
        child: Center(
          child: Text(
            'Không có sản phẩm nào',
            style: TextStyle(color: AppColors.fontBlack),
          ),
        ),
      );
    }

    return SizedBox(
      height: dynamicHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length > 5 ? 5 : products.length,
        itemBuilder: (context, index) {
          return ProductCard(
            product: products[index],
            isDarkMode: isDarkMode,
            onTap: onProductTap,
            getImageUrl: getImageUrl,
            formatPrice: formatPrice,
          );
        },
      ),
    );
  }
}
