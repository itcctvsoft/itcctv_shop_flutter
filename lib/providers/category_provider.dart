import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/models/category.dart';
import 'package:shoplite/repositories/category_repository.dart';
import 'package:flutter/material.dart';

// Khai báo provider để sử dụng CategoryRepository
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

// FutureProvider để lấy danh sách danh mục
final categoryListProvider =
    FutureProvider.autoDispose<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);

  try {
    final response = await repository.getCategories(1, 20);
    return response.categories;
  } catch (e) {
    print('Lỗi khi tải danh mục: $e');
    // Nếu lỗi thì trả về danh mục mẫu
    return repository.getDummyCategories();
  }
});

// Provider để lấy danh mục theo ID
final categoryByIdProvider =
    FutureProvider.autoDispose.family<Category?, int>((ref, categoryId) async {
  final categories = await ref.watch(categoryListProvider.future);
  return categories.firstWhere((category) => category.id == categoryId,
      orElse: () =>
          throw Exception('Không tìm thấy danh mục với ID: $categoryId'));
});

class CategoryProvider with ChangeNotifier {
  final CategoryRepository _repository;

  List<Category> _categories = [];
  int _currentPage = 1;
  int _perPage = 10;
  int _totalPages = 1;
  bool _isLoading = false;
  String? _errorMessage;

  CategoryProvider(this._repository);

  // Getters
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Lấy danh sách danh mục
  Future<void> fetchCategories({bool reset = false}) async {
    if (_isLoading) return;

    if (reset) {
      _currentPage = 1;
      _categories.clear();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getCategories(_currentPage, _perPage);
      if (reset) {
        _categories = response.categories;
      } else {
        _categories.addAll(response.categories);
      }
      _totalPages = response.pagination.lastPage;
      print(
          'Đã tải ${response.categories.length} danh mục, tổng số trang: $_totalPages');
    } catch (e) {
      _errorMessage = e.toString();
      print('Lỗi trong provider khi lấy danh mục: $e');

      // Sử dụng dữ liệu mẫu trong trường hợp lỗi
      if (_categories.isEmpty) {
        _categories = _repository.getDummyCategories();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tải thêm danh mục (trang tiếp theo)
  Future<void> loadMore() async {
    if (_isLoading || _currentPage >= _totalPages) return;

    _currentPage++;
    await fetchCategories(reset: false);
  }

  // Reset trạng thái
  void reset() {
    _categories.clear();
    _currentPage = 1;
    _totalPages = 1;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
