import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/models/blog.dart';
import 'package:shoplite/providers/blog_provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/foundation.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';

// Import the provider from main.dart
import 'package:shoplite/main.dart';

class BlogDetailScreen extends ConsumerStatefulWidget {
  final String slug;

  const BlogDetailScreen({Key? key, required this.slug}) : super(key: key);

  @override
  ConsumerState<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends ConsumerState<BlogDetailScreen> {
  // List to store image URLs from HTML content
  List<String> _extractedImages = [];

  @override
  void initState() {
    super.initState();
    // Load blog detail when the screen initializes with a 15-second timeout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBlogDetail();
    });
  }

  @override
  void dispose() {
    // We shouldn't use ref.read() in dispose() as it can cause
    // "Cannot use ref after the widget was disposed" errors
    // If state needs cleanup, consider using a different approach
    super.dispose();
  }

  // Separate method for loading blog detail with timeout
  void _loadBlogDetail() {
    ref.read(blogProvider).fetchBlogDetail(widget.slug);

    // Add timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && ref.read(blogProvider).isLoadingDetail) {
        // If still loading after 15 seconds, manually retry once
        ref.read(blogProvider).fetchBlogDetail(widget.slug);

        // Add one more timeout as final fallback
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && ref.read(blogProvider).isLoadingDetail) {
            // Force a UI refresh to show error state
            setState(() {});
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final blogProviderState = ref.watch(blogProvider);
    final blog = blogProviderState.currentBlog;
    final isDarkMode = ThemeController.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          blog != null ? blog.title : 'Chi tiết bài viết',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const ChatIconBadge(size: 26),
          ),
        ],
        flexibleSpace: Container(
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
          ),
        ),
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      extendBodyBehindAppBar: false,
      body: SafeArea(
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
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _buildBody(blogProviderState),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BlogProvider blogProvider) {
    // Show loading indicator
    if (blogProvider.isLoadingDetail) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Đang tải bài viết...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Show error message
    if (blogProvider.hasDetailError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Không thể tải bài viết',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _formatErrorMessage(blogProvider.detailErrorMessage),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _loadBlogDetail(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If blog is loaded, show blog detail
    if (blogProvider.currentBlog != null) {
      final blog = blogProvider.currentBlog!;
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blog header image with gradient overlay for title
            if (blog.photo.isNotEmpty)
              Stack(
                children: [
                  // Image with fixed size and error handling
                  SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: blog.photo,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported_rounded,
                            size: 50),
                      ),
                    ),
                  ),
                  // Gradient overlay for title
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        blog.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  blog.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

            // Blog info card (category, date, views)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Category
                  if (blog.categoryName != null)
                    Column(
                      children: [
                        Icon(
                          Icons.category_rounded,
                          color: AppColors.primaryColor,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          blog.categoryName!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                  // Date
                  Column(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.primaryColor,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${blog.createdAt.day}/${blog.createdAt.month}/${blog.createdAt.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Views
                  Column(
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        color: AppColors.primaryColor,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${blog.hit} views',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Blog content (HTML)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _renderContentWithImages(blog.content),
            ),

            // Tags section with modern UI
            if (blogProvider.blogTags.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: blogProvider.blogTags
                      .map(
                        (tag) => Chip(
                          label: Text(tag.name),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],

            // Related blogs section with improved UI
            if (blogProvider.relatedBlogs.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Row(
                  children: [
                    const Text(
                      'Related Articles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 2,
                      color: AppColors.primaryColor,
                      width: 40,
                    ),
                  ],
                ),
              ),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: blogProvider.relatedBlogs.length,
                itemBuilder: (context, index) {
                  final relatedBlog = blogProvider.relatedBlogs[index];
                  return RelatedBlogCard(
                    blog: relatedBlog,
                    onTap: () {
                      // Navigate to related blog - use push instead of pushReplacement to avoid disposal issues
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlogDetailScreen(
                            slug: relatedBlog.slug,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      );
    }

    // Default empty state
    return const Center(
      child: Text('No blog details available'),
    );
  }

  // Helper method to format error messages for better display
  String _formatErrorMessage(String error) {
    // Check if it's a JSON parsing error
    if (error.contains('FormatException') ||
        error.contains('Unexpected end of input')) {
      return 'Có lỗi với định dạng dữ liệu. Vui lòng thử lại sau.';
    }

    // Check if it's a network error
    if (error.contains('SocketException') ||
        error.contains('Connection refused')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.';
    }

    // Timeout error
    if (error.contains('timeout') || error.contains('timed out')) {
      return 'Quá thời gian kết nối. Vui lòng thử lại sau.';
    }

    // Default error message or simplified message
    if (error.length > 100) {
      return 'Đã xảy ra lỗi. Vui lòng thử lại sau.';
    }

    return error;
  }

  Widget _buildImageCard(String imageUrl) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () => _showFullScreenImage(context, imageUrl),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity, // Take full width
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center, // Center all content
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              // Remove fixed height for more flexibility
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                placeholder: (context, url) => Container(
                  height: 150, // Placeholder height
                  width: MediaQuery.of(context).size.width *
                      0.7, // Use percentage of screen width
                  color: Colors.grey.shade100,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 150,
                  width: MediaQuery.of(context).size.width * 0.7,
                  color: Colors.grey.shade100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image_rounded,
                          size: 42, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'Không thể tải hình ảnh',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Method to show a full-screen image viewer
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  List<String> _extractImagesFromHtml(String html) {
    final imgRegex =
        RegExp(r'<img[^>]+src="([^"]+)"[^>]*>', caseSensitive: false);
    final matches = imgRegex.allMatches(html);
    final images = <String>[];
    for (final match in matches) {
      final imgSrc = match.group(1) ?? '';
      if (imgSrc.isNotEmpty) {
        images.add(imgSrc);
      }
    }
    return images;
  }

  Widget _renderContentWithImages(String html) {
    // First, we'll split the HTML content by image tags
    final List<Widget> contentWidgets = [];
    final RegExp imgRegex =
        RegExp(r'<img[^>]+src="([^"]+)"[^>]*>', caseSensitive: false);

    // Split the HTML content by image tags
    final List<String> textParts = html.split(imgRegex);
    final List<RegExpMatch> imgMatches = imgRegex.allMatches(html).toList();

    // Add text and image parts in order
    for (int i = 0; i < textParts.length; i++) {
      // Add text part (even if empty)
      if (textParts[i].trim().isNotEmpty) {
        contentWidgets.add(
          Html(
            data: textParts[i],
            style: {
              "p": Style(
                fontSize: FontSize(16),
                lineHeight: LineHeight.number(1.5),
              ),
              "h1,h2,h3,h4,h5,h6": Style(
                fontWeight: FontWeight.bold,
              ),
            },
          ),
        );
      }

      // Add image if available for this position
      if (i < imgMatches.length) {
        final imgSrc = imgMatches[i].group(1);
        if (imgSrc != null && imgSrc.isNotEmpty) {
          contentWidgets.add(_buildImageCard(imgSrc));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentWidgets,
    );
  }
}

class RelatedBlogCard extends StatelessWidget {
  final Blog blog;
  final VoidCallback onTap;

  const RelatedBlogCard({
    Key? key,
    required this.blog,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Blog thumbnail with fixed size and error handling
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: blog.photo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: blog.photo,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child:
                                const Icon(Icons.image_not_supported_rounded),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.article_rounded),
                        ),
                ),
              ),

              const SizedBox(width: 16),

              // Blog info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      blog.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${blog.createdAt.day}/${blog.createdAt.month}/${blog.createdAt.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Separate stateful widget for full-screen image viewing
class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;

  const FullScreenImageViewer({Key? key, required this.imageUrl})
      : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text('Xem ảnh', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.white),
            onPressed: () {
              // Could implement zooming if needed
            },
            tooltip: 'Phóng to',
          ),
        ],
      ),
      body: Center(
        child: PhotoView(
          imageProvider: CachedNetworkImageProvider(widget.imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2.5,
          initialScale: PhotoViewComputedScale.contained,
          loadingBuilder: (context, event) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                value: event?.expectedTotalBytes != null &&
                        event!.expectedTotalBytes! > 0
                    ? event.cumulativeBytesLoaded / event.expectedTotalBytes!
                    : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Đang tải hình ảnh...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          errorBuilder: (context, error, stackTrace) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 40),
              const SizedBox(height: 16),
              const Text(
                'Không thể tải hình ảnh',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text('Quay lại'),
              ),
            ],
          ),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          tightMode: true,
          gestureDetectorBehavior: HitTestBehavior.translucent,
        ),
      ),
    );
  }
}
