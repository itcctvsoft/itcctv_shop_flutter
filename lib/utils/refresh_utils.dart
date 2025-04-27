import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/providers/order_provider.dart';

/// Tiện ích để làm mới dữ liệu toàn cục trong ứng dụng
class RefreshUtils {
  /// Phương thức làm mới tất cả dữ liệu cần thiết khi đăng nhập/đăng xuất
  /// hoặc khi có thay đổi người dùng
  static void refreshAllData(WidgetRef ref) {
    // Làm mới dữ liệu đơn hàng một cách triệt để
    ref.read(orderNotifierProvider.notifier).getOrders(forceRefresh: true);

    // Thay đổi token làm mới để các provider khác biết cần làm mới
    ref.read(forceRefreshTokenProvider.notifier).state =
        !ref.read(forceRefreshTokenProvider);

    // Thêm các provider khác cần làm mới ở đây
    // Ví dụ: giỏ hàng, thông tin người dùng, v.v.
  }

  /// Phương thức làm mới dữ liệu theo yêu cầu (khi người dùng yêu cầu làm mới)
  static Future<void> refreshOnDemand(WidgetRef ref) async {
    // Đặt tiện ích vào trạng thái "đang làm mới"
    ref.read(isRefreshingProvider.notifier).state = true;

    try {
      // Làm mới dữ liệu đơn hàng
      await ref
          .read(orderNotifierProvider.notifier)
          .getOrders(forceRefresh: true);

      // Thay đổi token làm mới
      ref.read(forceRefreshTokenProvider.notifier).state =
          !ref.read(forceRefreshTokenProvider);

      // Đợi một chút để đảm bảo người dùng thấy được hiệu ứng làm mới
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      print('Error refreshing data: $e');
    } finally {
      // Đặt tiện ích về trạng thái "đã hoàn thành làm mới"
      ref.read(isRefreshingProvider.notifier).state = false;
    }
  }
}

// isRefreshingProvider đã được định nghĩa trong order_provider.dart
// nên không cần định nghĩa lại ở đây
