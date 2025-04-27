import 'dart:io'; // Để kiểm tra môi trường
import 'package:flutter/foundation.dart'
    show kIsWeb; // Để nhận diện Flutter Web
import 'package:shoplite/models/site_setting.dart';
import '../models/profile.dart';

// Tự động xác định base URL
final String base = _getBaseUrl();

String _getBaseUrl() {
  if (kIsWeb) {
    // Nếu chạy trên Flutter Web (Chrome, Edge)
    return 'http://127.0.0.1:8000/api/v1';
  } else if (Platform.isAndroid) {
    // Nếu chạy trên giả lập Android
    // 10.0.2.2 là địa chỉ localhost của máy host từ emulator Android
    return 'http://10.0.2.2:8000/api/v1';
  } else if (Platform.isIOS) {
    // Nếu chạy trên giả lập iOS
    return 'http://localhost:8000/api/v1';
  } else {
    // Các trường hợp khác
    return 'http://127.0.0.1:8000/api/v1';
  }
}

// Các endpoint API
final String api_register = base + "/register";
final String api_updateprofile = base + "/updateprofile";
final String api_profile = base + "/profile";
final String api_products = '$base/products/all';
final String api_product_detail = '$base/product';
final String api_products_search = '$base/products/search';
final String api_products_hot = '$base/products/hot';
final String api_login_google = '$base/google-signin'; // API đăng nhập Google
final String api_products_by_category = '$base/products/by-category';
final String api_get_product_list = '$base/products/all';
final String api_get_category_list = '$base/categories';
final String api_ge_product_list = base + "/getproductlist";
final String api_ge_category_list = base + "/getcategorylist";
final String api_ge_blog_list = '$base/blogs'; // API cho danh sách blog
final String api_login = base + "/login";
final String api_sitesetting = base + "/getsitesetting";
final String api_address = base + "/addresses";
final String api_add_to_cart = base + "/cart/add";
final String api_get_cart = base + "/cart/view";
final String api_po_cart_order = base + "/cart/order";
final String api_delete_cart = base + "/cart/remove";
final String api_put_cart = base + "/cart/update";
final String api_get_addressbook = base + "/addresses/view";
final String api_po_addressbook = base + "/addresses/add";
final String api_delete_addressbook = base + "/addressbook/delete";
final String api_get_checkout = base + "/cart/checkout";
final String api_order_place = base + "/order/place"; // API đặt hàng
// 🆕 API Thanh toán VNPay
final String api_create_vnpay_payment =
    base + "/vnpay/create-payment"; // Tạo link thanh toán
final String api_check_vnpay_status =
    base + "/vnpay/status"; // API kiểm tra trạng thái thanh toán VNPay
final String api_vnpay_return =
    base + "/vnpay/return"; // Xử lý phản hồi từ VNPay
// 🆕 API Wishlist
final String api_wishlist_add = base + "/wishlist/add"; // Thêm vào wishlist
final String api_wishlist_remove =
    base + "/wishlist/remove"; // Xóa khỏi wishlist
final String api_wishlist_view = base +
    "/wishlist/list"; // Xem danh sách wishlist với đầy đủ thông tin sản phẩm
// 🆕 API Order History
final String api_orders = base + "/orders"; // Lấy lịch sử đơn hàng
// 🆕 API Change Password
final String api_change_password =
    base + "/change-password"; // API thay đổi mật khẩu người dùng

// 🆕 API Comments
final String api_comment_add = base + "/comments/add"; // Thêm bình luận mới
final String api_comment_by_product =
    base + "/comments/by-product"; // Lấy bình luận theo sản phẩm
final String api_comment_update =
    base + "/comments/update"; // Cập nhật bình luận
final String api_comment_delete = base + "/comments/delete"; // Xóa bình luận

// 🆕 API Chat Support
final String api_chat_get_or_create =
    base + "/support/chat"; // Lấy hoặc tạo chat với admin
final String api_chat_send = base + "/support/send"; // Gửi tin nhắn mới
final String api_chat_history = base + "/support/history"; // Lấy lịch sử chat
final String api_chat_unread =
    base + "/support/unread"; // Lấy số tin nhắn chưa đọc

// 🆕 API Payment Status
final String api_update_payment_status =
    base + "/order/update-payment"; // API cập nhật trạng thái thanh toán

// Biến toàn cục lưu trữ thông tin
var g_sitesetting =
    SiteSetting(id: 0, company_name: 'company_name', logo: 'logo');
var app_type = "app";
var g_token = "";

// Hồ sơ người dùng mặc định
Profile initialProfile = Profile(
    full_name: 'Người dùng',
    phone: '',
    address: '',
    photo: '',
    username: 'user',
    email: 'user@example.com');
