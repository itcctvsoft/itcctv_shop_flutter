import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/repositories/google_auth_repository.dart';
import 'package:shoplite/constants/pref_data.dart';

// Định nghĩa trạng thái cho quá trình đăng nhập bằng Google
enum GoogleAuthStatus { initial, loading, success, error }

class GoogleAuthNotifier extends StateNotifier<GoogleAuthStatus> {
  final GoogleAuthRepository _googleAuthRepository;
  GoogleAuthNotifier(this._googleAuthRepository)
      : super(GoogleAuthStatus.initial);

  String? errorMessage;
  int? userId;
  String? userName;
  String? userRole;
  String? token;

  // Method to force a complete sign-out before attempting a new sign-in
  Future<void> forceSignOut() async {
    try {
      // Force sign out from Google first
      await _googleAuthRepository.forceSignOut();

      // Reset all state
      userId = null;
      userName = null;
      userRole = null;
      token = null;
      errorMessage = null;

      // Reset to initial state without changing UI state
      // This allows the UI to continue showing the normal button
    } catch (error) {
      print("Error during force sign-out: $error");
      // We don't change state or show error here as this is a preparatory step
    }
  }

  // Phương thức đăng ký bằng Google
  Future<void> signUpWithGoogle({required String role}) async {
    state = GoogleAuthStatus.loading;

    try {
      final response = await _googleAuthRepository.signUpWithGoogle(role: role);

      if (response.containsKey('error')) {
        errorMessage = response['error'];
        state = GoogleAuthStatus.error;
        return;
      }

      if (response['success'] == true) {
        // Lưu thông tin người dùng từ phản hồi
        userId = response['userId'];
        userName = response['userName'];
        userRole = response['userRole'];
        token = response['token'];

        state = GoogleAuthStatus.success;
      } else {
        throw Exception('Đăng ký không thành công!');
      }
    } catch (error) {
      errorMessage = error.toString();
      state = GoogleAuthStatus.error;
    }
  }

  // Phương thức đăng nhập bằng Google
  Future<void> signInWithGoogle({String? role}) async {
    state = GoogleAuthStatus.loading;

    try {
      final response = await _googleAuthRepository.signInWithGoogle(role: role);

      if (response.containsKey('error')) {
        errorMessage = response['error'];
        state = GoogleAuthStatus.error;
        return;
      }

      if (response['success'] == true) {
        // Lưu thông tin người dùng từ phản hồi
        userId = response['userId'];
        userName = response['userName'];
        userRole = response['userRole'];
        token = response['token'];

        state = GoogleAuthStatus.success;
      } else {
        throw Exception('Đăng nhập không thành công!');
      }
    } catch (error) {
      errorMessage = error.toString();
      state = GoogleAuthStatus.error;
    }
  }

  // Phương thức đăng xuất
  Future<void> signOut() async {
    state = GoogleAuthStatus.loading;

    try {
      await _googleAuthRepository.signOut();

      // Reset state
      userId = null;
      userName = null;
      userRole = null;
      token = null;

      state = GoogleAuthStatus.initial;
    } catch (error) {
      errorMessage = error.toString();
      state = GoogleAuthStatus.error;
    }
  }
}

// Provider cho Google Authentication
final googleAuthProvider =
    StateNotifierProvider<GoogleAuthNotifier, GoogleAuthStatus>((ref) {
  final googleAuthRepository = GoogleAuthRepository();
  return GoogleAuthNotifier(googleAuthRepository);
});
