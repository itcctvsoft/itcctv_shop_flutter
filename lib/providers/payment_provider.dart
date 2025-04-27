import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/models/payment_transaction.dart';
import 'package:shoplite/repositories/payment_repository.dart';

class PaymentState {
  final bool isLoading;
  final String paymentUrl;
  final String? errorMessage;
  final PaymentTransaction? transaction;
  final String? orderId;

  PaymentState({
    this.isLoading = false,
    this.paymentUrl = "",
    this.errorMessage,
    this.transaction,
    this.orderId,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? paymentUrl,
    String? errorMessage,
    PaymentTransaction? transaction,
    String? orderId,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      errorMessage: errorMessage,
      transaction: transaction ?? this.transaction,
      orderId: orderId ?? this.orderId,
    );
  }

  bool get isPaid => transaction?.isPaid ?? false;
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentRepository _repository;

  PaymentNotifier(this._repository) : super(PaymentState());

  Future<void> generateVNPayUrl(double amount) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final String orderId = DateTime.now().millisecondsSinceEpoch.toString();
      print(
          "🔹 Gửi yêu cầu thanh toán VNPay: số tiền $amount, mã đơn hàng $orderId");

      final paymentUrl = await _repository.createVNPayPayment(amount, orderId);

      if (paymentUrl != null) {
        print("✅ Lấy được URL thanh toán: $paymentUrl");
        state = state.copyWith(paymentUrl: paymentUrl, orderId: orderId);
      } else {
        print("❌ Không nhận được URL thanh toán");
        state =
            state.copyWith(errorMessage: "Không thể tạo liên kết thanh toán");
      }
    } catch (e) {
      print("❌ Exception: $e");
      state = state.copyWith(errorMessage: "Lỗi kết nối: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> checkPaymentStatus(String orderId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final transaction = await _repository.getPaymentStatus(orderId);
      if (transaction != null) {
        print("✅ Thanh toán có trạng thái: ${transaction.status}");
        state = state.copyWith(transaction: transaction, orderId: orderId);
      } else {
        print("⚠️ Không tìm thấy thông tin thanh toán");
        state = state.copyWith(
            errorMessage:
                "Không thể lấy thông tin thanh toán cho đơn hàng này");
      }
    } catch (e) {
      print("❌ Lỗi khi kiểm tra trạng thái thanh toán: $e");
      state = state.copyWith(
          errorMessage: "Lỗi khi kiểm tra trạng thái thanh toán");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void resetPayment() {
    state = PaymentState();
  }

  // Phương thức mới để cập nhật kết quả giao dịch trực tiếp
  void setTransactionResult(PaymentTransaction transaction) {
    print(
        "✅ Cập nhật kết quả giao dịch: ${transaction.status}, isPaid=${transaction.isPaid}");
    state = state.copyWith(
      transaction: transaction,
      orderId: transaction.orderId,
    );
  }

  // Phương thức mới để đánh dấu thanh toán thành công bằng orderId
  void setTransactionSuccessfulByOrderId(String orderId) {
    print("✅ Đánh dấu thanh toán thành công cho đơn hàng: $orderId");

    // Tạo transaction đơn giản - sẽ được thay thế bởi phương thức setTransactionResult
    final transaction = PaymentTransaction(
      orderId: orderId,
      price: 0, // Giá trị mặc định
      status: 'Paid',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Cập nhật state
    state = state.copyWith(
      transaction: transaction,
      orderId: orderId,
    );
  }
}

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(PaymentRepository());
});
