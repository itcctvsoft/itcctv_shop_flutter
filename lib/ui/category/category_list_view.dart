import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/providers/category_provider.dart';
import '../../../constants/color_data.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';
import 'package:shoplite/widgets/optimized_image.dart';
import '../category/category_list.dart';
import 'package:shoplite/constants/utils.dart';

extension ColorExtension on String {
  toColor() {
    var hexColor = replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
  }
}

class CategoryListView extends ConsumerStatefulWidget {
  @override
  ConsumerState<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends ConsumerState<CategoryListView> {
  late List uniqueCategories;
  late Set<int> seenIds;
  bool isDarkMode = false;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    isDarkMode = ThemeController.isDarkMode;
    ThemeController.addListener(_onThemeChanged);

    // Thêm lắng nghe sự kiện cuộn để tải thêm danh mục khi cuộn đến cuối
    _scrollController.addListener(_scrollListener);

    // Tải danh sách danh mục ban đầu
    _loadCategories();
  }

  @override
  void dispose() {
    print('dispose: State bị hủy, giải phóng tài nguyên');
    ThemeController.removeListener(_onThemeChanged);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Hàm lắng nghe sự kiện cuộn
  void _scrollListener() {
    // Kiểm tra nếu đã cuộn đến gần cuối danh sách (còn khoảng 200 pixel)
    if (_scrollController.position.extentAfter < 200 && !_isLoadingMore) {
      _loadMoreCategories();
    }
  }

  // Hàm tải thêm danh mục
  void _loadMoreCategories() {
    // Vì đang dùng FutureProvider, ta chỉ có thể refresh để tải lại toàn bộ
    if (!_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });

      // Tải thêm danh mục bằng cách refresh provider
      Future.delayed(Duration(milliseconds: 500), () {
        ref.refresh(categoryListProvider);

        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  void _onThemeChanged() {
    setState(() {
      isDarkMode = ThemeController.isDarkMode;
    });
  }

  // Hàm tải danh sách danh mục
  void _loadCategories() {
    // Dùng refresh để tải lại danh sách - phù hợp với FutureProvider
    ref.refresh(categoryListProvider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Tải lại danh mục khi quay lại màn hình này
    final categoryListAsync = ref.watch(categoryListProvider);
    if (categoryListAsync.hasError) {
      print('Error detected in category list, reloading');
      Future.microtask(() {
        _loadCategories();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final categoryListAsync = ref.watch(categoryListProvider);

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      Expanded(
                        child: Text(
                          'Danh sách danh mục',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.fontLight,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
              // Content
              categoryListAsync.when(
                data: (categories) {
                  uniqueCategories = [];
                  seenIds = Set();

                  for (var category in categories) {
                    if (!seenIds.contains(category.id)) {
                      uniqueCategories.add(category);
                      seenIds.add(category.id);
                    }
                  }

                  return Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(10),
                        itemCount:
                            uniqueCategories.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Hiển thị loading indicator ở cuối danh sách
                          if (index == uniqueCategories.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            );
                          }

                          final category = uniqueCategories[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: AppColors.shadowColor,
                                width: 1.0,
                              ),
                            ),
                            color: AppColors.cardColor,
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 15),
                              leading: category.photos.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: OptimizedImage(
                                        imageUrl:
                                            _getImageUrl(category.photos[0]),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        isDarkMode: isDarkMode,
                                        borderRadius: 5,
                                      ),
                                    )
                                  : Icon(Icons.image_not_supported,
                                      size: 60, color: AppColors.greyFont),
                              title: Text(
                                category.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.fontBlack,
                                  fontSize: 16,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: AppColors.greyFont,
                              ),
                              onTap: () {
                                // Navigate to CategoryList with initial category selected
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CategoryList(
                                      initialCategoryId: category.id,
                                      initialCategoryName: category.title,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      // Hiển thị loading khi tải lần đầu
                      if (categoryListAsync.isLoading && categories.isEmpty)
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Đã xảy ra lỗi: ${error.toString()}',
                        style: TextStyle(color: AppColors.fontBlack),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.refresh(categoryListProvider);
                        },
                        child: Text('Thử lại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: AppColors.fontLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.backgroundColor,
        );
      },
    );
  }

  /// Thay đổi URL để hoạt động trên giả lập Android
  String _getImageUrl(String url) {
    return getImageUrl(url);
  }

  @override
  void deactivate() {
    super.deactivate();
    print('deactivate: State bị loại bỏ khỏi cây widget');
  }
}
