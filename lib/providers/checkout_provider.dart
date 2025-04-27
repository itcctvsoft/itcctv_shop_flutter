import 'package:flutter/material.dart';
import '../repositories/checkout_repository.dart';
import '../models/checkout.dart';
import '../constants/pref_data.dart';

class CheckoutProvider extends ChangeNotifier {
  final CheckoutRepository _checkoutRepository = CheckoutRepository();

  CheckoutResponse? _checkoutResponse;
  bool _isLoading = false;
  String? _errorMessage;

  CheckoutResponse? get checkoutResponse => _checkoutResponse;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> loadCheckoutData() async {
    _setLoading(true);
    _setError(null);
    final token = await PrefData.getToken();

    if (token == null) {
      _setError("Token không hợp lệ. Vui lòng đăng nhập lại.");
      _setLoading(false);
      return;
    }

    try {
      _checkoutResponse = await _checkoutRepository.fetchCheckoutData(token);
      print("Dữ liệu checkout tải thành công: ${_checkoutResponse?.data.products.length} sản phẩm.");
    } catch (e) {
      _setError("Lỗi khi tải dữ liệu checkout: ${e.toString()}");
      print("Lỗi khi tải dữ liệu checkout: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }
}