import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/repositories/wishlist_repository.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Provider for wishlist repository
final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository();
});

// Provider to store the list of product IDs in the wishlist
final wishlistProductIdsProvider =
    StateNotifierProvider<WishlistProductIdsNotifier, AsyncValue<List<int>>>(
  (ref) => WishlistProductIdsNotifier(ref.read(wishlistRepositoryProvider)),
);

// Checks if a specific product is in the wishlist
final isProductInWishlistProvider =
    Provider.family<AsyncValue<bool>, int>((ref, productId) {
  final wishlistIdsAsync = ref.watch(wishlistProductIdsProvider);

  return wishlistIdsAsync.when(
    data: (ids) => AsyncValue.data(ids.contains(productId)),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

class WishlistProductIdsNotifier extends StateNotifier<AsyncValue<List<int>>> {
  final WishlistRepository _repository;

  WishlistProductIdsNotifier(this._repository)
      : super(const AsyncValue.data([])) {
    loadWishlist();
  }

  Future<bool> toggleWishlist(int productId) async {
    if (g_token.isEmpty) {
      print('WishlistProvider: Token trống, không thể thêm/xóa yêu thích');
      return false;
    }

    try {
      // Lưu trạng thái hiện tại
      final currentState = state;
      final currentWishlist = state.value ?? [];
      final isInWishlist = currentWishlist.contains(productId);

      // Cập nhật state tạm thời ngay lập tức cho phản hồi UI nhanh
      if (isInWishlist) {
        state = AsyncValue.data(
            currentWishlist.where((id) => id != productId).toList());
      } else {
        state = AsyncValue.data([...currentWishlist, productId]);
      }

      // Gửi yêu cầu API
      final success = isInWishlist
          ? await _repository.removeFromWishlist(g_token, productId)
          : await _repository.addToWishlist(g_token, productId);

      if (success) {
        // Tải lại danh sách từ server để đồng bộ
        await loadWishlist();
        return true;
      } else {
        // Khôi phục state nếu API thất bại
        state = currentState;
        print(
            'WishlistProvider: API thất bại khi thêm/xóa sản phẩm $productId');
        return false;
      }
    } catch (e) {
      print('WishlistProvider: Lỗi khi thêm/xóa yêu thích - $e');
      // Tải lại danh sách để đảm bảo state đồng bộ với server
      await loadWishlist();
      return false;
    }
  }

  Future<void> loadWishlist() async {
    state = const AsyncValue.loading();
    try {
      print('WishlistProvider: Bắt đầu tải danh sách yêu thích');
      if (g_token.isEmpty) {
        print(
            'WishlistProvider: Token trống, không thể tải danh sách yêu thích');
        state = const AsyncValue.data([]);
        return;
      }

      final response = await http.get(
        Uri.parse(api_wishlist_view),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $g_token',
        },
      );

      print('WishlistProvider: API Response Status: ${response.statusCode}');
      print('WishlistProvider: API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          // Cấu trúc dữ liệu đã thay đổi theo endpoint list
          final List<dynamic> wishlistItems = data['data']['wishlists'];
          final List<int> productIds = wishlistItems
              .map<int>((item) => item['product_id'] as int)
              .toList();

          print(
              'WishlistProvider: Tải thành công ${productIds.length} sản phẩm yêu thích');
          state = AsyncValue.data(productIds);
        } else {
          print('WishlistProvider: Dữ liệu rỗng hoặc không hợp lệ');
          state = const AsyncValue.data([]);
        }
      } else if (response.statusCode == 401) {
        print('WishlistProvider: Lỗi xác thực (401)');
        state = const AsyncValue.data([]);
      } else {
        print('WishlistProvider: Lỗi API - Status: ${response.statusCode}');
        throw Exception('Không thể tải danh sách yêu thích');
      }
    } catch (e) {
      print('WishlistProvider: Lỗi khi tải danh sách yêu thích: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
