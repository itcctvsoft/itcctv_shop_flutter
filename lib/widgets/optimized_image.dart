import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/constants/utils.dart';

class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isDarkMode;
  final double borderRadius;

  const OptimizedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    required this.isDarkMode,
    this.borderRadius = 0,
  }) : super(key: key);

  // Kiểm tra URL hợp lệ
  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    // Kiểm tra cơ bản URL có hợp lệ không
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute;
    } catch (e) {
      print('URL không hợp lệ: $url - Lỗi: $e');
      return false;
    }
  }

  // Xử lý URL trước khi tải
  String _processUrl(String url) {
    if (!_isValidUrl(url)) return '';

    // Xử lý URL cho máy ảo Android
    if (url.contains('127.0.0.1') || url.contains('localhost')) {
      return url
          .replaceAll('127.0.0.1', '10.0.2.2')
          .replaceAll('localhost', '10.0.2.2');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Kiểm tra nếu imageUrl rỗng hoặc không hợp lệ, hiển thị placeholder
      if (imageUrl.isEmpty || !_isValidUrl(imageUrl)) {
        return _buildPlaceholder();
      }

      // Xử lý URL
      final processedUrl = _processUrl(imageUrl);
      if (processedUrl.isEmpty) {
        return _buildPlaceholder();
      }

      // Đảm bảo không có giá trị vô hạn hoặc NaN trong các tham số kích thước
      final safeWidth = (width != null && width!.isFinite) ? width : null;
      final safeHeight = (height != null && height!.isFinite) ? height : null;
      final safeBorderRadius = borderRadius.isFinite ? borderRadius : 0.0;

      // Tự động tính toán memCacheWidth và memCacheHeight
      int? memCacheW;
      int? memCacheH;

      // Calculate appropriate memory cache size based on device pixel ratio
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

      if (safeWidth != null &&
          safeWidth.isFinite &&
          safeWidth != double.infinity) {
        memCacheW = (safeWidth * devicePixelRatio).round();
      }

      if (safeHeight != null &&
          safeHeight.isFinite &&
          safeHeight != double.infinity) {
        memCacheH = (safeHeight * devicePixelRatio).round();
      }

      return CachedNetworkImage(
        imageUrl: processedUrl,
        width: safeWidth == double.infinity ? null : safeWidth,
        height: safeHeight == double.infinity ? null : safeHeight,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 150),
        fadeOutDuration: const Duration(milliseconds: 150),
        memCacheWidth: memCacheW,
        memCacheHeight: memCacheH,
        maxWidthDiskCache: memCacheW,
        maxHeightDiskCache: memCacheH,
        cacheKey: Uri.encodeFull(processedUrl),
        // Add HTTP headers for better caching
        httpHeaders: const {
          'Accept': 'image/jpeg,image/png,image/jpg,image/*',
          'Cache-Control': 'max-age=86400',
        },
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(safeBorderRadius),
            image: DecorationImage(
              image: imageProvider,
              fit: fit,
            ),
          ),
        ),
        placeholder: (context, url) =>
            _buildLoadingPlaceholder(safeBorderRadius),
        errorWidget: (context, url, error) {
          print('Lỗi tải ảnh từ $url: $error');
          return _buildErrorWidget(safeBorderRadius);
        },
      );
    } catch (e) {
      print('Lỗi không xác định trong OptimizedImage: $e');
      return _buildErrorWidget(0);
    }
  }

  // Widget placeholder khi chưa tải xong hoặc lỗi
  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: AppColors.greyFont,
          size: 24,
        ),
      ),
    );
  }

  // Widget hiển thị khi đang tải
  Widget _buildLoadingPlaceholder(double radius) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  // Widget hiển thị khi lỗi
  Widget _buildErrorWidget(double radius) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: AppColors.greyFont,
          size: 24,
        ),
      ),
    );
  }
}

// Widget phụ dành cho hình ảnh sản phẩm có nhãn giá
class ProductImageWithTag extends StatelessWidget {
  final String imageUrl;
  final String? tagText;
  final double width;
  final double height;
  final double borderRadius;
  final bool isDarkMode;

  const ProductImageWithTag({
    Key? key,
    required this.imageUrl,
    this.tagText,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadius),
          ),
          child: OptimizedImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            isDarkMode: isDarkMode,
          ),
        ),
        if (tagText != null)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                tagText!,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
