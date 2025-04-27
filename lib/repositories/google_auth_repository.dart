import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shoplite/constants/apilist.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shoplite/constants/pref_data.dart';

class GoogleAuthRepository {
  // API endpoint for Google Sign-In
  final String apiUrl = api_login_google;

  // Khởi tạo GoogleSignIn một lần để sử dụng lại
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Phương thức đăng nhập với Google
  Future<Map<String, dynamic>> signInWithGoogle({String? role}) async {
    try {
      print("=================== BẮT ĐẦU ĐĂNG NHẬP GOOGLE ===================");

      // Đăng xuất để đảm bảo người dùng chọn tài khoản mới mỗi lần
      try {
        await forceSignOut(); // Use our more comprehensive sign out method
      } catch (e) {
        print("Lỗi khi đăng xuất Google trước khi đăng nhập: $e");
        // Bỏ qua lỗi này, vẫn tiếp tục đăng nhập
      }

      // Thực hiện đăng nhập Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print("Người dùng hủy đăng nhập Google");
        return {"error": "Đăng nhập Google bị hủy"};
      }

      print("Google Sign In successful: ${googleUser.email}");

      // Lấy thông tin xác thực
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Lấy avatar URL từ tài khoản Google nếu có
      String? photoUrl = googleUser.photoUrl;

      // Google thường trả về ảnh dạng thu nhỏ, thay đổi kích thước để có ảnh lớn hơn
      if (photoUrl != null && photoUrl.isNotEmpty) {
        // Xóa tham số s=XX nếu có và thay bằng kích thước lớn hơn
        if (photoUrl.contains('=s')) {
          photoUrl = photoUrl.replaceAll(RegExp(r'=s\d+'), '=s500');
        } else {
          // Thêm tham số kích thước nếu chưa có
          photoUrl = '$photoUrl${photoUrl.contains('?') ? '&' : '?'}s=500';
        }
      }

      print("Google Avatar URL: $photoUrl");

      // Chuẩn bị dữ liệu cho API
      final userData = {
        'email': googleUser.email,
        'full_name': googleUser.displayName ?? googleUser.email.split('@')[0],
        'google_id': googleAuth.idToken ?? googleUser.id,
        'role': role ?? 'customer',
        'phone': '0000000000', // Giá trị mặc định, có thể thay đổi sau
        'username': googleUser.email.split('@')[0], // Tạo username từ email
        'photo_url': photoUrl, // Thêm URL ảnh đại diện từ Google
      };

      print("User data created successfully");

      // Gửi dữ liệu đến API
      print('Sending request to: $apiUrl');
      print('Request data: $userData');

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(userData),
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['success'] == true &&
              data['user'] != null &&
              data['token'] != null) {
            // Xử lý lưu thông tin
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('userId', data['user']['id']);
            await prefs.setString('userName', data['user']['full_name']);
            await prefs.setString('userEmail', data['user']['email']);
            await prefs.setString('userRole', data['user']['role']);

            // Lưu URL ảnh từ response hoặc từ Google nếu có
            String photoUrl = data['user']['photo'] ?? '';

            // Nếu ảnh từ server là ảnh mặc định và chúng ta có ảnh Google, sử dụng ảnh Google
            if ((photoUrl.isEmpty || photoUrl.contains('profile-6.jpg')) &&
                userData['photo_url'] != null &&
                userData['photo_url'].toString().isNotEmpty) {
              photoUrl = userData['photo_url'].toString();
            }

            await prefs.setString('userPhoto', photoUrl);
            await prefs.setString('token', data['token']);
            await prefs.setBool('isLoggedIn', true);

            // Lưu thông tin là tài khoản Google
            await prefs.setString('googleId', userData['google_id'].toString());
            // Explicitly mark this as a Google account
            await prefs.setBool('isGoogleAccount', true);

            // Lưu token vào biến toàn cục
            g_token = data['token'];

            // Sử dụng PrefData để lưu token - đảm bảo nhất quán
            await PrefData.setToken(data['token']);

            // In ra token để debug
            print('Token đã được lưu: ${data['token']}');
            print('g_token: $g_token');

            return {
              'success': true,
              'userId': data['user']['id'],
              'userName': data['user']['full_name'],
              'userRole': data['user']['role'],
              'token': data['token']
            };
          } else {
            return {"error": "Cấu trúc phản hồi API không hợp lệ"};
          }
        } else if (response.statusCode == 401) {
          return {"error": "Không được phép truy cập. Vui lòng thử lại."};
        } else if (response.statusCode == 500) {
          // Kiểm tra nếu lỗi liên quan đến database constraint
          final responseData = jsonDecode(response.body);
          if (responseData['message'] != null &&
              responseData['message']
                  .toString()
                  .contains('Integrity constraint violation')) {
            print("Database constraint error: ${responseData['message']}");
            return {
              "error":
                  "Lỗi dữ liệu: Thiếu thông tin bắt buộc cho đăng ký tài khoản."
            };
          }
          return {
            "error":
                "Lỗi máy chủ: ${response.statusCode}. Vui lòng thử lại sau."
          };
        } else {
          return {"error": "Lỗi API: ${response.statusCode}"};
        }
      } catch (apiError) {
        print("API Error: $apiError");
        return {"error": "Lỗi kết nối API: $apiError"};
      }
    } catch (e) {
      print('=================== LỖI ĐĂNG NHẬP GOOGLE ===================');
      print('Error type: ${e.runtimeType}');
      print('Error details: $e');
      print('============================================================');
      return {"error": e.toString()};
    }
  }

  // Force sign out method - more comprehensive than regular signOut
  Future<void> forceSignOut() async {
    try {
      // First try to disconnect completely (this removes all granted permissions)
      try {
        await _googleSignIn.disconnect();
      } catch (e) {
        print("Error disconnecting from Google: $e");
      }

      // Then perform a signOut to ensure the session is closed
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print("Error signing out from Google: $e");
      }

      // Use the comprehensive logout method to clear all authentication state
      await PrefData.logout();

      // Extra safety for global token
      g_token = "";

      print("=== Force sign out completed successfully ===");
    } catch (e) {
      print('Error during force sign out: $e');
      throw Exception('Không thể đăng xuất hoàn toàn: $e');
    }
  }

  // Phương thức đăng xuất
  Future<void> signOut() async {
    try {
      // Đăng xuất khỏi Google
      await _googleSignIn.signOut();

      // Use the comprehensive logout method to clear all authentication state
      await PrefData.logout();

      // Extra safety for global token
      g_token = "";

      print("=== Sign out completed successfully ===");
    } catch (e) {
      print('Error signing out: $e');
      throw Exception('Không thể đăng xuất: $e');
    }
  }

  // Phương thức đăng ký
  Future<Map<String, dynamic>> signUpWithGoogle({required String role}) async {
    return signInWithGoogle(role: role);
  }
}
