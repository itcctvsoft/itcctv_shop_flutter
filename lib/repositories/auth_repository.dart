import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shoplite/constants/apilist.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoplite/constants/pref_data.dart';
import 'package:shoplite/models/profile.dart';
import 'package:shoplite/repositories/google_auth_repository.dart'; // Import GoogleAuthRepository

class AuthRepository {
  final String apiUrl = api_login; // URL của API đăng nhập
  final String apiRegisterUrl = api_register; // URL của API đăng ký
  final String apiUpdateProfileUrl =
      api_updateprofile; // URL của API cập nhật profile

  // Create instance of GoogleAuthRepository for sign out operations
  final GoogleAuthRepository _googleAuthRepository = GoogleAuthRepository();

  // Phương thức đăng nhập
  Future<bool> login(String email, String password) async {
    try {
      // First, ensure any Google Sign-In session is completely terminated
      await _googleAuthRepository.forceSignOut();

      // Then proceed with regular login
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Login response data: $data");

        // Validate that we have the expected token structure
        if (data['token'] == null || data['token']['token'] == null) {
          print("Auth Repository: Missing token in response");
          return false;
        }

        g_token = data['token']['token'];

        print("AUTH REPOSITORY: Login successful, setting token and flags");
        print("Token: ${g_token.substring(0, 10)}...");

        // Store user data but explicitly mark as non-Google authentication
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isGoogleAccount', false);

        // Set token
        await PrefData.setToken(g_token);
        await prefs.setString(PrefData.token, g_token);

        // Save user profile data to SharedPreferences with detailed debug
        if (data['user'] != null) {
          // Store basic user info with type checking
          if (data['user']['full_name'] != null) {
            await prefs.setString(
                'userName', data['user']['full_name'].toString());
            print("Stored userName: ${data['user']['full_name']}");
          }

          if (data['user']['email'] != null) {
            await prefs.setString(
                'userEmail', data['user']['email'].toString());
            print("Stored userEmail: ${data['user']['email']}");
          }

          if (data['user']['role'] != null) {
            await prefs.setString('userRole', data['user']['role'].toString());
            print("Stored userRole: ${data['user']['role']}");
          }

          if (data['user']['photo'] != null) {
            await prefs.setString(
                'userPhoto', data['user']['photo'].toString());
            print("Stored userPhoto: ${data['user']['photo']}");
          } else {
            // Set default photo URL if missing
            await prefs.setString('userPhoto', '');
            print("No photo URL in response, set empty");
          }

          if (data['user']['phone'] != null) {
            await prefs.setString(
                'userPhone', data['user']['phone'].toString());
            print("Stored userPhone: ${data['user']['phone']}");
          } else {
            await prefs.setString('userPhone', '');
          }

          if (data['user']['address'] != null) {
            await prefs.setString(
                'userAddress', data['user']['address'].toString());
            print("Stored userAddress: ${data['user']['address']}");
          } else {
            await prefs.setString('userAddress', '');
          }

          if (data['user']['username'] != null) {
            await prefs.setString(
                'username', data['user']['username'].toString());
            print("Stored username: ${data['user']['username']}");
          } else {
            // Generate username from email if missing
            final String username =
                data['user']['email'].toString().split('@')[0];
            await prefs.setString('username', username);
            print("Generated username from email: $username");
          }

          // Store userId as an integer with explicit type handling
          if (data['user']['id'] != null) {
            // Check if id is already an int or needs conversion
            int userId;
            try {
              if (data['user']['id'] is int) {
                userId = data['user']['id'];
              } else {
                // Try to parse it as an int if it's a string
                userId = int.tryParse(data['user']['id'].toString()) ?? 0;
              }

              // First remove any existing userId to avoid type conflicts
              await prefs.remove('userId');

              // Then store it as an int
              if (userId > 0) {
                await prefs.setInt('userId', userId);
                print(
                    "Stored userId as INT: $userId (original type: ${data['user']['id'].runtimeType})");

                // Additional validation: read back and verify the type
                var storedUserId = prefs.get('userId');
                print(
                    "Verification - stored userId: $storedUserId (type: ${storedUserId.runtimeType})");
              } else {
                print("Invalid userId: $userId, not storing");
              }
            } catch (e) {
              print("Error storing userId: $e");
              // If there was an error, make sure we don't have a conflicting userId
              await prefs.remove('userId');
            }
          }
        }

        // Set current session auth state
        await prefs.setBool('currentSessionLoggedIn', true);

        // Verify settings were successful
        bool tokenSet = (await PrefData.getToken()).isNotEmpty;
        bool fullAuth = await PrefData.isAuthenticated();

        print("AUTH REPOSITORY verification:");
        print("- Token set: $tokenSet");
        print("- Full authentication: $fullAuth");

        // Create Profile object for app use
        initialProfile = Profile(
          phone: data['user']['phone']?.toString() ?? '',
          full_name: data['user']['full_name']?.toString() ?? 'Người dùng',
          address: data['user']['address']?.toString() ?? '',
          photo: data['user']['photo']?.toString() ?? '',
          email: data['user']['email']?.toString() ?? 'user@example.com',
          username: data['user']['username']?.toString() ??
              (data['user']['email']?.toString().split('@')[0] ?? 'user'),
        );
        return true;
      } else {
        print(
            "Auth Repository: Login failed with status code ${response.statusCode}");
        print("Response body: ${response.body}");
        return false;
      }
    } catch (error) {
      print("Auth Repository: Login error: $error");
      return false;
    }
  }

  // Phương thức đăng ký
  Future<bool> register(String email, String password, String full_Name,
      String phone, String address) async {
    try {
      final body = jsonEncode({
        'email': email,
        'password': password,
        'full_name': full_Name,
        'phone': phone,
        'address': address,
      });

      final response = await http.post(
        Uri.parse(apiRegisterUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}'); // In ra phản hồi để kiểm tra

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Kiểm tra success từ phản hồi
        if (data['success'] == true) {
          print('Đăng ký thành công!');
          return true; // Đăng ký thành công
        } else {
          print('Lỗi trong quá trình đăng ký: ${data['message']}');
          return false; // Đăng ký không thành công, xử lý thông báo lỗi từ API
        }
      } else {
        print('Đăng ký thất bại: ${response.body}');
        return false;
      }
    } catch (error) {
      print('Lỗi khi đăng ký: $error');
      return false; // Lỗi trong quá trình gọi API hoặc xử lý
    }
  }

  // Phương thức cập nhật thông tin profile
  Future<bool> updateProfile(Profile profile) async {
    try {
      final response = await http.post(
        Uri.parse(apiUpdateProfileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $g_token', // Gửi token trong header
        },
        body: jsonEncode(
            profile.toJson()), // Sử dụng phương thức toJson để gửi dữ liệu
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          PrefData.setProfile(
              profile); // Cập nhật thông tin mới vào SharedPreferences
          return true;
        } else {
          print('Lỗi trong quá trình cập nhật profile: ${data['message']}');
          return false;
        }
      } else {
        print('Cập nhật thất bại: ${response.body}');
        return false;
      }
    } catch (error) {
      print('Lỗi khi cập nhật profile: $error');
      return false;
    }
  }

  // Phương thức thay đổi mật khẩu
  Future<Map<String, dynamic>> changePassword(String currentPassword,
      String newPassword, String confirmPassword) async {
    try {
      final response = await http.post(
        Uri.parse(api_change_password),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $g_token', // Gửi token trong header
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Thay đổi mật khẩu thành công!',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Có lỗi xảy ra khi thay đổi mật khẩu.',
        };
      }
    } catch (error) {
      print('Lỗi khi thay đổi mật khẩu: $error');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi, vui lòng thử lại sau.',
      };
    }
  }

  // Phương thức cập nhật thông tin profile có ảnh
  Future<Map<String, dynamic>> updateProfileWithPhoto(Profile profile,
      {String? imagePath}) async {
    try {
      // Tạo multipart request để có thể upload file
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(apiUpdateProfileUrl),
      );

      // Thêm headers và auth token
      request.headers.addAll({
        'Authorization': 'Bearer $g_token',
        'Accept': 'application/json',
      });

      // Thêm các trường dữ liệu theo yêu cầu API
      request.fields['full_name'] = profile.full_name;
      request.fields['email'] = profile.email;
      if (profile.phone.isNotEmpty) request.fields['phone'] = profile.phone;
      if (profile.address.isNotEmpty)
        request.fields['address'] = profile.address;

      // Nếu có đường dẫn ảnh mới và không phải URL (tức là file cục bộ)
      if (imagePath != null && !imagePath.startsWith('http')) {
        print("Uploading image from path: $imagePath");
        // Thêm file ảnh vào request - 'photo' là tên field trong API Laravel
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          imagePath,
        ));
      }

      print(
          "Sending profile update request with${imagePath != null ? '' : 'out'} photo");

      // Gửi request và chờ phản hồi
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Profile update response status: ${response.statusCode}");
      print("Profile update response body: ${response.body}");

      // Phân tích JSON phản hồi
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Kiểm tra dữ liệu phản hồi
        var updatedProfile = profile;

        // Cấu trúc API updateProfile trả về user nằm trong trường 'user'
        if (data['user'] != null) {
          // Cập nhật ảnh mới từ response
          if (data['user']['photo'] != null) {
            updatedProfile.photo = data['user']['photo'];
            print("Cập nhật ảnh mới từ API: ${updatedProfile.photo}");
          }

          // Cập nhật các thông tin khác
          if (data['user']['full_name'] != null) {
            updatedProfile.full_name = data['user']['full_name'];
          }
          if (data['user']['email'] != null) {
            updatedProfile.email = data['user']['email'];
          }
          if (data['user']['phone'] != null) {
            updatedProfile.phone = data['user']['phone'];
          }
          if (data['user']['address'] != null) {
            updatedProfile.address = data['user']['address'];
          }
        }

        // Lưu profile vào SharedPreferences
        await PrefData.setProfile(updatedProfile);

        // Lưu từng trường thông tin riêng lẻ
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', updatedProfile.full_name);
        await prefs.setString('userEmail', updatedProfile.email);
        await prefs.setString('userPhone', updatedProfile.phone);
        await prefs.setString('userAddress', updatedProfile.address);
        await prefs.setString('userPhoto', updatedProfile.photo);
        await prefs.setString('username', updatedProfile.username);

        return {
          'success': true,
          'message': data['message'] ?? 'Cập nhật thành công!',
          'profile': updatedProfile,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Có lỗi xảy ra khi cập nhật profile.',
        };
      }
    } catch (error) {
      print('Lỗi khi cập nhật profile: $error');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $error',
      };
    }
  }
}
