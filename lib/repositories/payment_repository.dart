import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/models/payment_transaction.dart';
import 'package:shoplite/constants/pref_data.dart';

class PaymentRepository {
  Future<String?> createVNPayPayment(double amount, String orderId) async {
    try {
      // Đảm bảo orderId không có tiền tố 'ORD'
      String cleanOrderId = orderId;
      if (orderId.startsWith("ORD")) {
        cleanOrderId = orderId.substring(3);
        print(
            "⚠️ Đã loại bỏ tiền tố 'ORD' khỏi orderId: $orderId -> $cleanOrderId");
      }

      final Uri url = Uri.parse(api_create_vnpay_payment);
      print("🔹 Bắt đầu quá trình thanh toán VNPay trực tiếp");
      print("🔹 Gửi yêu cầu đến VNPay API: $url");
      print("🔹 Số tiền: $amount");
      print("🔹 Mã đơn hàng (đã xử lý): $cleanOrderId");

      // Tạo và log JSON payload trước khi gửi
      final payload = {"amount": amount, "order_id": cleanOrderId};
      print("📦 Payload JSON: ${jsonEncode(payload)}");

      final response = await http.post(
        url,
        body: jsonEncode(payload),
        headers: {"Content-Type": "application/json"},
      );

      print("🔹 Trạng thái phản hồi từ VNPay: ${response.statusCode}");
      print("🔹 Dữ liệu phản hồi từ VNPay: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data.containsKey("payment_url")) {
          print("✅ Lấy được payment URL: ${data["payment_url"]}");
          return data["payment_url"];
        } else {
          final message = data['message'] ?? 'Không xác định';
          final errorDetail = data['error_detail'] ?? '';
          print("⚠️ Lỗi từ server: $message");
          if (errorDetail.isNotEmpty) {
            print("⚠️ Chi tiết lỗi: $errorDetail");
          }
          return null;
        }
      } else {
        print("⚠️ VNPay API trả về lỗi: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Lỗi trong createVNPayPayment: $e");
      return null;
    }
  }

  Future<PaymentTransaction?> getPaymentStatus(String orderId) async {
    try {
      // Đảm bảo orderId không có tiền tố
      String cleanOrderId = orderId;
      if (orderId.startsWith("ORD")) {
        cleanOrderId = orderId.substring(3);
        print(
            "⚠️ Đã loại bỏ tiền tố 'ORD' khỏi orderId: $orderId -> $cleanOrderId");
      }

      // Nếu orderId có tiền tố MEM, cũng cần xử lý
      if (cleanOrderId.startsWith("MEM")) {
        print(
            "⚠️ Đã phát hiện orderId có tiền tố MEM, giữ nguyên để API xử lý: $cleanOrderId");
      }

      final String apiEndpoint = api_check_vnpay_status + '/$cleanOrderId';
      final Uri url = Uri.parse(apiEndpoint);
      print("🔹 Kiểm tra trạng thái thanh toán cho đơn hàng: $cleanOrderId");
      print("🔹 URL: $apiEndpoint");

      final response = await http.get(url);
      print("🔹 Trạng thái phản hồi: ${response.statusCode}");
      print("🔹 Dữ liệu phản hồi: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data.containsKey('data')) {
          print("✅ Lấy được thông tin thanh toán");
          final transaction = PaymentTransaction.fromJson(data['data']);
          print("✅ Trạng thái thanh toán: ${transaction.status}");
          print("✅ Đã thanh toán: ${transaction.isPaid}");
          return transaction;
        } else {
          final message = data['message'] ?? 'Không có thông tin';
          print("⚠️ Không tìm thấy thông tin thanh toán: $message");
          return null;
        }
      } else if (response.statusCode == 404) {
        print("⚠️ Không tìm thấy giao dịch thanh toán cho đơn hàng này");
        return null;
      } else {
        print("❌ Lỗi khi kiểm tra trạng thái: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Lỗi trong getPaymentStatus: $e");
      return null;
    }
  }

