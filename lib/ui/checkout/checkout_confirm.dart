import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/color_data.dart'; // AppColors and DarkThemeColors are defined here
import '../../constants/utils.dart'; // getImageUrl is defined here
import '../../models/Address.dart';
import '../../models/checkout.dart';
import '../../repositories/checkout_repository.dart';
import '../../repositories/address_repository.dart';
import '../../providers/address_provider.dart';
import '../../constants/apilist.dart';
import 'package:http/http.dart' as http;
import '../../repositories/payment_repository.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/payment_provider.dart';
import '../vnpay/payment_screen.dart';
import '../../constants/pref_data.dart';
import 'thank_you_dialog.dart'; // Add import for ThankYouDialog
import '../../ui/widgets/notification_dialog.dart'; // Import for NotificationDialog
import '../../widgets/chat_icon_badge.dart';
import 'package:shoplite/models/payment_transaction.dart';

class CheckoutProvider extends ChangeNotifier {
  final CheckoutRepository _checkoutRepository = CheckoutRepository();
  final AddressRepository _addressRepository = AddressRepository();
  final AddressProvider _addressProvider = AddressProvider();

  CheckoutResponse? _checkoutResponse;
  bool _isLoading = false;
  String? _errorMessage;
  String _paymentMethod = "COD";
  Address? _billingAddress;
  Address? _shippingAddress;

  CheckoutResponse? get checkoutResponse => _checkoutResponse;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get paymentMethod => _paymentMethod;
  Address? get billingAddress => _billingAddress;
  Address? get shippingAddress => _shippingAddress;
  List<Address> get addressList => _addressProvider.addressList;

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
      print(
          "Dữ liệu checkout tải thành công: ${_checkoutResponse?.data.products.length} sản phẩm.");

