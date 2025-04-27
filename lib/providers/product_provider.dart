import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/models/product.dart';
import 'package:shoplite/repositories/product_repository.dart';
import 'dart:math' show min;

// Provider cho repository
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// Provider để lấy danh sách sản phẩm với AsyncValue và phân trang
final productListProvider =
FutureProvider.autoDispose<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);

  try {
    final response = await repository.getProducts(1, 10);
    // Filter out products with zero stock
    return response.items.where((product) => product.stock > 0).toList();
  } catch (e) {
    print('Error in productListProvider: $e');
    throw e;
  }
});

// Provider để lấy danh sách sản phẩm phổ biến (sản phẩm có số lượng ít nhất)
final randomProductsProvider =
FutureProvider.autoDispose<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);

  // Keep previous data on refresh/rebuild
  ref.keepAlive();

  // Get previous state value to use if needed
  final previousValue = ref.state.valueOrNull;

  try {
    // Get products with a larger limit to have more selection
    final response = await repository.getProducts(1, 30);

    // Filter out products with zero stock
    List<Product> products =
    response.items.where((product) => product.stock > 0).toList();

    // If we have less than 2 products, try getting products again with a different approach
    if (products.length < 2) {
      print(
          'Got too few products (${products.length}), trying another approach');
      final backup = await repository.getProducts(1, 50);
      products = backup.items.where((product) => product.stock > 0).toList();
    }

    // Sort products by stock (ascending) - products with least quantity first
    if (products.isNotEmpty) {
      products.sort((a, b) => a.stock.compareTo(b.stock));
    }

    // Return a subset of products (maximum 6 products)
    if (products.isEmpty) {
      // We got nothing even after our retry - throw a more descriptive error
      throw Exception('Không tìm thấy sản phẩm phổ biến');
    }

    return products.take(min(6, products.length)).toList();
  } catch (e) {
    print('Error in randomProductsProvider: $e');

    // If we already have data in the previous state, return that instead of throwing
    if (previousValue != null && previousValue.isNotEmpty) {
      print('Returning previous data due to error');
      return previousValue;
    }

    // Failed to get data and no previous data - try a fallback
    try {
      // As a fallback, get some products from a specific category (assuming category 1 exists)
      final fallbackResponse = await repository.getProductsByCategory(1, 1, 10);
      List<Product> fallbackProducts =
      fallbackResponse.items.where((product) => product.stock > 0).toList();

      if (fallbackProducts.isNotEmpty) {
        // Sort fallback products by stock (ascending)
        fallbackProducts.sort((a, b) => a.stock.compareTo(b.stock));
        print('Using fallback products from category');
        return fallbackProducts.take(min(6, fallbackProducts.length)).toList();
      }
    } catch (fallbackError) {
      print('Fallback also failed: $fallbackError');
    }

    // If everything fails, rethrow the original error
    throw e;
  }
});

// Provider để lấy sản phẩm theo danh mục với tham số categoryId
final productsByCategoryProvider = FutureProvider.autoDispose
    .family<List<Product>, int>((ref, categoryId) async {
  final repository = ref.watch(productRepositoryProvider);

  try {
    final response = await repository.getProductsByCategory(categoryId, 1, 10);
    // Filter out products with zero stock
    return response.items.where((product) => product.stock > 0).toList();
  } catch (e) {
    print('Error in productsByCategoryProvider: $e');
    throw e;
  }
});

// Provider để tìm kiếm sản phẩm
final searchProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, keyword) async {
  final repository = ref.watch(productRepositoryProvider);

  try {
    final response = await repository.searchProducts(keyword, 1, 10);
    // Filter out products with zero stock
    return response.items.where((product) => product.stock > 0).toList();
  } catch (e) {
    print('Error in searchProductsProvider: $e');
    throw e;
  }
});

// Provider để quản lý trạng thái sản phẩm với phân trang và bộ đệm
final productProvider = ChangeNotifierProvider<ProductProvider>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductProvider(repository);
});

class ProductProvider with ChangeNotifier {
  final ProductRepository _repository;

  List<Product> _products = [];
  int _currentPage = 1;
  int _perPage = 10;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int? _currentCategoryId; // Track current category ID
  String? _currentSearchQuery; // Track current search query

  // Cache for products to avoid re-fetching
  final Map<String, List<Product>> _productCache = {};
  final Map<int, List<Product>> _categoryProductCache = {};

  // Lưu trữ các tùy chọn tìm kiếm
  String? _sortBy;
  String? _sortOrder;
  double? _minPrice;
  double? _maxPrice;
  List<int>? _categoryIds;
  bool _onlyInStock = true;

  ProductProvider(this._repository);

  // Getters
  List<Product> get products => _products;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int? get currentCategoryId => _currentCategoryId;

