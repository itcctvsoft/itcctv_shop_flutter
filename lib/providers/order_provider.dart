import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/models/order.dart';
import 'package:shoplite/repositories/order_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoplite/constants/pref_data.dart';

// Provider để theo dõi sự thay đổi user đăng nhập
final userChangedProvider = StateProvider<String>((ref) => '');

// Thêm provider theo dõi việc làm mới
final forceRefreshTokenProvider = StateProvider<bool>((ref) => false);

// Provider theo dõi thời gian làm mới đơn hàng cuối cùng
final lastOrderRefreshTimeProvider = StateProvider<DateTime?>((ref) => null);

// Provider để theo dõi trạng thái đang làm mới
final isRefreshingProvider = StateProvider<bool>((ref) => false);

// Provider tự động lấy dữ liệu đơn hàng và làm mới khi user thay đổi
final ordersProvider = FutureProvider<List<Order>>((ref) async {
  // Theo dõi sự thay đổi user
  final userId = ref.watch(userChangedProvider);

  // Theo dõi token làm mới
  final shouldRefresh = ref.watch(forceRefreshTokenProvider);

  final orderRepository = OrderRepository();
  return await orderRepository.getOrders(forceRefresh: shouldRefresh);
});

// Provider cho order đang được chọn để xem chi tiết
final selectedOrderProvider = StateProvider<Order?>((ref) => null);

// Provider để làm mới danh sách đơn hàng
final orderRefreshProvider = StateProvider<bool>((ref) => false);

// Provider để theo dõi trạng thái tải đơn hàng
class OrderNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  final OrderRepository _repository;
  final Ref _ref;
  String? _currentUserId;
  bool _isLoadingInProgress = false;

  OrderNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    // Khởi tạo theo dõi user ID
    _checkCurrentUser();

    // Theo dõi sự thay đổi user từ provider
    _ref.listen(userChangedProvider, (previous, next) {
      if (previous != next) {
        getOrders(forceRefresh: true);
      }
    });

    // Theo dõi token làm mới
    _ref.listen(forceRefreshTokenProvider, (previous, next) {
      if (next) {
        getOrders(forceRefresh: true);
      }
    });
  }

  // Kiểm tra user hiện tại và cập nhật nếu thay đổi
  Future<void> _checkCurrentUser() async {
    if (_isLoadingInProgress) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userId') ?? '';

      // Nếu user ID đã thay đổi, cập nhật và tải lại dữ liệu
      if (_currentUserId != userId) {
        _currentUserId = userId;
        _ref.read(userChangedProvider.notifier).state = userId;
        getOrders(forceRefresh: true);
      }
    } catch (e) {
      print('Error checking current user: $e');
    }
  }

  Future<void> getOrders({bool forceRefresh = false}) async {
    if (_isLoadingInProgress) return;

    _isLoadingInProgress = true;
    try {
      // Đánh dấu đang loading nhưng GIỮ LẠI dữ liệu hiện tại nếu có
      // Chỉ chuyển sang trạng thái loading nếu không có dữ liệu
      state = state.maybeWhen(
        data: (existingData) => existingData.isEmpty
            ? const AsyncValue.loading()
            : AsyncValue.data(
                existingData), // Giữ lại dữ liệu cũ trong khi load
        orElse: () => const AsyncValue.loading(),
      );

      // Luôn kiểm tra user hiện tại trước khi tải đơn hàng
      if (!forceRefresh) {
        await _checkCurrentUser();
      }

      // Tải dữ liệu mới
      final orders = await _repository.getOrders(forceRefresh: forceRefresh);

      // Đảm bảo còn mounted trước khi cập nhật state
      if (mounted) {
        // Nếu danh sách đơn hàng trống và không force refresh, giữ lại dữ liệu cũ
        if (orders.isEmpty && !forceRefresh) {
          state.maybeWhen(
            data: (existingData) {
              if (existingData.isNotEmpty) {
                state = AsyncValue.data(existingData);
                return;
              }
            },
            orElse: () {},
          );
        }

        // Cập nhật với dữ liệu mới
        state = AsyncValue.data(orders);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        // Nếu có lỗi nhưng có dữ liệu cũ, giữ lại dữ liệu cũ và hiển thị lỗi
        state.maybeWhen(
          data: (existingData) {
            if (existingData.isNotEmpty) {
              // Hiển thị lỗi nhưng giữ lại dữ liệu
              print('Error loading orders but keeping existing data: $e');
              state = AsyncValue.data(existingData);
              return;
            }
          },
          orElse: () {},
        );

        // Nếu không có dữ liệu cũ, hiển thị lỗi
        state = AsyncValue.error(e, stackTrace);
      }
    } finally {
      _isLoadingInProgress = false;
    }
  }

  // Phương thức để gọi khi đăng xuất
  void clearOrdersOnLogout() {
    state = const AsyncValue.data([]);
    _currentUserId = null;

    // Tăng token làm mới để các provider khác biết dữ liệu đã thay đổi
    final currentToken = _ref.read(forceRefreshTokenProvider);
    _ref.read(forceRefreshTokenProvider.notifier).state = !currentToken;
  }

  // Phương thức kiểm tra xem notifier còn hoạt động không
  // (Riverpod sẽ tự đánh dấu disposed khi không còn được sử dụng)
  bool get mounted {
    try {
      // Kiểm tra xem có thể đọc state không
      state.when(
        data: (_) {},
        loading: () {},
        error: (_, __) {},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Cập nhật trạng thái thanh toán cho một đơn hàng
  Future<bool> updateOrderPaymentStatus(Order order) async {
    try {
      final success = await _repository.updatePaymentStatus([order.id]);

      if (success) {
        // Làm mới dữ liệu đơn hàng
        await getOrders(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating order payment status: $e');
      return false;
    }
  }

  // Cập nhật trạng thái thanh toán cho nhiều đơn hàng
  Future<bool> updateMultipleOrdersPaymentStatus(List<Order> orders) async {
    try {
      final orderIds = orders.map((order) => order.id).toList();
      final success = await _repository.updatePaymentStatus(orderIds);

      if (success) {
        // Làm mới dữ liệu đơn hàng
        await getOrders(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating multiple orders payment status: $e');
      return false;
    }
  }

  // Đồng bộ trạng thái thanh toán cho tất cả đơn hàng
  Future<bool> syncAllOrdersPaymentStatus() async {
    try {
      final success = await _repository.syncPaymentStatus();

      if (success) {
        // Làm mới dữ liệu đơn hàng
        await getOrders(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e) {
      print('Error syncing all orders payment status: $e');
      return false;
    }
  }
}

final orderNotifierProvider =
    StateNotifierProvider<OrderNotifier, AsyncValue<List<Order>>>((ref) {
  return OrderNotifier(OrderRepository(), ref);
});