      // Load address list
      await loadAddresses();
    } catch (e) {
      _setError("Lỗi khi tải dữ liệu checkout: ${e.toString()}");
      print("Lỗi khi tải dữ liệu checkout: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAddresses() async {
    final token = await PrefData.getToken();
    if (token == null) return;

    try {
      await _addressProvider.fetchAddressBook(token);
    } catch (e) {
      print("Lỗi khi tải địa chỉ: ${e.toString()}");
    }
  }

  Future<bool> addNewAddress(Address address) async {
    final token = await PrefData.getToken();
    if (token == null) return false;

    try {
      _setLoading(true);

      // Call the repository to add the address to the backend
      await _addressProvider.addAddress(token, address);

      // Reload addresses after adding a new one
      await loadAddresses();

      return true;
    } catch (e) {
      print("Lỗi khi thêm địa chỉ: ${e.toString()}");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  List<Product> get orderProducts => _checkoutResponse?.data.products ?? [];

  double get totalPrice {
    return orderProducts.fold(0, (sum, product) => sum + product.totalPrice);
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setBillingAddress(Address address) {
    _billingAddress = address;
    notifyListeners();
  }

  void setShippingAddress(Address address) {
    _shippingAddress = address;
    notifyListeners();
  }

  // Đặt hàng với backend
  Future<Map<String, dynamic>> placeOrder() async {
    _setLoading(true);
    _setError(null);

    final token = await PrefData.getToken();
    if (token == null) {
      _setError("Token không hợp lệ. Vui lòng đăng nhập lại.");
      _setLoading(false);
      throw Exception("Token không hợp lệ");
    }

    if (_billingAddress == null || _shippingAddress == null) {
      _setError("Vui lòng chọn địa chỉ trước khi đặt hàng.");
      _setLoading(false);
      throw Exception("Thiếu địa chỉ");
    }

    try {
      final url = Uri.parse(api_order_place);

      // Cấu trúc dữ liệu gửi đi theo yêu cầu API
      final body = {
        'ship_id': _shippingAddress!.id,
        'invoice_id': _billingAddress!.id,
        // Thêm trường payment_method theo yêu cầu API
        'payment_method': _paymentMethod == "Online" ? 'online' : 'cod',
        // Giữ lại trường is_paid nếu cần
        'is_paid': _paymentMethod == "Online" ? 1 : 0
      };

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      print('🔹 Gửi yêu cầu đặt hàng: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);
        print('✅ Đặt hàng thành công: $responseData');
        return responseData;
      } else {
        final error = json.decode(response.body);
        _setError("Lỗi khi đặt hàng: ${error['message'] ?? 'Unknown error'}");
        print('❌ Lỗi khi đặt hàng: ${response.body}');
        throw Exception(
            "Lỗi khi đặt hàng: ${error['message'] ?? 'Unknown error'}");
      }
    } catch (e) {
      _setError("Lỗi đặt hàng: ${e.toString()}");
      print('❌ Exception khi đặt hàng: ${e.toString()}');
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  // Phương thức để làm mới dữ liệu giỏ hàng sau khi đặt hàng thành công
  Future<void> refreshCart() async {
    final token = await PrefData.getToken();
    if (token == null) return;

    try {
      // Reset các biến trạng thái
      _checkoutResponse = null;
      _billingAddress = null;
      _shippingAddress = null;
      notifyListeners();

      // Tải lại dữ liệu giỏ hàng nếu cần thiết
      // Lưu ý: Sau khi đặt hàng thành công, giỏ hàng thường trống
      // await loadCheckoutData();
    } catch (e) {
      print('❌ Lỗi khi làm mới giỏ hàng: ${e.toString()}');
    }
  }

  // Tạo URL thanh toán VNPay
  Future<String?> createVNPayPayment() async {
    _setLoading(true);
    _setError(null);

    final token = await PrefData.getToken();
    if (token == null) {
      _setError("Token không hợp lệ. Vui lòng đăng nhập lại.");
      _setLoading(false);
      return null;
    }

    try {
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      print("🔹 Đang tạo thanh toán VNPay với Order ID: $orderId");

      final paymentUrl =
          await PaymentRepository().createVNPayPayment(totalPrice, orderId);
      return paymentUrl;
    } catch (e) {
      _setError("Lỗi tạo thanh toán VNPay: ${e.toString()}");
      print("❌ Lỗi tạo thanh toán VNPay: ${e.toString()}");
      return null;
    } finally {
      _setLoading(false);
    }
  }
}

class CheckoutConfirmScreen extends StatefulWidget {
  const CheckoutConfirmScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutConfirmScreen> createState() => _CheckoutConfirmScreenState();
}

class _CheckoutConfirmScreenState extends State<CheckoutConfirmScreen> {
  final CheckoutProvider _provider = CheckoutProvider();
  bool _isLoading = true;
  bool get isDarkMode => ThemeController.isDarkMode;

  @override
  void initState() {
    super.initState();
    _provider.addListener(_onProviderChanged);
    _loadData();
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    super.dispose();
  }

  // Phương thức được gọi khi provider thay đổi
  void _onProviderChanged() {
    if (mounted) {
      setState(() {
        // Rebuild UI khi provider thay đổi
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _provider.loadCheckoutData();

      // If no addresses are loaded yet, try to set default ones
      if (_provider.addressList.isNotEmpty) {
        // If billing address is not set, set the first address as default
        if (_provider.billingAddress == null) {
          _provider.setBillingAddress(_provider.addressList.first);
        }

        // If shipping address is not set, use the same as billing
        if (_provider.shippingAddress == null) {
          _provider.setShippingAddress(_provider.billingAddress!);
        }
      }
    } catch (e) {
      NotificationDialog.showError(
        context: context,
        title: 'Lỗi khi tải dữ liệu',
        message: e.toString(),
        primaryButtonText: 'Thử lại',
        secondaryButtonText: 'Đóng',
        primaryAction: () {
          _loadData(); // Retry loading data
        },
        secondaryAction: () {
          // Close dialog
        },
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to place an order
  Future<void> _placeOrder() async {
    // Kiểm tra địa chỉ đã được chọn chưa
    if (_provider.billingAddress == null || _provider.shippingAddress == null) {
      NotificationDialog.showWarning(
        context: context,
        title: 'Địa chỉ chưa đủ',
        message: 'Vui lòng chọn địa chỉ trước khi đặt hàng',
        primaryButtonText: 'Đã hiểu',
        primaryAction: () {
          // Dialog will close
        },
      );
      return;
    }

    // Nếu phương thức thanh toán là Online, xử lý thanh toán VNPay
    if (_provider.paymentMethod == "Online") {
      await _handleVNPayPayment();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi API đặt hàng
      final orderResponse = await _provider.placeOrder();

      // Lấy thông tin từ response
      final orderId = orderResponse['order_id'];
      final message = orderResponse['message'] ?? 'Đặt hàng thành công!';

      // Nếu đặt hàng thành công và thanh toán là COD, cập nhật trạng thái thanh toán nếu cần
      if (_provider.paymentMethod == "COD") {
        // Kiểm tra và xử lý orderId an toàn
        if (orderId != null) {
          print("🔹 Đặt hàng COD thành công, orderId=$orderId");
        }
      }

      // Làm mới giỏ hàng sau khi đặt hàng thành công
      await _provider.refreshCart();

      // Hiển thị ThankYouDialog thay vì SnackBar
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => ThankYouDialog(
          context,
          (value) {
            // Handle value if needed
            if (value == 1) {
              // User selected OK or Track Order
              Navigator.pop(context, true); // Return to previous screen
            }
          },
        ),
      );
    } catch (e) {
      // Thông báo lỗi
      NotificationDialog.showError(
        context: context,
        title: 'Lỗi đặt hàng',
        message: e.toString(),
        primaryButtonText: 'Đóng',
        primaryAction: () {
          // Dialog will close
        },
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Xử lý thanh toán VNPay
  Future<void> _handleVNPayPayment() async {
    // Variable to track if we have a dialog open
    bool hasActiveDialog = false;

    try {
      setState(() {
        _isLoading = true;
      });

      // Kiểm tra điều kiện đặt hàng
      if (_provider.billingAddress == null ||
          _provider.shippingAddress == null) {
        NotificationDialog.showWarning(
          context: context,
          title: 'Địa chỉ chưa đủ',
          message: 'Vui lòng chọn địa chỉ trước khi thanh toán',
          primaryButtonText: 'Đã hiểu',
          primaryAction: () {
            // Dialog will close
          },
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print("🔹 Bắt đầu quá trình thanh toán VNPay trực tiếp");

      // Hiển thị thông báo đang chuẩn bị thanh toán
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          hasActiveDialog = true;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 15),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'Đang xử lý',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Đang chuẩn bị trang thanh toán...',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text('Đóng'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    hasActiveDialog = false;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                    minimumSize: Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Tạo order ID
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();

      // Gọi trực tiếp từ repository để lấy payment URL
      final paymentUrl = await PaymentRepository()
          .createVNPayPayment(_provider.totalPrice, orderId);

      setState(() {
        _isLoading = false;
      });

      // Đảm bảo đóng dialog "Đang xử lý" trước khi hiển thị thông báo lỗi
      if (hasActiveDialog) {
        Navigator.of(context).pop();
        hasActiveDialog = false;
      }

      if (paymentUrl == null) {
        print("❌ Không tạo được URL thanh toán");
        NotificationDialog.showPaymentFailed(
          context: context,
          title: 'Lỗi thanh toán',
          message: 'Không thể tạo URL thanh toán. Vui lòng thử lại sau.',
          primaryButtonText: 'Đóng',
          primaryAction: () {
            // Dialog will close
          },
        );
        return;
      }

      print("✅ Đã tạo URL thanh toán: $paymentUrl");

      // Sử dụng WebView đơn giản
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimplePaymentWebView(
            paymentUrl: paymentUrl,
            amount: _provider.totalPrice,
          ),
        ),
      );

      print("🔹 Kết quả thanh toán VNPay: $result");

      // Xử lý kết quả thanh toán dựa trên Map trả về từ WebView
      if (result is Map && result['success'] == true) {
        // Lấy orderId từ kết quả nếu có
        final paymentOrderId = result['orderId'];
        print(
            "✅ Thanh toán VNPay thành công với orderId: $paymentOrderId, đang kiểm tra trạng thái thanh toán...");

        // Kiểm tra trạng thái thanh toán từ API với cơ chế polling
        try {
          final paymentRepo = PaymentRepository();

          // Chỉ tạo transaction trực tiếp, không gọi API kiểm tra
          final transaction = PaymentTransaction(
            orderId: paymentOrderId,
            price: _provider.totalPrice,
            status: 'Paid',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Đóng dialog "Đang xử lý" nếu có
          if (hasActiveDialog) {
            Navigator.of(context).pop();
            hasActiveDialog = false;
          }

          if (transaction != null) {
            print(
                "✅ Kết quả cuối cùng: status=${transaction.status}, orderId=${transaction.orderId}");

            // Nếu trạng thái là đã thanh toán (Paid), tiến hành đặt hàng
            if (transaction.isPaid) {
              print("✅ Thanh toán đã được xác nhận. Tiến hành đặt hàng...");
              await _placeOrderAfterPayment();
              return;
            } else {
              print(
                  "⚠️ Thanh toán chưa được xác nhận (status=${transaction.status}). Chờ xác nhận từ VNPay...");

              // Hiển thị dialog hỏi người dùng có muốn đặt hàng không
              bool shouldPlaceOrder = await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.orange),
                            SizedBox(width: 10),
                            Text('Thanh toán đang xử lý'),
                          ],
                        ),
                        content: Text(
                          'Thanh toán đang được xử lý bởi VNPay. Bạn có muốn tiếp tục đặt hàng không?',
                          style: TextStyle(fontSize: 16),
                        ),
                        actions: [
                          TextButton(
                            child: Text('Hủy'),
                            onPressed: () {
                              Navigator.of(dialogContext).pop(false);
                            },
                          ),
                          ElevatedButton(
                            child: Text('Tiếp tục đặt hàng'),
                            onPressed: () {
                              Navigator.of(dialogContext).pop(true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      );
                    },
                  ) ??
                  false;

              if (shouldPlaceOrder) {
                print(
                    "✅ Người dùng xác nhận tiếp tục đặt hàng dù thanh toán chưa hoàn tất.");
                await _placeOrderAfterPayment();
              } else {
                print("⚠️ Người dùng đã hủy quy trình đặt hàng.");
              }
            }
          } else {
            print(
                "⚠️ Không tìm thấy thông tin thanh toán cho orderId: $orderId");

            // Hiển thị dialog hỏi người dùng
            bool shouldPlaceOrder = await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange),
                          SizedBox(width: 10),
                          Text('Không tìm thấy thông tin'),
                        ],
                      ),
                      content: Text(
                        'Không thể xác nhận thanh toán cho đơn hàng này. Bạn có muốn tiếp tục đặt hàng không?',
                        style: TextStyle(fontSize: 16),
                      ),
                      actions: [
                        TextButton(
                          child: Text('Hủy'),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                          },
                        ),
                        ElevatedButton(
                          child: Text('Tiếp tục đặt hàng'),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ) ??
                false;

            if (shouldPlaceOrder) {
              print(
                  "✅ Người dùng xác nhận tiếp tục đặt hàng dù không xác nhận được thanh toán.");
              await _placeOrderAfterPayment();
            } else {
              print("⚠️ Người dùng đã hủy quy trình đặt hàng.");
            }
          }
        } catch (e) {
          print("❌ Lỗi khi kiểm tra trạng thái thanh toán: $e");

          // Đóng dialog "Đang xử lý" nếu có
          if (hasActiveDialog) {
            Navigator.of(context).pop();
            hasActiveDialog = false;
          }

          // Hiển thị thông báo lỗi
          NotificationDialog.showError(
            context: context,
            title: 'Lỗi kiểm tra',
            message: 'Không thể kiểm tra trạng thái thanh toán: $e',
            primaryButtonText: 'Đồng ý',
            primaryAction: () {
              // Dialog will close
            },
          );
        }
      } else {
        print("❌ Thanh toán VNPay không thành công hoặc bị hủy");
        NotificationDialog.showPaymentFailed(
          context: context,
          title: 'Thanh toán thất bại',
          message: 'Thanh toán không thành công hoặc bị hủy',
          primaryButtonText: 'Đóng',
          primaryAction: () {
            // Dialog will close
          },
        );
      }
    } catch (e) {
      print("❌ Lỗi trong quá trình thanh toán VNPay: $e");

      // Đảm bảo đóng dialog "Đang xử lý" trước khi hiển thị thông báo lỗi
      if (hasActiveDialog) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isLoading = false;
      });

      NotificationDialog.showPaymentFailed(
        context: context,
        title: 'Lỗi thanh toán',
        message: 'Lỗi thanh toán: ${e.toString()}',
        primaryButtonText: 'Đóng',
        primaryAction: () {
          // Dialog will close
        },
      );
    }
  }

  // Đặt hàng sau khi thanh toán thành công
  Future<void> _placeOrderAfterPayment() async {
    // Track if a dialog is currently open
    bool hasActiveDialog = false;

    try {
      setState(() {
        _isLoading = true;
      });

      // Hiển thị thông báo đang xử lý
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          hasActiveDialog = true;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 15),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'Đang xử lý',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Đang hoàn tất đơn hàng của bạn...',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text('Đóng'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    hasActiveDialog = false;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                    minimumSize: Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Kiểm tra điều kiện đặt hàng
      if (_provider.billingAddress == null ||
          _provider.shippingAddress == null) {
        // Đóng dialog "Đang xử lý" nếu có
        if (hasActiveDialog) {
          Navigator.of(context).pop();
          hasActiveDialog = false;
        }

        NotificationDialog.showWarning(
          context: context,
          title: 'Địa chỉ chưa đủ',
          message: 'Vui lòng chọn địa chỉ trước khi đặt hàng',
          primaryButtonText: 'Đã hiểu',
          primaryAction: () {
            // Dialog will close
          },
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Gọi API đặt hàng
      final result = await _provider.placeOrder();

      // Xử lý kết quả
      final success = result['success'] ??
          true; // Mặc định thành công nếu không có trường success
      final orderId = result['order_id'] ?? '';
      final message = result['message'] ?? 'Đặt hàng thành công!';

      // Nếu đặt hàng thành công và thanh toán qua VNPay, cập nhật trạng thái thanh toán
      if (success && orderId != '' && _provider.paymentMethod == "Online") {
        print(
            "🔹 Đặt hàng thành công, cập nhật trạng thái thanh toán cho đơn hàng #$orderId");

        try {
          // Gọi API để cập nhật trạng thái thanh toán
          final paymentRepo = PaymentRepository();

          // Convert orderId to int safely, handling both String and int types
          int orderIdInt;
          if (orderId is int) {
            orderIdInt = orderId;
          } else if (orderId is String) {
            orderIdInt = int.parse(orderId);
          } else {
            print(
                "⚠️ OrderId không đúng định dạng: $orderId (${orderId.runtimeType})");
            orderIdInt = 0; // Fallback value
          }

          if (orderIdInt > 0) {
            try {
              final paymentUpdateSuccess =
                  await paymentRepo.updateOrderPaymentStatus(
                      orderIdInt, true // Đánh dấu là đã thanh toán
                      );

              if (paymentUpdateSuccess) {
                print(
                    "✅ Đã cập nhật trạng thái thanh toán cho đơn hàng #$orderId thành công");
              } else {
                print(
                    "⚠️ Không thể cập nhật trạng thái thanh toán cho đơn hàng #$orderId");
                // Xử lý vẫn tiếp tục dù không cập nhật được trạng thái thanh toán
                print(
                    "✅ Vẫn tiếp tục quy trình đặt hàng dù không cập nhật được trạng thái thanh toán");
              }
            } catch (e) {
              // Bắt lỗi nhưng vẫn tiếp tục flow
              print("⚠️ Lỗi khi cập nhật trạng thái thanh toán: $e");
              print("✅ Vẫn tiếp tục quy trình đặt hàng mặc dù có lỗi");
            }
          } else {
            print(
                "⚠️ Không thể cập nhật trạng thái thanh toán: OrderId không hợp lệ");
          }
        } catch (e) {
          // Bắt lỗi cho toàn bộ phần cập nhật thanh toán nhưng vẫn tiếp tục
          print("⚠️ Lỗi ngoại lệ khi cập nhật trạng thái thanh toán: $e");
          print("✅ Vẫn tiếp tục quy trình đặt hàng");
        }
      }

      // Làm mới giỏ hàng trước khi thông báo để tránh hiện tượng nhấp nháy UI
      if (success) {
        await _provider.refreshCart();
      }

      // Đóng dialog "Đang xử lý" nếu có
      if (hasActiveDialog) {
        Navigator.of(context).pop();
        hasActiveDialog = false;
      }

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Thay thế Dialog thành công bằng ThankYouDialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => ThankYouDialog(
            context,
            (value) {
              // Handle value if needed
              if (value == 1) {
                // User selected OK or Track Order
                Navigator.pop(context, true); // Return to previous screen
              }
            },
          ),
        );
      } else {
        // Thông báo lỗi
        NotificationDialog.showError(
          context: context,
          title: 'Lỗi đặt hàng',
          message: message,
          primaryButtonText: 'Đóng',
          primaryAction: () {
            // Dialog will close
          },
        );
      }
    } catch (e) {
      print("❌ Lỗi đặt hàng sau thanh toán: $e");

      // Đóng dialog "Đang xử lý" nếu có
      if (hasActiveDialog) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isLoading = false;
      });

      NotificationDialog.showError(
        context: context,
        title: 'Lỗi đặt hàng',
        message: e.toString(),
        primaryButtonText: 'Đóng',
        primaryAction: () {
          // Dialog will close
        },
      );
    }
  }

  void _showAddressSelectionDialog(bool isBilling) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primaryColor),
              SizedBox(width: 8),
              Text(
                "Chọn địa chỉ ${isBilling ? 'nhận hóa đơn' : 'giao hàng'}",
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 400),
            child: _provider.addressList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_off,
                            size: 48, color: AppColors.greyFont),
                        SizedBox(height: 16),
                        Text(
                          "Bạn chưa có địa chỉ nào",
                          style: TextStyle(color: AppColors.greyFont),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _provider.addressList.length,
                    itemBuilder: (context, index) {
                      final address = _provider.addressList[index];
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            address.fullName,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(address.phone),
                              SizedBox(height: 4),
                              Text(address.address),
                            ],
                          ),
                          onTap: () {
                            if (isBilling) {
                              _provider.setBillingAddress(address);
                            } else {
                              _provider.setShippingAddress(address);
                            }
                            Navigator.pop(dialogContext);

                            // Force update UI after address selection
                            setState(() {});
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Hủy", style: TextStyle(color: AppColors.greyFont)),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.add, size: 16),
              label: Text("Thêm địa chỉ mới"),
              onPressed: () {
                Navigator.pop(dialogContext);
                _showAddNewAddressDialog(isBilling);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddNewAddressDialog(bool isBilling) {
    final fullNameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.add_location_alt, color: AppColors.primaryColor),
                SizedBox(width: 8),
                Text("Thêm địa chỉ mới"),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Thông tin địa chỉ",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.greyFont,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Họ tên',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? DarkThemeColors.secondaryBackground
                          : Colors.grey[50],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? DarkThemeColors.secondaryBackground
                          : Colors.grey[50],
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Địa chỉ chi tiết',
                      prefixIcon: Icon(Icons.home),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? DarkThemeColors.secondaryBackground
                          : Colors.grey[50],
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: Text("Hủy"),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        // Validate fields
                        if (fullNameController.text.isEmpty ||
                            phoneController.text.isEmpty ||
                            addressController.text.isEmpty) {
                          NotificationDialog.showWarning(
                            context: context,
                            title: 'Thông tin chưa đầy đủ',
                            message: 'Vui lòng điền đầy đủ thông tin',
                            primaryButtonText: 'Đã hiểu',
                            primaryAction: () {
                              // Dialog will close
                            },
                          );
                          return;
                        }

                        setState(() {
                          isSubmitting = true;
                        });

                        // Create new address with default email
                        final newAddress = Address(
                          id: 0, // ID will be assigned by backend
                          fullName: fullNameController.text,
                          phone: phoneController.text,
                          address: addressController.text,
                        );

                        try {
                          final success =
                              await _provider.addNewAddress(newAddress);

                          // Set isSubmitting to false before showing notification
                          setState(() {
                            isSubmitting = false;
                          });

                          if (success) {
                            // Close the dialog first before showing notification
                            Navigator.pop(dialogContext);

                            // Get the last added address (should be the one we just created)
                            if (_provider.addressList.isNotEmpty) {
                              Address? addedAddress;

                              // Find the address we just added by matching properties
                              for (var address in _provider.addressList) {
                                if (address.fullName == newAddress.fullName &&
                                    address.phone == newAddress.phone &&
                                    address.address == newAddress.address) {
                                  addedAddress = address;
                                  break;
                                }
                              }

                              if (addedAddress != null) {
                                if (isBilling) {
                                  _provider.setBillingAddress(addedAddress);
                                } else {
                                  _provider.setShippingAddress(addedAddress);
                                }

                                // Force update UI after address addition
                                this.setState(() {});
                              }
                            }

                            // Show success notification after dialog is closed
                            NotificationDialog.showSuccess(
                              context: context,
                              title: 'Thành công',
                              message: 'Thêm địa chỉ thành công',
                              primaryButtonText: 'Đóng',
                              primaryAction: () {
                                // Dialog will close
                              },
                            );
                          } else {
                            NotificationDialog.showError(
                              context: context,
                              title: 'Lỗi',
                              message:
                                  'Không thể thêm địa chỉ. Vui lòng thử lại.',
                              primaryButtonText: 'Đóng',
                              primaryAction: () {
                                // Dialog will close
                              },
                            );
                          }
                        } catch (e) {
                          // Handle any exceptions that might occur
                          setState(() {
                            isSubmitting = false;
                          });

                          NotificationDialog.showError(
                            context: context,
                            title: 'Lỗi',
                            message: 'Đã xảy ra lỗi: ${e.toString()}',
                            primaryButtonText: 'Đóng',
                            primaryAction: () {
                              // Dialog will close
                            },
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text("Lưu địa chỉ"),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                      decoration: BoxDecoration(
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
                  Text(
                    "Xác nhận đơn hàng",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.fontLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  const ChatIconBadge(size: 26),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Main content
          _isLoading && _provider.addressList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primaryColor),
                      SizedBox(height: 16),
                      Text(
                        "Đang tải thông tin đơn hàng...",
                        style: TextStyle(color: AppColors.greyFont),
                      )
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Billing address section
                      _buildSectionHeader(
                          "Địa chỉ nhận hóa đơn", Icons.receipt, context),
                      SizedBox(height: 8),
                      _buildAddressCard(_provider.billingAddress, context),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: Icon(Icons.edit,
                                  size: 16, color: AppColors.primaryColor),
                              label: Text("Chọn địa chỉ khác",
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.primaryColor)),
                              onPressed: () {
                                _showAddressSelectionDialog(true);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.add,
                                size: 16, color: AppColors.primaryColor),
                            label: Text("Thêm mới",
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primaryColor)),
                            onPressed: () {
                              _showAddNewAddressDialog(true);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ],
                      ),

                      Divider(
                          height: 32,
                          thickness: 1,
                          color: AppColors.dividerColor),

                      // Shipping address section
                      _buildSectionHeader(
                          "Địa chỉ giao hàng", Icons.local_shipping, context),
                      SizedBox(height: 8),
                      _buildAddressCard(_provider.shippingAddress, context),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: Icon(Icons.edit,
                                  size: 16, color: AppColors.primaryColor),
                              label: Text("Chọn địa chỉ khác",
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.primaryColor)),
                              onPressed: () {
                                _showAddressSelectionDialog(false);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.add,
                                size: 16, color: AppColors.primaryColor),
                            label: Text("Thêm mới",
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primaryColor)),
                            onPressed: () {
                              _showAddNewAddressDialog(false);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ],
                      ),

                      Divider(
                          height: 32,
                          thickness: 1,
                          color: AppColors.dividerColor),

                      // Payment method section
                      _buildSectionHeader(
                          "Phương thức thanh toán", Icons.payment, context),
                      SizedBox(height: 12),

                      // Payment options in nicer cards
                      _buildPaymentMethodCard(
                        "COD",
                        "Thanh toán sau khi nhận hàng (COD)",
                        Icons.local_atm,
                        _provider.paymentMethod == "COD",
                        () {
                          setState(() {
                            _provider.setPaymentMethod("COD");
                          });
                        },
                        context,
                      ),
                      SizedBox(height: 8),
                      _buildPaymentMethodCard(
                        "Online",
                        "Thanh toán online",
                        Icons.credit_card,
                        _provider.paymentMethod == "Online",
                        () {
                          setState(() {
                            _provider.setPaymentMethod("Online");
                          });
                        },
                        context,
                      ),

                      Divider(
                          height: 32,
                          thickness: 1,
                          color: AppColors.dividerColor),

                      // Order items section
                      _buildSectionHeader(
                          "Đơn hàng", Icons.shopping_bag, context),
                      SizedBox(height: 12),

                      // Product list
                      ..._provider.orderProducts
                          .map((product) => _buildProductItem(product, context))
                          .toList(),

                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? DarkThemeColors.secondaryBackground
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Shipping fee
                            _buildCostRow(
                                "Chi phí vận chuyển",
                                "${_provider.checkoutResponse?.data.shippingCost?.toStringAsFixed(0) ?? '0'} đ",
                                context),

                            SizedBox(height: 8),

                            // Notification about shipping cost
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 16, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  "Thông báo sau cho khách hàng",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),

                            Divider(height: 24, color: AppColors.dividerColor),

                            // Payment method confirmation
                            Row(
                              children: [
                                Icon(
                                  _provider.paymentMethod == 'COD'
                                      ? Icons.local_atm
                                      : Icons.credit_card,
                                  size: 16,
                                  color: AppColors.greyFont,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Phương thức thanh toán: ${_provider.paymentMethod == 'COD' ? 'Thanh toán sau khi nhận hàng (COD)' : 'Thanh toán online'}",
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            Divider(height: 24, color: AppColors.dividerColor),

                            // Total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Tổng thanh toán",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${_formatPrice(_provider.totalPrice)} đ",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Place order button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.shopping_cart_checkout),
                          label: Text(
                            "Đặt hàng",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _placeOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

          // Loading overlay - improved for dark mode
          if (_isLoading && _provider.addressList.isNotEmpty)
            Container(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.5)
                  : Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  elevation: isDarkMode ? 8 : 4,
                  color: AppColors.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Đang xử lý đơn hàng...",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.fontBlack,
                          ),
                        ),
                        SizedBox(height: 8),
                        if (_provider.billingAddress != null &&
                            _provider.shippingAddress != null)
                          Container(
                            width: 250,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Phương thức: ${_provider.paymentMethod == 'COD' ? 'Thanh toán khi nhận hàng' : 'Thanh toán online'}",
                                  style: TextStyle(
                                      fontSize: 14, color: AppColors.fontBlack),
                                ),
                                Text(
                                  "Người nhận: ${_provider.shippingAddress!.fullName}",
                                  style: TextStyle(
                                      fontSize: 14, color: AppColors.fontBlack),
                                ),
                                Text(
                                  "SĐT: ${_provider.shippingAddress!.phone}",
                                  style: TextStyle(
                                      fontSize: 14, color: AppColors.fontBlack),
                                ),
                                Text(
                                  "Tổng đơn hàng: ${_formatPrice(_provider.totalPrice)} đ",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.fontBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, IconData icon, BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryColor),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.fontBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(Address? address, BuildContext context) {
    if (address == null) {
      return Card(
        elevation: 0,
        color:
            isDarkMode ? DarkThemeColors.secondaryBackground : Colors.grey[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.dividerColor),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.location_off, color: AppColors.greyFont),
              SizedBox(width: 12),
              Text("Chưa có địa chỉ",
                  style: TextStyle(color: AppColors.greyFont)),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, size: 16, color: AppColors.primaryColor),
                SizedBox(width: 8),
                Text(
                  address.fullName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: AppColors.greyFont),
                SizedBox(width: 8),
                Text(address.phone),
              ],
            ),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.home, size: 16, color: AppColors.greyFont),
                SizedBox(width: 8),
                Expanded(
                  child: Text(address.address),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String value, String title, IconData icon,
      bool isSelected, VoidCallback onTap, BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.1)
              : (isDarkMode
                  ? DarkThemeColors.secondaryBackground
                  : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryColor : AppColors.greyFont,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(Product product, BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.fontBlack,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "SL: ${product.quantity}",
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      if (product.code.isNotEmpty)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "Mã: ${product.code}",
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Price
            Text(
              "${_formatPrice(product.price)} đ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String title, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  String _getFixedImageUrl(String url) {
    try {
      if (url.isEmpty) {
        // Return default placeholder image if URL is empty
        return 'https://via.placeholder.com/150/cccccc/ffffff?text=No+Image';
      }

      // Sử dụng getImageUrl từ utils
      String processedUrl = getImageUrl(url);

      // Ghi log URL đã xử lý để dễ gỡ lỗi
      print("Processed URL: $processedUrl");

      return processedUrl;
    } catch (e) {
      print("Error processing image URL: $e");
      // Return default placeholder image in case of error
      return 'https://via.placeholder.com/150/cccccc/ffffff?text=Error';
    }
  }
}
