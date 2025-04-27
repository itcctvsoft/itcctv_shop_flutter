import 'package:flutter/material.dart';
import 'package:shoplite/models/blog.dart';
import 'package:shoplite/repositories/blog_repository.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

class BlogProvider extends ChangeNotifier {
  final BlogRepository _repository = BlogRepository();

  // Blog list state
  List<Blog> _blogs = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  int _lastPage = 1;
  bool _hasMorePages = true;

  // Blog detail state
  Blog? _currentBlog;
  List<Blog> _relatedBlogs = [];
  List<BlogTag> _blogTags = [];
  bool _isLoadingDetail = false;
  bool _hasDetailError = false;
  String _detailErrorMessage = '';

  // Getters
  List<Blog> get blogs => _blogs;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  bool get hasMorePages => _hasMorePages;

  Blog? get currentBlog => _currentBlog;
  List<Blog> get relatedBlogs => _relatedBlogs;
  List<BlogTag> get blogTags => _blogTags;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get hasDetailError => _hasDetailError;
  String get detailErrorMessage => _detailErrorMessage;

  // Fetch blogs (initial load)
  Future<void> fetchBlogs() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      if (kDebugMode) {
        print('⏳ Fetching blog list');
      }

      // Implement retry mechanism
      int retryCount = 0;
      bool success = false;
      Exception? lastError;

      while (retryCount < 3 && !success) {
        try {
          final blogPagination =
              await _repository.getAllBlogs(page: _currentPage);
          _blogs = blogPagination.blogs;
          _lastPage = blogPagination.lastPage;
          _hasMorePages = _currentPage < _lastPage;
          success = true;

          if (kDebugMode) {
            print('✅ Blog list loaded successfully. Count: ${_blogs.length}');
          }
        } catch (e) {
          retryCount++;
          lastError = e is Exception ? e : Exception(e.toString());

          if (kDebugMode) {
            print('⚠️ Retry $retryCount failed: ${e.toString()}');
          }

          if (retryCount < 3) {
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          }
        }
      }

      if (!success) {
        throw lastError ??
            Exception('Failed to load blogs after multiple retries');
      }
    } catch (e) {
      _hasError = true;

      // Provide more specific Vietnamese error messages
      if (e is SocketException) {
        _errorMessage =
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.';
      } else if (e is TimeoutException) {
        _errorMessage = 'Kết nối đã hết thời gian. Vui lòng thử lại sau.';
      } else if (e.toString().contains('format')) {
        _errorMessage =
            'Định dạng dữ liệu không hợp lệ. Vui lòng liên hệ quản trị viên.';
      } else {
        _errorMessage = e.toString();
      }

      if (kDebugMode) {
        print('❌ Error fetching blog list: $e');
        print('Stack trace: ${StackTrace.current}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more blogs (pagination)
  Future<void> loadMoreBlogs() async {
    if (!_hasMorePages || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final blogPagination = await _repository.getAllBlogs(page: nextPage);

      _blogs.addAll(blogPagination.blogs);
      _currentPage = nextPage;
      _hasMorePages = _currentPage < _lastPage;
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch blog detail
  Future<void> fetchBlogDetail(String slug) async {
    // Reset state before fetching
    _isLoadingDetail = true;
    _hasDetailError = false;
    _detailErrorMessage = '';
    notifyListeners();

    // Create a timeout that will automatically fail the request if it takes too long
    Timer? timeoutTimer;
    timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (_isLoadingDetail) {
        _isLoadingDetail = false;
        _hasDetailError = true;
        _detailErrorMessage =
            'Quá thời gian tải bài viết. Vui lòng thử lại sau.';
        notifyListeners();

        if (kDebugMode) {
          print(
              '❌ Blog detail request timed out after 10 seconds for slug: $slug');
        }
      }
    });

    try {
      // Add logging for debugging
      if (kDebugMode) {
        print('⏳ Fetching blog detail for slug: $slug');
      }

      // Implement retry mechanism (try up to 3 times)
      int retryCount = 0;
      bool success = false;
      Exception? lastError;

      while (retryCount < 3 && !success && _isLoadingDetail) {
        try {
          final blogDetail = await _repository.getBlogDetail(slug);

          // Cancel timeout since we got a response
          timeoutTimer.cancel();

          // Only process if we're still in loading state (not timed out)
          if (_isLoadingDetail) {
            _currentBlog = blogDetail['blog'];
            _relatedBlogs = blogDetail['relatedBlogs'];
            _blogTags = blogDetail['tags'];
            success = true;

            // Log success
            if (kDebugMode) {
              print(
                  '✅ Blog detail loaded successfully for: ${_currentBlog?.title}');
            }
          }
        } catch (e) {
          // Incremental backoff (wait a bit longer each retry)
          retryCount++;
          lastError = e is Exception ? e : Exception(e.toString());

          if (kDebugMode) {
            print('⚠️ Retry $retryCount failed: ${e.toString()}');
          }

          if (retryCount < 3 && _isLoadingDetail) {
            // Wait before retrying (incremental delay)
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          }
        }
      }

      // Cancel timeout since we're done with retries
      timeoutTimer.cancel();

      if (!success && _isLoadingDetail) {
        throw lastError ??
            Exception('Failed to load blog after multiple retries');
      }
    } catch (e) {
      // Cancel timeout since we're handling the error now
      timeoutTimer.cancel();

      _hasDetailError = true;
      // Provide more specific error messages
      if (e is SocketException) {
        _detailErrorMessage =
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.';
      } else if (e is TimeoutException) {
        _detailErrorMessage = 'Kết nối đã hết thời gian. Vui lòng thử lại sau.';
      } else if (e.toString().contains('format')) {
        _detailErrorMessage =
            'Định dạng dữ liệu không hợp lệ. Vui lòng liên hệ quản trị viên.';
      } else {
        _detailErrorMessage = e.toString();
      }

      // Log detailed error for debugging
      if (kDebugMode) {
        print('❌ Error fetching blog detail: $e');
        print('Stack trace: ${StackTrace.current}');
      }
    } finally {
      // Cancel timeout just in case
      timeoutTimer.cancel();

      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  // Reset detail data - this is now automatically called when provider is disposed
  void resetBlogDetail() {
    _currentBlog = null;
    _relatedBlogs = [];
    _blogTags = [];
    _isLoadingDetail = false;
    _hasDetailError = false;
    _detailErrorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up any resources or subscription here
    resetBlogDetail();
    super.dispose();
  }
}
