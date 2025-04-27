import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/providers/blog_provider.dart';
import 'package:shoplite/ui/blog/blog_list.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';

// Import the provider from main.dart
import 'package:shoplite/main.dart';

class BlogScreen extends ConsumerStatefulWidget {
  const BlogScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends ConsumerState<BlogScreen> {
  @override
  void initState() {
    super.initState();
    // Load blogs when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBlogs();
    });
  }

  // Separate method for loading blogs with timeout
  Future<void> _loadBlogs() {
    ref.read(blogProvider).fetchBlogs();

    // Add timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && ref.read(blogProvider).isLoading) {
        // Force a UI refresh to show either error or empty state
        setState(() {});
      }
    });

    // Return the Future for RefreshIndicator
    return ref.read(blogProvider).fetchBlogs();
  }

  @override
  Widget build(BuildContext context) {
    final blogProviderState = ref.watch(blogProvider);
    final isDarkMode = ThemeController.isDarkMode;

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
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withOpacity(0.3),
                offset: const Offset(0, 3),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.article_outlined,
                            color: AppColors.fontLight,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "Bài viết & Tin tức",
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 360
                                  ? 16
                                  : 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.fontLight,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _loadBlogs,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.refresh,
                            color: AppColors.fontLight,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const ChatIconBadge(size: 22),
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
          // Background gradient
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

          // Content area
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                top: 65 + MediaQuery.of(context).padding.top + 5,
              ),
              child: _buildBody(blogProviderState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BlogProvider blogProvider) {
    // Show loading indicator with animation
    if (blogProvider.isLoading && blogProvider.blogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 24),
            Text(
              'Đang tải bài viết...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Show error message with retry button
    if (blogProvider.hasError && blogProvider.blogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _formatErrorMessage(blogProvider.errorMessage),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _loadBlogs(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.primaryColor,
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

    // Show blog list
    return RefreshIndicator(
      onRefresh: () async {
        await _loadBlogs();
      },
      color: AppColors.primaryColor,
      child: BlogList(
        blogs: blogProvider.blogs,
        isLoading: blogProvider.isLoading,
        hasMorePages: blogProvider.hasMorePages,
        loadMore: blogProvider.loadMoreBlogs,
      ),
    );
  }

  // Helper method to format error messages for better display
  String _formatErrorMessage(String error) {
    // Check if it's the missing BlogResource error
    if (error.contains('BlogResource not found') ||
        error.contains('chưa được cài đặt trên máy chủ')) {
      return 'Tính năng blog chưa được cài đặt trên máy chủ. Vui lòng liên hệ quản trị viên.';
    }

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

    // Server error
    if (error.contains('status code: 500')) {
      return 'Lỗi máy chủ. Vui lòng thử lại sau hoặc liên hệ quản trị viên.';
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
}
