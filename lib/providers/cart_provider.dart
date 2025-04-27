import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/cart_repository.dart';
import 'package:shoplite/models/Cart.dart';

class CartProvider extends ChangeNotifier {
  final CartRepository _cartRepository = CartRepository();

  List<CartItem> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cập nhật trạng thái loading
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Cập nhật thông báo lỗi
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Lấy danh sách giỏ hàng
  Future<void> fetchCartItems(String token) async {
    _setLoading(true);
    _setError(null);

    try {
      print("Đang tải danh sách giỏ hàng với token: $token...");
      _cartItems = await _cartRepository.getCartItems(token);
      print(
          "Danh sách giỏ hàng đã tải thành công: ${_cartItems.map((item) => item.title).toList()}");
    } catch (e) {
      _setError("Không thể tải danh sách giỏ hàng: ${e.toString()}");
      print("Lỗi khi tải danh sách giỏ hàng: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  // Thêm sản phẩm vào giỏ hàng
  Future<void> addToCart(String token, int productId, int quantity) async {
    _setLoading(true);
    _setError(null);

    try {
      print(
          "Đang thêm sản phẩm vào giỏ hàng: Product ID $productId, Quantity $quantity...");
      await _cartRepository.addToCart(token, productId, quantity);
      print("Thêm sản phẩm vào giỏ hàng thành công!");
      // Sau khi thêm, cập nhật lại danh sách giỏ hàng
      await fetchCartItems(token);
    } catch (e) {
      _setError("Không thể thêm sản phẩm vào giỏ hàng: ${e.toString()}");
      print("Lỗi khi thêm sản phẩm vào giỏ hàng: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  // Xóa sản phẩm khỏi giỏ hàng
  Future<void> removeFromCart(String token, int productId) async {
    _setLoading(true);
    _setError(null);

    try {
      print("Đang xóa sản phẩm khỏi giỏ hàng: Product ID $productId...");
      await _cartRepository.removeFromCart(token, productId);
      print("Xóa sản phẩm khỏi giỏ hàng thành công!");

      // Sau khi xóa, cập nhật lại danh sách giỏ hàng
      await fetchCartItems(token);
    } catch (e) {
      final errorMessage =
          "Không thể xóa sản phẩm khỏi giỏ hàng: ${e.toString()}";
      _setError(errorMessage);
      print(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Kiểm tra nếu giỏ hàng trống
  bool isCartEmpty() {
    return _cartItems.isEmpty;
  }

  // Tính tổng giá trị giỏ hàng
  double getCartTotal() {
    return _cartItems.fold(
      0.0,
      (total, item) => total + (item.price * item.quantity),
    );
  }

// Cập nhật giỏ hàng
  Future<void> updateCart(String token, List<CartItem> updatedItems) async {
    _setLoading(true);
    _setError(null);

    try {
      print("Đang cập nhật giỏ hàng...");
      for (var item in updatedItems) {
        // Sử dụng hàm updateCartItem để cập nhật từng sản phẩm
        await _cartRepository.updateCartItem(token, item.id, item.quantity);
      }

      // Sau khi cập nhật xong, tải lại danh sách giỏ hàng
      await fetchCartItems(token);
      print("Cập nhật giỏ hàng thành công!");
    } catch (e) {
      _setError("Không thể cập nhật giỏ hàng: ${e.toString()}");
      print("Lỗi khi cập nhật giỏ hàng: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  // Log thông tin giỏ hàng
  void logCartItems() {
    print("Danh sách sản phẩm trong giỏ hàng:");
    for (var item in _cartItems) {
      print("- ${item.title}: ${item.quantity} x ${item.price}");
    }
  }
}

// Riverpod provider to access CartProvider globally
final cartProvider = ChangeNotifierProvider<CartProvider>((ref) {
  return CartProvider();
});
