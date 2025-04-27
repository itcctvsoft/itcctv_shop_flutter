class PaymentTransaction {
  final int? id;
  final String orderId;
  final String? code;
  final double price;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentTransaction({
    this.id,
    required this.orderId,
    this.code,
    required this.price,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['transaction_id'],
      orderId: json['order_id'].toString(),
      code: json['code'],
      price: double.parse(json['price'].toString()),
      status: json['payment_status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool get isPaid => status.toLowerCase() == 'paid';

  bool get isUnpaid => status.toLowerCase() == 'unpaid';
}
