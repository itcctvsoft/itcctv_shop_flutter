import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/apilist.dart';

class PaymentRepository {
  // Tạo URL thanh toán VNPay
  Future<String?> createVNPayPayment(double amount, String orderId) async {
    try {
      // Lấy token từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print("❌ Không có token để tạo thanh toán VNPay");
        return null;
      }

      // Tạo body request
      final body = {
        'amount': amount.round().toString(),
        'orderInfo': 'Thanh toan don hang $orderId',
        'orderId': orderId
      };

      print("🔹 API Request tạo thanh toán VNPay: $body");

      // Gửi request đến API
      final response = await http.post(
        Uri.parse(api_create_vnpay_payment),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print("🔹 API Response: [${response.statusCode}] ${response.body}");

      // Kiểm tra response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['payment_url'] != null) {
          return data['payment_url'].toString();
        }
      }

      return null;
    } catch (e) {
      print("❌ Lỗi tạo thanh toán VNPay: $e");
      return null;
    }
  }
}
