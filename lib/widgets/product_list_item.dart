import 'package:flutter/material.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/models/product.dart';
import 'package:shoplite/widgets/optimized_image.dart';

class ProductListItem extends StatelessWidget {
  final Product product;
  final bool isDarkMode;
  final Function(Product) onTap;
  final String Function(String) getImageUrl;
  final String Function(double) formatPrice;
  final bool showDescription;

  const ProductListItem({
    Key? key,
    required this.product,
    required this.isDarkMode,
    required this.onTap,
    required this.getImageUrl,
    required this.formatPrice,
    this.showDescription = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(product),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.cardColor : AppColors.fontLight,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(15),
              ),
              child: OptimizedImage(
                imageUrl: product.photos.isNotEmpty
                    ? getImageUrl(product.photos.first)
                    : '',
                width: 100,
                height: 100,
                isDarkMode: isDarkMode,
              ),
            ),

            // Product Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.fontBlack,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showDescription) ...[
                      SizedBox(height: 5),
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.greyFont,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatPrice(product.price),
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Còn ${product.stock}",
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
}

class VerticalProductList extends StatelessWidget {
  final List<Product> products;
  final bool isDarkMode;
  final Function(Product) onProductTap;
  final String Function(String) getImageUrl;
  final String Function(double) formatPrice;
  final bool showDescription;

  const VerticalProductList({
    Key? key,
    required this.products,
    required this.isDarkMode,
    required this.onProductTap,
    required this.getImageUrl,
    required this.formatPrice,
    this.showDescription = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Text(
          'Không có sản phẩm nào',
          style: TextStyle(color: AppColors.fontBlack),
        ),
      );
    }

    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: products.length > 4 ? 4 : products.length,
      itemBuilder: (context, index) {
        return ProductListItem(
          product: products[index],
          isDarkMode: isDarkMode,
          onTap: onProductTap,
          getImageUrl: getImageUrl,
          formatPrice: formatPrice,
          showDescription: showDescription,
        );
      },
    );
  }
}