  // Phương thức mới để chờ và kiểm tra trạng thái thanh toán nhiều lần
  Future<PaymentTransaction?> waitForPaymentConfirmation(String orderId,
      {int maxAttempts = 5, int delaySeconds = 2}) async {
    print("🔄 Bắt đầu theo dõi trạng thái thanh toán cho đơn hàng: $orderId");

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      print("🔄 Lần kiểm tra #$attempt/$maxAttempts");

      // Thử kiểm tra bằng cả hai phương thức
      PaymentTransaction? transaction = await getPaymentStatus(orderId);

      // Nếu không tìm thấy bằng orderId, thử kiểm tra bằng mã giao dịch
      if (transaction == null) {
        transaction = await getPaymentStatusByCode(orderId);
      }

      if (transaction != null) {
        print("✅ Có thông tin giao dịch: status=${transaction.status}");

        // Nếu trạng thái đã là Paid, trả về ngay
        if (transaction.isPaid) {
          print("✅ Thanh toán đã được xác nhận thành công!");
          return transaction;
        }

        // Nếu là lần kiểm tra cuối cùng, trả về dù chưa paid
        if (attempt == maxAttempts) {
          print("⚠️ Đã hết số lần thử, thanh toán vẫn chưa được xác nhận.");
          return transaction;
        }
      } else if (attempt == maxAttempts) {
        // Nếu là lần kiểm tra cuối cùng và không có thông tin, trả về null
        print("❌ Đã hết số lần thử, không tìm thấy thông tin giao dịch.");
        return null;
      }

      // Chờ trước khi kiểm tra lại
      if (attempt < maxAttempts) {
        print("⏱️ Chờ $delaySeconds giây trước khi kiểm tra lại...");
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    return null;
  }

  // Phương thức mới để kiểm tra trạng thái thanh toán bằng mã giao dịch
  Future<PaymentTransaction?> getPaymentStatusByCode(String code) async {
    try {
      // Đảm bảo code có tiền tố MEM
      String transactionCode = code;
      if (!transactionCode.startsWith("MEM")) {
        transactionCode = "MEM$transactionCode";
        print(
            "🔹 Thêm tiền tố 'MEM' cho mã giao dịch: $code -> $transactionCode");
      }

      final String apiEndpoint = api_check_vnpay_status + '/$transactionCode';
      final Uri url = Uri.parse(apiEndpoint);
      print(
          "🔹 Kiểm tra trạng thái thanh toán cho mã giao dịch: $transactionCode");
      print("🔹 URL: $apiEndpoint");

      final response = await http.get(url);
      print("🔹 Trạng thái phản hồi: ${response.statusCode}");
      print("🔹 Dữ liệu phản hồi: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data.containsKey('data')) {
          print("✅ Lấy được thông tin thanh toán qua mã giao dịch");
          final transaction = PaymentTransaction.fromJson(data['data']);
          print("✅ Trạng thái thanh toán: ${transaction.status}");
          print("✅ Đã thanh toán: ${transaction.isPaid}");
          return transaction;
        } else {
          final message = data['message'] ?? 'Không có thông tin';
          print(
              "⚠️ Không tìm thấy thông tin thanh toán qua mã giao dịch: $message");
          return null;
        }
      } else if (response.statusCode == 404) {
        print("⚠️ Không tìm thấy giao dịch thanh toán cho mã giao dịch này");
        return null;
      } else {
        print(
            "❌ Lỗi khi kiểm tra trạng thái qua mã giao dịch: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Lỗi trong getPaymentStatusByCode: $e");
      return null;
    }
  }

  // Phương thức mới xử lý kết quả thanh toán VNPay trực tiếp
  Future<PaymentTransaction> handleVNPayDirectResponse(
      String orderId, double amount) async {
    try {
      print(
          "✅ Xử lý kết quả thanh toán VNPay trực tiếp: orderId=$orderId, amount=$amount");

      // Tạo đối tượng PaymentTransaction với trạng thái thành công
      return PaymentTransaction(
        id: null, // ID sẽ do server tạo sau khi đồng bộ
        orderId: orderId,
        code: "VNPAY_DIRECT",
        price: amount,
        status: "Paid",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print("❌ Lỗi xử lý kết quả thanh toán VNPay trực tiếp: $e");

      // Trả về transaction với trạng thái mặc định là Paid
      return PaymentTransaction(
        orderId: orderId,
        price: amount,
        status: "Paid",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Phương thức mới để cập nhật trạng thái thanh toán của đơn hàng
  Future<bool> updateOrderPaymentStatus(int orderId, bool isPaid) async {
    try {
      // Lấy token xác thực
      final token = await PrefData.getToken();
      if (token == null) {
        print("❌ Không có token: không thể cập nhật trạng thái thanh toán");
        return false;
      }

      final Uri url = Uri.parse(api_update_payment_status);
      print("🔹 Cập nhật trạng thái thanh toán cho đơn hàng #$orderId");
      print(
          "🔹 Trạng thái thanh toán mới: ${isPaid ? 'Đã thanh toán' : 'Chưa thanh toán'}");

      // Tạo request body - chỉ gửi các trường cần thiết mà không bao gồm trường status
      // Backend sẽ tự xử lý logic status theo business rules của nó
      final body = {
        'order_id': orderId,
        'is_paid': isPaid ? 1 : 0,
        // Bỏ trường status để backend tự xử lý
      };

      // Tạo headers với token xác thực
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      print("📦 Payload JSON: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print("🔹 Trạng thái phản hồi: ${response.statusCode}");
      print("🔹 Dữ liệu phản hồi: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          print("✅ Cập nhật trạng thái thanh toán thành công");
          return true;
        } else {
          final message = data['message'] ?? 'Không xác định';
          print("⚠️ Lỗi từ server: $message");
          return false;
        }
      } else {
        print("❌ API trả về lỗi: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Lỗi trong updateOrderPaymentStatus: $e");
      return false;
    }
  }
}
