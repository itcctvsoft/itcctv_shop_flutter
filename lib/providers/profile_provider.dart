import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/constants/pref_data.dart';
import 'package:shoplite/repositories/auth_repository.dart';
import 'package:shoplite/models/profile.dart';
import '../constants/apilist.dart';
import '../constants/enum.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileState {
  final Profile profile;
  final UpdateStatus updateStatus;
  final String? errorMessage;
  final bool isImageUploading; // Thêm trạng thái đang upload ảnh

  ProfileState({
    required this.profile,
    this.updateStatus = UpdateStatus.initial,
    this.errorMessage,
    this.isImageUploading = false, // Default là false
  });

  // Sao chép ProfileState với các giá trị có thể được cập nhật
  ProfileState copyWith({
    Profile? profile,
    UpdateStatus? updateStatus,
    String? errorMessage,
    bool? isImageUploading,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      updateStatus: updateStatus ?? this.updateStatus,
      errorMessage: errorMessage,
      isImageUploading: isImageUploading ?? this.isImageUploading,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final AuthRepository _repository;

  ProfileNotifier(this._repository)
      : super(ProfileState(profile: initialProfile)) {
    _loadProfile();
  }

  // Method to load profile from SharedPreferences
  Future<void> _loadProfile() async {
    try {
      // Try to get profile from SharedPreferences
      final profile = await PrefData.getProfile();
      if (profile != null) {
        state = state.copyWith(profile: profile);
      }
    } catch (e) {
      print("Error loading profile: $e");
    }
  }

  Future<Map<String, dynamic>> updateProfile(Profile updatedProfile) async {
    try {
      // Cập nhật trạng thái thành loading
      state = state.copyWith(updateStatus: UpdateStatus.loading);

      // Gửi yêu cầu cập nhật profile lên API
      bool isSuccess = await _repository.updateProfile(
          updatedProfile); // Gọi hàm updateProfile của repository

      if (isSuccess) {
        // Thành công, cập nhật state và lưu thông tin
        state = state.copyWith(
            updateStatus: UpdateStatus.success, profile: updatedProfile);
        await PrefData.setProfile(
            updatedProfile); // Lưu thông tin profile vào SharedPreferences

        return {
          'success': true,
          'message': 'Cập nhật hồ sơ thành công',
          'profile': updatedProfile,
        };
      } else {
        // Thất bại
        state = state.copyWith(
            updateStatus: UpdateStatus.failure,
            errorMessage: "Failed to update profile");

        return {
          'success': false,
          'message': 'Không thể cập nhật hồ sơ',
        };
      }
    } catch (e) {
      state = state.copyWith(
          updateStatus: UpdateStatus.failure, errorMessage: e.toString());

      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }

  // Phương thức mới để cập nhật profile có ảnh
  Future<Map<String, dynamic>> updateProfileWithPhoto(Profile updatedProfile,
      {String? imagePath}) async {
    try {
      // Đánh dấu đang tải ảnh lên
      state = state.copyWith(
        updateStatus: UpdateStatus.loading,
        isImageUploading: true,
      );

      // Gọi API cập nhật profile với ảnh
      final result = await _repository.updateProfileWithPhoto(
        updatedProfile,
        imagePath: imagePath,
      );

      if (result['success']) {
        // Lấy profile đã cập nhật từ kết quả nếu có
        final updatedProfile = result['profile'] as Profile? ?? state.profile;

        // Cập nhật state với thông tin mới
        state = state.copyWith(
          profile: updatedProfile,
          updateStatus: UpdateStatus.success,
          isImageUploading: false,
        );
      } else {
        // Xử lý khi cập nhật thất bại
        state = state.copyWith(
          updateStatus: UpdateStatus.failure,
          errorMessage: result['message'],
          isImageUploading: false,
        );
      }

      return result;
    } catch (e) {
      // Xử lý khi có lỗi
      state = state.copyWith(
        updateStatus: UpdateStatus.failure,
        errorMessage: e.toString(),
        isImageUploading: false,
      );

      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }

  // Fetch profile directly from API
  Future<bool> fetchProfileFromApi() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        return false;
      }

      final dio = Dio();
      Response response = await dio.get(
        api_profile,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print(
          "Profile fetch response: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 200) {
        var data = response.data;

        // API directly returns user properties
        Profile updatedProfile = Profile(
          full_name: data['full_name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          address: data['address'] ?? '',
          photo: data['photo'] ?? '',
          username: data['email']?.toString().split('@')[0] ?? '',
        );

        // Update state and save to SharedPreferences
        state = state.copyWith(profile: updatedProfile);
        await PrefData.setProfile(updatedProfile);
        return true;
      } else {
        print(
            "Failed to fetch profile: ${response.statusCode} - ${response.data}");
        return false;
      }
    } catch (e) {
      print("Error fetching profile from API: $e");
      return false;
    }
  }
}

// Provider cho AuthRepository
final profileRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());

// StateNotifierProvider để quản lý trạng thái ProfileNotifier
final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository);
});
