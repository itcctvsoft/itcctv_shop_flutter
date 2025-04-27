import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/constants/utils.dart';
import 'package:shoplite/models/order.dart';
import 'package:shoplite/providers/order_provider.dart';
import 'package:shoplite/ui/order/order_detail_screen.dart';
import 'package:shoplite/utils/refresh_utils.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';

// Trạng thái hiển thị cho màn hình
enum OrderHistoryDisplayState {
  loading,
  data,
  empty,
  error,
}

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isInitialized = false;
  bool _isFirstBuild = true;
  OrderHistoryDisplayState _displayState = OrderHistoryDisplayState.loading;
  String? _errorMessage;
  List<Order> _cachedOrders = [];

  // Đảm bảo giữ lại trạng thái khi chuyển tab
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Đảm bảo load dữ liệu khi màn hình được tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Đảm bảo load dữ liệu khi các dependencies thay đổi
    if (!_isInitialized) {
      _loadOrderData();
      _isInitialized = true;
    }
  }

  @override
  void didUpdateWidget(covariant OrderHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndRefreshIfNeeded();
  }

  // Kiểm tra và làm mới dữ liệu nếu cần (khi quay lại màn hình)
  void _checkAndRefreshIfNeeded() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final lastRefreshTime = ref.read(lastOrderRefreshTimeProvider);
        final now = DateTime.now();

        // Nếu thời gian làm mới đã quá 5 phút, tự động làm mới
        if (lastRefreshTime == null ||
            now.difference(lastRefreshTime).inMinutes > 5) {
          _loadOrderData();
        }
      });
    }
  }

  Future<void> _loadOrderData() async {
    if (!mounted) return;

    try {
      // Chỉ hiển thị loading nếu không có dữ liệu cached
      if (_cachedOrders.isEmpty) {
        setState(() {
          _displayState = OrderHistoryDisplayState.loading;
        });
      }

      // Đặt trạng thái làm mới
      ref.read(isRefreshingProvider.notifier).state = true;

      // Làm mới dữ liệu đơn hàng
      await ref
          .read(orderNotifierProvider.notifier)
          .getOrders(forceRefresh: true);

      // Cập nhật thời gian làm mới cuối cùng
      ref.read(lastOrderRefreshTimeProvider.notifier).state = DateTime.now();

      // Không cần đợi sau khi gọi - tránh block UI
      ref.read(forceRefreshTokenProvider.notifier).state =
          !ref.read(forceRefreshTokenProvider);

      if (mounted) {
        setState(() {
          _displayState = OrderHistoryDisplayState.data;
        });
      }
    } catch (e) {
      print('Error loading order data: $e');
      if (mounted) {
        // Chỉ hiển thị lỗi nếu không có dữ liệu cached
        if (_cachedOrders.isEmpty) {
          setState(() {
            _displayState = OrderHistoryDisplayState.error;
            _errorMessage = e.toString();
          });
        }
      }
    } finally {
      // Đảm bảo kết thúc trạng thái làm mới
      if (mounted) {
        ref.read(isRefreshingProvider.notifier).state = false;
      }
    }
  }

  // Pull to refresh functionality
  Future<void> refreshOrders() async {
    try {
      await RefreshUtils.refreshOnDemand(ref);
      ref.read(lastOrderRefreshTimeProvider.notifier).state = DateTime.now();

      if (mounted) {
        setState(() {
          _displayState = OrderHistoryDisplayState.data;
        });
      }
    } catch (e) {
      print('Error during manual refresh: $e');
      // Không cần set error state vì đây là manual refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    final themeData = Theme.of(context);
    final ordersAsync = ref.watch(orderNotifierProvider);
    final isRefreshing = ref.watch(isRefreshingProvider);

    // Cập nhật trạng thái từ dữ liệu provider
    ordersAsync.whenData((orders) {
      if (_isFirstBuild || _cachedOrders.isEmpty) {
        _cachedOrders = orders;
        _isFirstBuild = false;

        // Kiểm tra nếu orders trống và không đang loading
        if (_cachedOrders.isEmpty && !isRefreshing && mounted) {
          _displayState = OrderHistoryDisplayState.empty;
        } else if (_cachedOrders.isNotEmpty && mounted) {
          _displayState = OrderHistoryDisplayState.data;
        }
      }
    });

    ordersAsync.maybeWhen(
        error: (error, stack) {
          // Chỉ hiển thị lỗi nếu không có dữ liệu cached
          if (_cachedOrders.isEmpty && mounted) {
            _displayState = OrderHistoryDisplayState.error;
            _errorMessage = error.toString();
          }
        },
        orElse: () {});

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
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
                      'Lịch sử đơn hàng',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.fontLight,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  GestureDetector(
                    onTap: refreshOrders,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.refresh,
                            color: AppColors.fontLight,
                            size: 22,
                          ),
                          if (isRefreshing)
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.fontLight),
                              ),
                            ),
                        ],
                      ),
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
      body: RefreshIndicator(
        onRefresh: refreshOrders,
        color: AppColors.primaryColor,
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      themeData.brightness == Brightness.dark
                          ? AppColors.primaryColor.withOpacity(0.2)
                          : AppColors.primaryColor.withOpacity(0.05),
                      themeData.brightness == Brightness.dark
                          ? const Color(0xFF121212)
                          : Colors.white,
                    ],
                    stops: themeData.brightness == Brightness.dark
                        ? const [0.0, 0.35]
                        : const [0.0, 0.3],
                  ),
                ),
              ),
            ),
            // Original content
            _buildMainContent(themeData, isRefreshing),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData themeData, bool isRefreshing) {
    switch (_displayState) {
      case OrderHistoryDisplayState.loading:
        return _buildLoadingState();

      case OrderHistoryDisplayState.data:
        return _buildOrdersList(isRefreshing);

      case OrderHistoryDisplayState.empty:
        return _buildEmptyState(context, themeData);

      case OrderHistoryDisplayState.error:
        return _buildErrorState(
            themeData, _errorMessage ?? 'Unknown error', refreshOrders);
    }
  }

  Widget _buildOrdersList(bool isRefreshing) {
    // Hiển thị shimmer loading effect khi đang làm mới nhưng có dữ liệu
    if (isRefreshing) {
      return Stack(
        children: [
          _buildOrderListView(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.7),
                    AppColors.primaryDarkColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      );
    }

    return _buildOrderListView();
  }

  Widget _buildOrderListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cachedOrders.length,
      itemBuilder: (context, index) {
        final order = _cachedOrders[index];
        return _buildOrderCard(context, ref, order);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải đơn hàng...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.greyFont,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData themeData) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: ThemeController.isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 70,
                  color: AppColors.primaryColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bạn chưa có đơn hàng nào',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.fontBlack,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hãy mua sắm ngay!',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.greyFont,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Mua sắm ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.fontLight,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
      ThemeData themeData, Object error, Function refreshOrders) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Không thể tải lịch sử đơn hàng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.fontBlack,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.greyFont,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => refreshOrders(),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.fontLight,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, Order order) {
    // Format order date
    String formattedDate = '';
    try {
      DateTime dateTime = DateTime.parse(order.orderDate);
      formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      formattedDate = order.orderDate;
    }

    // Determine order status color and text
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (order.orderStatus.toLowerCase()) {
      case 'completed':
      case 'hoàn thành':
      case 'đã giao':
      case 'done':
        statusColor = Colors.green.shade400;
        statusIcon = Icons.check_circle_outline;
        statusText = 'done';
        break;
      case 'processing':
      case 'đang xử lý':
        statusColor = Colors.orange.shade400;
        statusIcon = Icons.pending_outlined;
        statusText = 'processing';
        break;
      case 'cancelled':
      case 'hủy':
      case 'đã hủy':
        statusColor = Colors.red.shade400;
        statusIcon = Icons.cancel_outlined;
        statusText = 'cancelled';
        break;
      case 'pending':
      default:
        statusColor = Colors.blue.shade400;
        statusIcon = Icons.schedule;
        statusText = 'pending';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppColors.cardColor,
      child: InkWell(
        onTap: () {
          // Lưu trữ order được chọn trong provider
          ref.read(selectedOrderProvider.notifier).state = order;

          // Điều hướng đến trang chi tiết đơn hàng
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: statusColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${order.details.length} sản phẩm',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.greyFont,
                      ),
                    ),
                  ],
                ),
              ),

              // Order ID and total amount
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn hàng #${order.id}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.fontBlack,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrency(order.orderTotal),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'VND',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.greyFont,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Order date and payment status
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.greyFont,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ngày đặt: $formattedDate',
                      style: TextStyle(
                        color: AppColors.greyFont,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.payment_outlined,
                      size: 14,
                      color: AppColors.greyFont,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: order.paymentStatus
                                .toLowerCase()
                                .contains('đã thanh toán')
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: order.paymentStatus
                                  .toLowerCase()
                                  .contains('đã thanh toán')
                              ? Colors.green.withOpacity(0.5)
                              : Colors.orange.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            order.paymentStatus
                                    .toLowerCase()
                                    .contains('đã thanh toán')
                                ? Icons.check_circle_outline
                                : Icons.pending_outlined,
                            size: 14,
                            color: order.paymentStatus
                                    .toLowerCase()
                                    .contains('đã thanh toán')
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.paymentStatus,
                            style: TextStyle(
                              color: order.paymentStatus
                                      .toLowerCase()
                                      .contains('đã thanh toán')
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // View details button
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: TextButton(
                  onPressed: () {
                    ref.read(selectedOrderProvider.notifier).state = order;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailScreen(order: order),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.fontLight,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Xem chi tiết',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Đồng bộ trạng thái thanh toán
  Future<void> _syncPaymentStatus(BuildContext context) async {
    if (ref.read(isRefreshingProvider)) return;

    try {
      // Bắt đầu quá trình làm mới
      ref.read(isRefreshingProvider.notifier).state = true;

      // Gọi API đồng bộ trạng thái thanh toán
      final success = await ref
          .read(orderNotifierProvider.notifier)
          .syncAllOrdersPaymentStatus();

      if (success) {
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đồng bộ trạng thái thanh toán thành công'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        // Hiển thị thông báo lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể đồng bộ trạng thái thanh toán'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error syncing payment status: $e');
      // Hiển thị thông báo lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      // Kết thúc trạng thái làm mới
      ref.read(isRefreshingProvider.notifier).state = false;
    }
  }
}
