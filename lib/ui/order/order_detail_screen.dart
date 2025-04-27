import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/constants/utils.dart';
import 'package:shoplite/models/order.dart';
import 'package:shoplite/providers/order_provider.dart';
import 'package:shoplite/utils/refresh_utils.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';
import 'package:shoplite/screens/chat_screen.dart';

class OrderDetailScreen extends ConsumerWidget {
  final Order order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = Theme.of(context);

    // Force refresh when screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RefreshUtils.refreshAllData(ref);
    });

    // Format order date
    String formattedDate = '';
    try {
      DateTime dateTime = DateTime.parse(order.orderDate);
      formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      formattedDate = order.orderDate;
    }

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
                      'Chi tiết đơn hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.fontLight,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Order status banner with improved design
                _buildStatusBanner(context, order.orderStatus),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderInfoSection(context, formattedDate),
                      const SizedBox(height: 24),
                      _buildProductsHeader(context),
                      const SizedBox(height: 12),
                      _buildProductList(context),
                      const SizedBox(height: 24),
                      _buildTotalSection(context),
                      const SizedBox(height: 24),
                      _buildActionButtons(context),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, String status) {
    final themeData = Theme.of(context);
    Color statusColor;
    IconData statusIcon;
    String statusMessage;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'hoàn thành':
      case 'đã giao':
      case 'done':
        statusColor = Colors.green.shade400;
        statusIcon = Icons.check_circle;
        statusMessage = 'Đơn hàng đã hoàn thành';
        break;
      case 'processing':
      case 'đang xử lý':
        statusColor = Colors.orange.shade400;
        statusIcon = Icons.pending;
        statusMessage = 'Đơn hàng đang được xử lý';
        break;
      case 'pending':
        statusColor = Colors.blue.shade400;
        statusIcon = Icons.schedule;
        statusMessage = 'Đơn hàng đang chờ xử lý';
        break;
      case 'cancelled':
      case 'hủy':
      case 'đã hủy':
        statusColor = Colors.red.shade400;
        statusIcon = Icons.cancel;
        statusMessage = 'Đơn hàng đã bị hủy';
        break;
      default:
        statusColor = Colors.blue.shade400;
        statusIcon = Icons.info;
        statusMessage = 'Trạng thái: $status';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        border: Border(bottom: BorderSide(color: statusColor, width: 1)),
      ),
      child: Column(
        children: [
          Icon(statusIcon, color: statusColor, size: 36),
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusMessage,
            style: TextStyle(
              color: themeData.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoSection(BuildContext context, String formattedDate) {
    final themeData = Theme.of(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: themeData.cardColor,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: themeData.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Thông tin đơn hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, 'ID đơn hàng:', '#${order.id}',
                iconData: Icons.tag),
            _buildInfoRow(context, 'Ngày đặt:', formattedDate,
                iconData: Icons.calendar_today),
            _buildInfoRow(context, 'Thanh toán:', order.paymentStatus,
                iconData: Icons.payment,
                valueColor:
                    order.paymentStatus.toLowerCase().contains("đã thanh toán")
                        ? Colors.green.shade600
                        : Colors.orange,
                valueBold: true),
            if (order.remainingAmount != null && order.remainingAmount! > 0)
              _buildInfoRow(
                context,
                'Còn lại:',
                '${formatCurrency(order.remainingAmount!)} VNĐ',
                iconData: Icons.pending_actions,
                valueColor: Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value,
      {IconData? iconData, Color? valueColor, bool valueBold = false}) {
    final themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (iconData != null) ...[
            Icon(
              iconData,
              size: 16,
              color: themeData.colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: themeData.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? themeData.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsHeader(BuildContext context) {
    final themeData = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.shopping_bag_outlined,
          color: themeData.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Sản phẩm đã đặt',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: themeData.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: themeData.colorScheme.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${order.details.length}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductList(BuildContext context) {
    final themeData = Theme.of(context);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: order.details.length,
      itemBuilder: (context, index) {
        final item = order.details[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
          color: themeData.cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: themeData.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                themeData.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'x${item.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: themeData.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${formatCurrency(item.price)} VNĐ',
                          style: TextStyle(
                            color: themeData.colorScheme.onSurface
                                .withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${formatCurrency(item.totalPrice)} VNĐ',
                      style: TextStyle(
                        color: themeData.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalSection(BuildContext context) {
    final themeData = Theme.of(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: themeData.cardColor,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: themeData.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tóm tắt thanh toán',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPriceRow(context, 'Tổng tiền sản phẩm:', order.orderTotal),
            if (order.discount != null && order.discount! > 0)
              _buildPriceRow(context, 'Giảm giá:', order.discount!,
                  valueColor: Colors.green.shade600, showNegative: true),
            _buildShippingRow(context, 'Phí vận chuyển:',
                'Liên hệ trực tiếp để biết chi tiết'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                  color: themeData.colorScheme.onSurface.withOpacity(0.2)),
            ),
            _buildPriceRow(
              context,
              'Tổng thanh toán:',
              order.discount != null
                  ? order.orderTotal - order.discount!
                  : order.orderTotal,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, double value,
      {bool isBold = false, Color? valueColor, bool showNegative = false}) {
    final themeData = Theme.of(context);
    final formattedValue = showNegative
        ? '-${formatCurrency(value)} VNĐ'
        : '${formatCurrency(value)} VNĐ';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold
                  ? themeData.colorScheme.onSurface
                  : themeData.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const Spacer(),
          Text(
            formattedValue,
            style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ??
                  (isBold
                      ? themeData.colorScheme.primary
                      : themeData.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingRow(BuildContext context, String label, String value) {
    final themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: themeData.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final themeData = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to chat screen
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ChatScreen()));
          },
          icon: const Icon(Icons.support_agent),
          label: const Text('Liên hệ hỗ trợ'),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeData.colorScheme.primary,
            foregroundColor: themeData.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
        ),
      ],
    );
  }
}