  // Lấy danh sách sản phẩm với caching
  Future<void> fetchProducts({bool reset = false, int? perPage}) async {
    if (_isLoading && !reset) return;

    final String cacheKey =
        'products_page${reset ? 1 : _currentPage}_perPage$_perPage';

    if (!reset && _productCache.containsKey(cacheKey)) {
      if (reset) {
        _products = _productCache[cacheKey]!;
      } else {
        _products.addAll(_productCache[cacheKey]!);
      }
      notifyListeners();
      return;
    }

    if (reset) {
      _products.clear();
      _currentPage = 1;
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }

    if (perPage != null) {
      _perPage = perPage;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getProducts(_currentPage, _perPage);
      final newProducts =
      response.items.where((product) => product.stock > 0).toList();

      // Update cache
      _productCache[cacheKey] = newProducts;

      if (reset) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      _totalPages = response.pagination.lastPage;
    } catch (e) {
      _errorMessage = 'Không thể tải sản phẩm: ${e.toString()}';
      print('Error in fetchProducts: $_errorMessage');
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Tìm kiếm sản phẩm
  Future<void> searchProducts(
      String keyword, {
        int? perPage,
        String? sortBy,
        String? sortOrder,
        double? minPrice,
        double? maxPrice,
        List<int>? categoryIds,
        bool onlyInStock = true,
      }) async {
    if (_isLoading) return;

    if (perPage != null) {
      _perPage = perPage;
    }

    // Kiểm tra bộ nhớ đệm
    final String cacheKey = 'search_${keyword}_page$_currentPage'
        '_sort${sortBy ?? ''}_order${sortOrder ?? ''}'
        '_min${minPrice?.toInt() ?? 0}_max${maxPrice?.toInt() ?? 0}'
        '_cats${categoryIds?.join('-') ?? ''}_stock$onlyInStock';

    if (_productCache.containsKey(cacheKey) && _currentPage == 1) {
      _products = _productCache[cacheKey]!;
      notifyListeners();
      return;
    }

    // Lưu các tùy chọn tìm kiếm
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _categoryIds = categoryIds;
    _onlyInStock = onlyInStock;

    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _currentCategoryId = null; // Reset category ID when searching
    _currentSearchQuery = keyword; // Store search query
    _products.clear();
    notifyListeners();

    try {
      final response = await _repository.searchProducts(
        keyword,
        _currentPage,
        _perPage,
        sortBy: sortBy,
        sortOrder: sortOrder,
        minPrice: minPrice,
        maxPrice: maxPrice,
        categoryIds: categoryIds,
      );

      _products = response.items
          .where((product) => onlyInStock ? product.stock > 0 : true)
          .toList();

      // Cache the results
      _productCache[cacheKey] = _products;

      _totalPages = response.pagination.lastPage;
    } catch (e) {
      _errorMessage = 'Tìm kiếm thất bại: ${e.toString()}';
      print('Error in searchProducts: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy sản phẩm theo danh mục với caching
  Future<void> fetchProductsByCategory(int categoryId,
      {int? perPage, bool forceRefresh = false}) async {
    if (_isLoading) return;

    if (perPage != null) {
      _perPage = perPage;
    }

    final String cacheKey = 'category${categoryId}_page$_currentPage';

    // Sử dụng cache chỉ khi không yêu cầu làm mới và cache có dữ liệu
    if (!forceRefresh &&
        _categoryProductCache.containsKey(categoryId) &&
        _currentPage == 1) {
      _products = _categoryProductCache[categoryId]!;
      _currentCategoryId = categoryId;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _currentCategoryId = categoryId; // Store category ID for loadMore
    _products.clear();
    notifyListeners();

    try {
      final response = await _repository.getProductsByCategory(
          categoryId, _currentPage, _perPage);
      _products = response.items.where((product) => product.stock > 0).toList();

      // Cache the results
      _categoryProductCache[categoryId] = _products;

      _totalPages = response.pagination.lastPage;
    } catch (e) {
      _errorMessage = 'Không thể tải sản phẩm: ${e.toString()}';
      print('Error in fetchProductsByCategory: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tải thêm sản phẩm (load more) với phân trang tối ưu
  Future<void> loadMore({int? perPage}) async {
    if (_isLoading || _isLoadingMore || _currentPage >= _totalPages) {
      print(
          'Skip loadMore: isLoading=$_isLoading, isLoadingMore=$_isLoadingMore, currentPage=$_currentPage, totalPages=$_totalPages');
      return;
    }

    if (perPage != null) {
      _perPage = perPage;
    }

    _currentPage++;
    _isLoadingMore = true;
    notifyListeners();

    print('Loading more: page $_currentPage with $_perPage per page');

    try {
      if (_currentSearchQuery != null && _currentSearchQuery!.isNotEmpty) {
        // Nếu đang tìm kiếm, load thêm kết quả tìm kiếm
        final response = await _repository.searchProducts(
          _currentSearchQuery!,
          _currentPage,
          _perPage,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          categoryIds: _categoryIds,
        );

        final newItems = response.items
            .where((product) => _onlyInStock ? product.stock > 0 : true)
            .toList();

        _products.addAll(newItems);
        _totalPages = response.pagination.lastPage;
      } else if (_currentCategoryId != null) {
        // Nếu đang xem theo danh mục, load thêm sản phẩm của danh mục
        final response = await _repository.getProductsByCategory(
            _currentCategoryId!, _currentPage, _perPage);

        final newItems =
        response.items.where((product) => product.stock > 0).toList();
        _products.addAll(newItems);
        _totalPages = response.pagination.lastPage;
      } else {
        // Nếu đang xem tất cả sản phẩm, load thêm sản phẩm
        final response = await _repository.getProducts(_currentPage, _perPage);
        final newItems =
        response.items.where((product) => product.stock > 0).toList();
        _products.addAll(newItems);
        _totalPages = response.pagination.lastPage;
      }
    } catch (e) {
      _errorMessage = 'Không thể tải thêm sản phẩm: ${e.toString()}';
      print('Error in loadMore: $_errorMessage');
      _currentPage--; // Revert page increment on failure
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Chuyển đến trang cụ thể
  Future<void> goToPage(int page) async {
    if (page < 1 || page > _totalPages) {
      throw Exception('Invalid page number: $page (total pages: $_totalPages)');
    }

    if (_isLoading) return;

    _currentPage = page;
    notifyListeners();
  }

  // Xóa bộ nhớ đệm
  void clearCache() {
    _productCache.clear();
    _categoryProductCache.clear();
  }

  // Reset trạng thái
  void reset() {
    _products.clear();
    _currentPage = 1;
    _totalPages = 1;
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _currentCategoryId = null; // Reset category ID
    _currentSearchQuery = null; // Reset search query
    notifyListeners();
  }
}
