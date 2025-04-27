import 'dart:convert';
import 'package:flutter/foundation.dart';

class Order {
  final int id;
  final int customerId;
  final String orderCode;
  final String orderDate;
  final double orderTotal;
  final String paymentStatus;
  final String orderStatus;
  final List<OrderDetail> details;
  final double? discount;
  final bool isPaid;
  final double? paidAmount;
  final double? remainingAmount;

  Order({
    required this.id,
    required this.customerId,
    required this.orderCode,
    required this.orderDate,
    required this.orderTotal,
    required this.paymentStatus,
    required this.orderStatus,
    required this.details,
    this.discount,
    required this.isPaid,
    this.paidAmount,
    this.remainingAmount,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderDetail> orderDetails = [];
    if (json['details'] != null) {
      orderDetails = List<OrderDetail>.from(
        (json['details'] as List).map(
          (detail) => OrderDetail.fromJson(detail),
        ),
      );
    }

    // Parse order total from final_amount
    double parsedTotal = 0.0;
    try {
      if (json['final_amount'] != null) {
        if (json['final_amount'] is num) {
          parsedTotal = (json['final_amount'] as num).toDouble();
        } else {
          var totalStr = json['final_amount'].toString().trim();
          totalStr = totalStr.replaceAll(RegExp(r'[^\d.]'), '');
          if (totalStr.isNotEmpty) {
            parsedTotal = double.parse(totalStr);
          }
        }
      } else if (json['total'] != null) {
        if (json['total'] is num) {
          parsedTotal = (json['total'] as num).toDouble();
        } else {
          var totalStr = json['total'].toString().trim();
          totalStr = totalStr.replaceAll(RegExp(r'[^\d.]'), '');
          if (totalStr.isNotEmpty) {
            parsedTotal = double.parse(totalStr);
          }
        }
      }
    } catch (e) {
      print('Error parsing order total: $e');
    }

    // Nếu tổng tiền vẫn là 0 nhưng có chi tiết đơn hàng, tính tổng từ chi tiết
    if (parsedTotal == 0.0 && orderDetails.isNotEmpty) {
      parsedTotal =
          orderDetails.fold(0.0, (sum, detail) => sum + detail.totalPrice);
      print('Calculated total from details: $parsedTotal');
    }

    // Parse discount amount if available
    double? discountAmount;
    if (json['discount_amount'] != null) {
      try {
        if (json['discount_amount'] is num) {
          discountAmount = (json['discount_amount'] as num).toDouble();
        } else {
          var discountStr = json['discount_amount'].toString().trim();
          discountStr = discountStr.replaceAll(RegExp(r'[^\d.]'), '');
          if (discountStr.isNotEmpty) {
            discountAmount = double.parse(discountStr);
          }
        }
      } catch (e) {
        print('Error parsing discount amount: $e');
      }
    }

    // Xử lý thông tin thanh toán từ payment_info
    String paymentStatus = 'Chưa thanh toán';
    bool isPaid = false;
    double? paidAmount;
    double? remainingAmount;

    if (json['payment_info'] != null) {
      // Lấy trạng thái thanh toán từ payment_info.status_text
      paymentStatus = json['payment_info']['status_text'] ?? 'Chưa thanh toán';

      // Lấy trạng thái đã thanh toán từ payment_info.is_paid
      isPaid = json['payment_info']['is_paid'] == true ||
          json['payment_info']['is_paid'] == 1 ||
          json['payment_info']['is_paid'] == "1";

      // Parse số tiền đã thanh toán và còn lại
      if (json['payment_info']['paid_amount'] != null) {
        if (json['payment_info']['paid_amount'] is num) {
          paidAmount = (json['payment_info']['paid_amount'] as num).toDouble();
        } else {
          try {
            paidAmount =
                double.parse(json['payment_info']['paid_amount'].toString());
          } catch (e) {
            print('Error parsing paid amount: $e');
          }
        }
      }

      if (json['payment_info']['remaining_amount'] != null) {
        if (json['payment_info']['remaining_amount'] is num) {
          remainingAmount =
              (json['payment_info']['remaining_amount'] as num).toDouble();
        } else {
          try {
            remainingAmount = double.parse(
                json['payment_info']['remaining_amount'].toString());
          } catch (e) {
            print('Error parsing remaining amount: $e');
          }
        }
      }
    } else {
      // Xử lý theo cách cũ nếu không có payment_info
      paymentStatus = json['payment_status'] ?? 'Chưa thanh toán';
      isPaid = json['is_paid'] == 1 ||
          json['is_paid'] == true ||
          json['is_paid'] == "1" ||
          paymentStatus.toLowerCase().contains('đã thanh toán');
    }

    print(
        'Payment info - Status: $paymentStatus, IsPaid: $isPaid, Paid: $paidAmount, Remaining: $remainingAmount');

    return Order(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      customerId: json['customer_id'] is int
          ? json['customer_id']
          : int.tryParse(json['customer_id'].toString()) ?? 0,
      orderCode: json['code'] ?? '',
      orderDate: json['created_at'] ?? '',
      orderTotal: parsedTotal,
      paymentStatus: paymentStatus,
      orderStatus: json['status'] ?? 'Đang xử lý',
      details: orderDetails,
      discount: discountAmount,
      isPaid: isPaid,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'code': orderCode,
        'created_at': orderDate,
        'final_amount': orderTotal,
        'payment_info': {
          'status_text': paymentStatus,
          'is_paid': isPaid,
          'paid_amount': paidAmount,
          'remaining_amount': remainingAmount,
        },
        'status': orderStatus,
        'details': details.map((detail) => detail.toJson()).toList(),
        'discount_amount': discount,
      };
}

class OrderDetail {
  final int id;
  final int orderId;
  final int productId;
  final String productTitle;
  final String productPhoto;
  final int quantity;
  final double price;
  final double totalPrice;
  final bool isPaid;

  OrderDetail({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productTitle,
    required this.productPhoto,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    this.isPaid = false,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    // In ra dữ liệu gốc để debug
    print(
        'OrderDetail raw data: ${json['price']} and total: ${json['total_price']}');

    double parsedPrice = 0.0;
    try {
      if (json['price'] != null) {
        // Thử chuyển đổi theo nhiều cách khác nhau
        if (json['price'] is num) {
          parsedPrice = (json['price'] as num).toDouble();
        } else {
          var priceStr = json['price'].toString().trim();
          // Loại bỏ các ký tự không phải số và dấu thập phân
          priceStr = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
          if (priceStr.isNotEmpty) {
            parsedPrice = double.parse(priceStr);
          }
        }
      }
    } catch (e) {
      print('Error parsing price: $e');
    }

    double parsedTotalPrice = 0.0;
    try {
      if (json['total_price'] != null) {
        // Thử chuyển đổi theo nhiều cách khác nhau
        if (json['total_price'] is num) {
          parsedTotalPrice = (json['total_price'] as num).toDouble();
        } else {
          var totalStr = json['total_price'].toString().trim();
          // Loại bỏ các ký tự không phải số và dấu thập phân
          totalStr = totalStr.replaceAll(RegExp(r'[^\d.]'), '');
          if (totalStr.isNotEmpty) {
            parsedTotalPrice = double.parse(totalStr);
          }
        }
      }
    } catch (e) {
      print('Error parsing total price: $e');
    }

    // Tính toán giá trị tổng nếu giá đơn vị và số lượng hợp lệ nhưng tổng bằng 0
    int quantity = int.tryParse(json['quantity'].toString()) ?? 0;
    if (parsedTotalPrice == 0.0 && parsedPrice > 0.0 && quantity > 0) {
      parsedTotalPrice = parsedPrice * quantity;
    }

    // Tính toán giá đơn vị nếu tổng và số lượng hợp lệ nhưng giá đơn vị bằng 0
    if (parsedPrice == 0.0 && parsedTotalPrice > 0.0 && quantity > 0) {
      parsedPrice = parsedTotalPrice / quantity;
    }

    // Xử lý trạng thái thanh toán
    bool isPaid = false;
    if (json['is_paid'] != null) {
      isPaid = json['is_paid'] == true ||
          json['is_paid'] == 1 ||
          json['is_paid'] == "1";
    }

    print(
        'Parsed price: $parsedPrice, total: $parsedTotalPrice, quantity: $quantity, isPaid: $isPaid');

    return OrderDetail(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      orderId: json['wo_id'] is int
          ? json['wo_id']
          : int.tryParse(json['wo_id'].toString()) ?? 0,
      productId: json['product_id'] is int
          ? json['product_id']
          : int.tryParse(json['product_id'].toString()) ?? 0,
      productTitle: json['title'] ?? 'Sản phẩm không tên',
      productPhoto: json['photo'] ?? '',
      quantity: quantity,
      price: parsedPrice,
      totalPrice: parsedTotalPrice,
      isPaid: isPaid,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wo_id': orderId,
        'product_id': productId,
        'title': productTitle,
        'photo': productPhoto,
        'quantity': quantity,
        'price': price,
        'total_price': totalPrice,
        'is_paid': isPaid,
      };
}
