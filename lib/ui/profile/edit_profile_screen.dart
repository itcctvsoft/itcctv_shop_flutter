import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/constants/widget_utils.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/enum.dart'; // Import for UpdateStatus
import 'package:shoplite/models/profile.dart';
import 'package:shoplite/providers/profile_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart'; // Sử dụng image_picker cho cả web và mobile
import 'package:flutter/foundation.dart'; // Thư viện hỗ trợ kiểm tra nền tảng
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shoplite/ui/widgets/notification_dialog.dart'; // Import NotificationDialog

class EditProfileScreen extends ConsumerStatefulWidget {
  final Profile currentProfile;

  const EditProfileScreen({Key? key, required this.currentProfile})
      : super(key: key);

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreen();
}

class _EditProfileScreen extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late Profile _profile;
  late ImagePicker _picker;
  XFile? _imageFile;
  bool _isGoogleAccount = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.currentProfile;
    _picker = ImagePicker();
    _checkIfGoogleAccount();
  }

  // Kiểm tra nếu tài khoản đăng nhập từ Google
  Future<void> _checkIfGoogleAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final googleId = prefs.getString('googleId');
    setState(() {
      _isGoogleAccount = googleId != null && googleId.isNotEmpty;
    });

    print("Account type: ${_isGoogleAccount ? 'Google' : 'Email/Password'}");
    print("Current photo: ${_profile.photo}");
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Debug info
        print("====== SAVING PROFILE ======");
        print("API Endpoint: ${api_updateprofile}");
        print(
            "Profile data: ${_profile.full_name}, ${_profile.email}, ${_profile.phone}, ${_profile.address}");
        if (_imageFile != null) {
          print("Image file: ${_imageFile!.path}");
        } else if (_profile.photo.startsWith('asset://')) {
          print("Using preset avatar: ${_profile.photo}");
        } else {
          print("Using existing photo: ${_profile.photo}");
        }

        Map<String, dynamic> result;

        // Kiểm tra trường hợp xử lý ảnh
        if (_imageFile != null) {
          // Trường hợp 1: Có ảnh mới từ camera hoặc thư viện
          result =
              await ref.read(profileProvider.notifier).updateProfileWithPhoto(
                    _profile,
                    imagePath: _imageFile!.path,
                  );
        } else if (_profile.photo.startsWith('asset://')) {
          // Trường hợp 2: Ảnh được chọn từ asset có sẵn
          // Đặt cờ hiệu để API biết đây là ảnh avatar có sẵn
          _profile.avatarType = 'preset_avatar';

          // Cập nhật profile mà không cần gửi ảnh lên server
          result =
              await ref.read(profileProvider.notifier).updateProfile(_profile);
        } else {
          // Trường hợp 3: Không có ảnh mới, hoặc giữ ảnh cũ từ URL
          result =
              await ref.read(profileProvider.notifier).updateProfile(_profile);
        }

        setState(() {
          _isSubmitting = false;
        });

        if (result['success']) {
          // Cập nhật ảnh từ kết quả nếu có
          if (result['profile'] != null) {
            _profile = result['profile'];
          }

          // Hiển thị thông báo thành công
          NotificationDialog.showSuccess(
            context: context,
            title: 'Thành công',
            message: 'Cập nhật hồ sơ thành công!',
            autoDismiss: true,
            autoDismissDuration: const Duration(seconds: 1),
          );

          Navigator.pop(context, _profile);
        } else {
          // Hiển thị thông báo lỗi
          NotificationDialog.showError(
            context: context,
            title: 'Lỗi',
            message: result['message'] ??
                'Không thể cập nhật hồ sơ. Vui lòng thử lại sau.',
            primaryButtonText: 'Đóng',
            primaryAction: () {
              // Dialog tự đóng
            },
          );
        }
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });
        NotificationDialog.showError(
          context: context,
          title: 'Lỗi',
          message: 'Không thể cập nhật hồ sơ: $e',
          primaryButtonText: 'Đóng',
          primaryAction: () {
            // Dialog tự đóng
          },
        );
      }
    }
  }

  // Mở dialog để chọn nguồn ảnh (camera hoặc thư viện)
  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          title: Text('Chọn nguồn ảnh',
              style: TextStyle(color: AppColors.fontBlack)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: ListTile(
                    leading: Icon(Icons.photo_library,
                        color: AppColors.primaryColor),
                    title: Text('Thư viện ảnh',
                        style: TextStyle(color: AppColors.fontBlack)),
                    subtitle: Text('Chọn từ thư viện ảnh của bạn',
                        style: TextStyle(color: AppColors.greyFont)),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _getImageFromSource(ImageSource.gallery);
                  },
                ),
                Divider(color: AppColors.dividerColor),
                GestureDetector(
                  child: ListTile(
                    leading:
                        Icon(Icons.photo_camera, color: AppColors.primaryColor),
                    title: Text('Máy ảnh',
                        style: TextStyle(color: AppColors.fontBlack)),
                    subtitle: Text('Chụp ảnh mới',
                        style: TextStyle(color: AppColors.greyFont)),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _getImageFromSource(ImageSource.camera);
                  },
                ),
                Divider(color: AppColors.dividerColor),
                GestureDetector(
                  child: ListTile(
                    leading: Icon(Icons.face, color: AppColors.primaryColor),
                    title: Text('Ảnh có sẵn',
                        style: TextStyle(color: AppColors.fontBlack)),
                    subtitle: Text('Chọn từ danh sách ảnh đại diện có sẵn',
                        style: TextStyle(color: AppColors.greyFont)),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showPresetAvatarsDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Lấy ảnh từ nguồn được chọn (camera hoặc thư viện)
  Future<void> _getImageFromSource(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800, // Giới hạn kích thước ảnh
        maxHeight: 800,
        imageQuality: 85, // Giảm chất lượng xuống 85% để giảm kích thước
      );

      if (pickedFile != null) {
        // Kiểm tra kích thước file
        File file = File(pickedFile.path);
        int sizeInBytes = await file.length();
        double sizeInMB = sizeInBytes / (1024 * 1024);

        if (sizeInMB > 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Ảnh quá lớn (${sizeInMB.toStringAsFixed(1)}MB). Vui lòng chọn ảnh nhỏ hơn 2MB.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Hiển thị dialog chọn ảnh đại diện có sẵn
  Future<void> _showPresetAvatarsDialog() async {
    // Danh sách các ảnh đại diện có sẵn - Cập nhật theo file thực tế
    final List<Map<String, dynamic>> presetAvatars = [
      {
        'name': 'Xanh dương', // Tên tiếng Việt phù hợp
        'image': 'assets/images/avatars/avatar1.png', // File PNG có sẵn
        'type': 'asset'
      },
      {
        'name': 'Xanh lá', // Tên tiếng Việt phù hợp
        'image': 'assets/images/avatars/avatar2.jpg', // File JPG có sẵn
        'type': 'asset'
      },
      {
        'name': 'Vàng', // Tên tiếng Việt phù hợp
        'image': 'assets/images/avatars/avatar3.png', // File PNG có sẵn
        'type': 'asset'
      },
      {
        'name': 'Đỏ', // Tên tiếng Việt phù hợp
        'image': 'assets/images/avatars/avatar4.png', // File PNG có sẵn
        'type': 'asset'
      },
      {
        'name': 'Google Default',
        'image':
            'https://lh3.googleusercontent.com/-XdUIqdMkCWA/AAAAAAAAAAI/AAAAAAAAAAA/4252rscbv5M/photo.jpg',
        'type': 'network'
      },
    ];

    final selectedAvatar = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.cardColor,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chọn ảnh đại diện',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.greyFont),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: double.maxFinite,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: presetAvatars.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(presetAvatars[index]);
                        },
                        child: Column(
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      AppColors.primaryColor.withOpacity(0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowColor,
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: presetAvatars[index]['type'] == 'asset'
                                    ? Image.asset(
                                        presetAvatars[index]['image'],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          print("Error loading avatar: $error");
                                          return Container(
                                            color: Colors.grey.shade200,
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      )
                                    : Image.network(
                                        presetAvatars[index]['image'],
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              color: AppColors.primaryColor,
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Center(
                                            child: Icon(
                                              Icons.error_outline,
                                              color: Colors.red,
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              presetAvatars[index]['name'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.fontBlack,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeController.isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      foregroundColor: AppColors.greyFont,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Hủy',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedAvatar != null) {
      setState(() {
        if (selectedAvatar['type'] == 'network') {
          // Đây là ảnh từ mạng, cập nhật URL trực tiếp
          _profile.photo = selectedAvatar['image'];
          // Xóa _imageFile để không gửi lên server lại
          _imageFile = null;
        } else {
          // Đây là ảnh asset thông thường, ta lưu đường dẫn
          String assetPath = selectedAvatar['image'];

          // Đánh dấu đây là asset để hiển thị đúng loại ảnh
          _profile.photo = 'asset://$assetPath';

          // Xóa _imageFile để không gửi lên server lại
          _imageFile = null;

          // Lưu loại avatar đã chọn để xử lý khi lưu
          _profile.avatarType = 'preset_avatar';
          _profile.avatarAssetPath = assetPath;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarPadding = getAppBarPadding();
    final profileState = ref.watch(profileProvider);
    final isLoading = profileState.updateStatus == UpdateStatus.loading ||
        profileState.isImageUploading ||
        _isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        elevation: 0,
        title: Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ChatIconBadge(size: 26),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryColor),
                  SizedBox(height: 16),
                  Text(
                    profileState.isImageUploading
                        ? 'Đang tải ảnh lên...'
                        : 'Đang cập nhật thông tin...',
                    style: TextStyle(color: AppColors.greyFont),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Image Section with Color Background
                  Container(
                    width: double.infinity,
                    color: AppColors.primaryColor,
                    padding: EdgeInsets.only(top: 20, bottom: 30),
                    child: Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Avatar container
                          Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.cardColor,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowColor,
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _imageFile != null
                                  ? Image.file(
                                      File(_imageFile!.path),
                                      fit: BoxFit.cover,
                                    )
                                  : _getProfileImage(),
                            ),
                          ),

                          // Camera button
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.cardColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.shadowColor,
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Form fields
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name field
                          _buildFormField(
                            label: 'Họ và tên',
                            initialValue: _profile.full_name,
                            icon: Icons.person,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập tên của bạn';
                              }
                              return null;
                            },
                            onSaved: (value) => _profile.full_name = value!,
                          ),
                          SizedBox(height: 20),

                          // Email field
                          _buildFormField(
                            label: 'Email',
                            initialValue: _profile.email,
                            icon: Icons.email,
                            readOnly: true,
                            suffixIcon: Icons.lock,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập email của bạn';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Vui lòng nhập email hợp lệ';
                              }
                              return null;
                            },
                            onSaved: (value) => _profile.email = value!,
                          ),
                          SizedBox(height: 20),

                          // Phone field
                          _buildFormField(
                            label: 'Số điện thoại',
                            initialValue: _profile.phone,
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập số điện thoại của bạn';
                              }
                              if (!RegExp(r'^(0|\+84)[3-9][0-9]{8}$')
                                  .hasMatch(value)) {
                                return 'Số điện thoại không hợp lệ';
                              }
                              return null;
                            },
                            onSaved: (value) => _profile.phone = value!,
                          ),
                          SizedBox(height: 20),

                          // Address field
                          _buildFormField(
                            label: 'Địa chỉ',
                            initialValue: _profile.address,
                            icon: Icons.home,
                            maxLines: 2,
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  value.length < 5) {
                                return 'Địa chỉ phải có ít nhất 5 ký tự';
                              }
                              return null;
                            },
                            onSaved: (value) => _profile.address = value ?? '',
                          ),
                          SizedBox(height: 30),

                          // Save button
                          Container(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSubmitting
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Đang lưu...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'Lưu hồ sơ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper method to create a default avatar with the first letter of the name
  Widget _buildDefaultAvatar(String name) {
    String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.primaryDarkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Helper method to build form fields with consistent styling
  Widget _buildFormField({
    required String label,
    required String initialValue,
    required IconData icon,
    bool readOnly = false,
    IconData? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.greyFont,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          readOnly: readOnly,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 16,
            color: readOnly ? AppColors.greyFont : AppColors.fontBlack,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon,
                color: AppColors.primaryColor.withOpacity(0.7), size: 20),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: AppColors.greyFont, size: 20)
                : null,
            filled: true,
            fillColor: AppColors.cardColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
          onSaved: onSaved,
        ),
      ],
    );
  }

  // Helper method to build Google icon
  Widget _buildGoogleIcon({required double size}) {
    // Google logo colors
    final List<Color> googleColors = [
      Color(0xFF4285F4), // Google Blue
      Color(0xFF34A853), // Google Green
      Color(0xFFFBBC05), // Google Yellow
      Color(0xFFEA4335), // Google Red
    ];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: GoogleLogoPainter(colors: googleColors),
      ),
    );
  }

  // Biểu tượng G cho Google Account
  Widget _buildGoogleGIcon({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          Center(
            child: Text(
              'G',
              style: TextStyle(
                fontSize: size * 0.6,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4285F4), // Google Blue
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getProfileImage() {
    if (_profile.photo.isNotEmpty && _profile.photo != 'null') {
      if (_profile.photo.startsWith('http') ||
          _profile.photo.startsWith('https')) {
        // Hiển thị ảnh từ URL
        return Image.network(
          _profile.photo,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print("Lỗi hiển thị ảnh: $error");
            return _buildDefaultAvatar(_profile.full_name);
          },
        );
      } else if (_profile.photo.startsWith('asset://')) {
        // Hiển thị ảnh từ asset
        String assetPath = _profile.photo.replaceFirst('asset://', '');
        return Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print("Lỗi hiển thị ảnh asset: $error");
            return _buildDefaultAvatar(_profile.full_name);
          },
        );
      }
    }
    // Mặc định nếu không có ảnh
    return _buildDefaultAvatar(_profile.full_name);
  }
}

// Google Logo Painter
class GoogleLogoPainter extends CustomPainter {
  final List<Color> colors;

  GoogleLogoPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2.5;

    // Simplified Google 'G' shape
    Path path = Path()
      ..moveTo(centerX, centerY - radius * 0.7)
      ..lineTo(centerX + radius * 0.7, centerY - radius * 0.7)
      ..arcToPoint(
        Offset(centerX + radius * 0.7, centerY + radius * 0.7),
        radius: Radius.circular(radius * 0.7),
        clockwise: true,
      )
      ..lineTo(centerX - radius * 0.7, centerY + radius * 0.7)
      ..arcToPoint(
        Offset(centerX - radius * 0.7, centerY - radius * 0.7),
        radius: Radius.circular(radius * 0.7),
        clockwise: true,
      )
      ..close();

    // Draw simplified G in Google Blue
    paint.color = colors[0]; // Google Blue
    canvas.drawPath(path, paint);

    // Draw inner white circle to create the 'G' shape
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius * 0.4,
      paint,
    );

    // Draw the right part to complete the 'G'
    paint.color = colors[0]; // Google Blue
    Path rightPart = Path()
      ..moveTo(centerX, centerY)
      ..lineTo(centerX + radius * 0.7, centerY)
      ..lineTo(centerX + radius * 0.7, centerY + radius * 0.25)
      ..arcToPoint(
        Offset(centerX + radius * 0.4, centerY),
        radius: Radius.circular(radius * 0.3),
        clockwise: false,
      )
      ..close();

    canvas.drawPath(rightPart, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
