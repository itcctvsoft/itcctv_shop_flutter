import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shoplite/constants/pref_data.dart';
import 'package:shoplite/repositories/auth_repository.dart';
import 'dart:convert';

import '../constants/apilist.dart';
import '../constants/enum.dart';
import '../models/profile.dart';

// Định nghĩa trạng thái cho quá trình đăng nhập

// Provider để quản lý trạng thái đăng nhập
class LoginNotifier extends StateNotifier<LoginStatus> {
  LoginNotifier(this._repository) : super(LoginStatus.initial);
  final AuthRepository _repository;
  Future<void> login(String email, String password) async {
    state = LoginStatus.loading;
    bool kq = await _repository.login(email, password);
    if (kq == true) {
      PrefData.setLogIn(true);
      state = LoginStatus.success;
    } else
      state = LoginStatus.error;
  }
}

// Provider cho ProfileNotifier
final authRepositoryProvider = Provider((ref) => AuthRepository());

final loginProvider = StateNotifierProvider<LoginNotifier, LoginStatus>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginNotifier(repository);
});

class RegisterNotifier extends StateNotifier<RegisterStatus> {
  RegisterNotifier(this._repository) : super(RegisterStatus.initial);
  final AuthRepository _repository;

  Future<void> register(String email, String password, String fullName,
      String phone, String address) async {
    state = RegisterStatus.loading; // Đánh dấu bắt đầu quá trình đăng ký
    bool kq =
    await _repository.register(email, password, fullName, phone, address);
    if (kq == true) {
      PrefData.setLogIn(true);
      state = RegisterStatus
          .success; // Nếu thành công, chuyển trạng thái thành success
    } else {
      state =
          RegisterStatus.error; // Nếu thất bại, chuyển trạng thái thành error
    }
  }
}

final registerRepositoryProvider = Provider((ref) => AuthRepository());

final registerProvider =
StateNotifierProvider<RegisterNotifier, RegisterStatus>((ref) {
  final repository = ref.watch(registerRepositoryProvider);
  return RegisterNotifier(repository);
});

// Provider để quản lý trạng thái thay đổi mật khẩu
class ChangePasswordNotifier extends StateNotifier<ChangePasswordStatus> {
  ChangePasswordNotifier(this._repository)
      : super(ChangePasswordStatus.initial);
  final AuthRepository _repository;

  // Lưu trữ thông báo lỗi hoặc thành công
  String? _message;
  String? get message => _message;

  Future<bool> changePassword(String currentPassword, String newPassword,
      String confirmPassword) async {
    state = ChangePasswordStatus.loading;

    final result = await _repository.changePassword(
        currentPassword, newPassword, confirmPassword);

    _message = result['message'];

    if (result['success'] == true) {
      state = ChangePasswordStatus.success;
      return true;
    } else {
      state = ChangePasswordStatus.error;
      return false;
    }
  }

  // Reset trạng thái về ban đầu
  void resetState() {
    state = ChangePasswordStatus.initial;
    _message = null;
  }
}

final changePasswordProvider =
StateNotifierProvider<ChangePasswordNotifier, ChangePasswordStatus>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ChangePasswordNotifier(repository);
});
