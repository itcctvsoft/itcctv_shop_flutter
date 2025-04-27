import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:shoplite/providers/profile_provider.dart';
import 'package:shoplite/ui/profile/edit_profile_screen.dart';
import 'package:shoplite/ui/order/order_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/apilist.dart';
import '../../constants/widget_utils.dart';
import '../../constants/color_data.dart';
import '../../constants/enum.dart';
import 'package:shoplite/models/profile.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';
import 'package:dio/dio.dart';
import 'dart:io'; // Import for Platform
import 'package:flutter/foundation.dart' show kIsWeb; // Import for kIsWeb
import 'package:flutter_svg/flutter_svg.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreen();
}

class _ProfileScreen extends ConsumerState<ProfileScreen> {
  bool isLoading = true;
  bool _isGoogleAccount = false;
  Profile? currentProfile;

  @override
  void initState() {
    super.initState();
    _checkIfGoogleAccount();
    _loadProfile();
  }

  // Kiểm tra nếu tài khoản đăng nhập từ Google
  Future<void> _checkIfGoogleAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final googleId = prefs.getString('googleId');
    setState(() {
      _isGoogleAccount = googleId != null && googleId.isNotEmpty;
    });
  }

  // Lấy thông tin người dùng từ provider và API
  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Thử lấy thông tin từ SharedPreferences trước
      await _loadProfileFromPrefs();

      // Sau đó gọi API để cập nhật
      await fetchProfile();
    } catch (e) {
      print("Lỗi khi tải profile: $e");

      // Hiển thị thông báo lỗi cho người dùng
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Không thể kết nối đến máy chủ. Đang hiển thị dữ liệu đã lưu.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Lấy thông tin profile từ SharedPreferences
  Future<void> _loadProfileFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Kiểm tra xem có dữ liệu đã lưu không
      String? fullName = prefs.getString('userName');
      String? email = prefs.getString('userEmail');
      String? phone = prefs.getString('userPhone') ?? '';
      String? address = prefs.getString('userAddress') ?? '';
      String? photo = prefs.getString('userPhoto') ?? '';
      String? username = prefs.getString('username');

      // Nếu có ít nhất thông tin cơ bản (tên và email)
      if (fullName != null && email != null) {
        // Đảm bảo username không null bằng cách sử dụng email nếu cần
        String nonNullUsername = username ?? email.split('@')[0];

        setState(() {
          currentProfile = Profile(
            full_name: fullName,
            email: email,
            phone: phone,
            address: address,
            photo: photo,
            username: nonNullUsername,
          );
        });

        print("Đã tải profile từ bộ nhớ cục bộ: $fullName, $email");
      } else {
        print("Không tìm thấy dữ liệu profile đã lưu");
      }
    } catch (e) {
      print("Lỗi khi tải profile từ SharedPreferences: $e");
    }
  }

  // Lấy thông tin người dùng từ API
  Future<void> fetchProfile() async {
    setState(() {
      isLoading = true;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      print(
          "Đang gọi API lấy profile với token: ${token.length > 10 ? token.substring(0, 10) + '...' : token}");

      final dio = Dio();

      // Sử dụng API endpoint
      Response response = await dio.get(
        api_profile, // Sử dụng api_profile từ apilist.dart
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

      print("Phản hồi API profile: Mã trạng thái=${response.statusCode}");
      print("Dữ liệu: ${response.data}");

      if (response.statusCode == 200) {
        var data = response.data;

        // API trả về dữ liệu profile trực tiếp
        setState(() {
          currentProfile = Profile(
            full_name: data['full_name'] ?? '',
            email: data['email'] ?? '',
            phone: data['phone'] ?? '',
            address: data['address'] ?? '',
            photo: data['photo'] ?? '',
            username: data['email']?.toString().split('@')[0] ?? '',
          );
          isLoading = false;
        });

        print(
            "Thông tin profile đã được cập nhật: ${currentProfile!.full_name}, Ảnh: ${currentProfile!.photo}");

        // Lưu thông tin vào SharedPreferences
        await _updateSharedPreferences(currentProfile!);
      } else if (response.statusCode == 401) {
        print("Lỗi xác thực: Token không hợp lệ hoặc đã hết hạn");
        setState(() {
          isLoading = false;
        });
      } else {
        print("Lỗi API: ${response.statusCode} - ${response.data}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi khi tải profile: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Cập nhật SharedPreferences với thông tin hồ sơ mới
  Future<void> _updateSharedPreferences(Profile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', profile.full_name);
    await prefs.setString('userEmail', profile.email);
    await prefs.setString('userPhone', profile.phone);
    await prefs.setString('userAddress', profile.address);
    await prefs.setString('userPhoto', profile.photo);
    await prefs.setString('username', profile.username);
  }

  // Phương thức quay lại màn hình trước đó
  _requestPop() {
    Constant.backToFinish(context);
  }

  // Kiểm tra xem URL có hợp lệ không
  bool isValidImageUrl(String url) {
    if (url.isEmpty || url == 'null') return false;

    // Kiểm tra chuỗi URL có chứa đuôi tệp hình ảnh phổ biến không
    final imageExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.svg',
      '.bmp'
    ];
    bool hasValidExtension =
        imageExtensions.any((ext) => url.toLowerCase().contains(ext));

    // Kiểm tra xem URL có bắt đầu bằng http/https không
    bool hasValidProtocol =
        url.startsWith('http://') || url.startsWith('https://');

    // Đặc biệt xử lý các URL localhost
    bool hasLocalhost = url.contains('127.0.0.1') || url.contains('localhost');
    bool needsConversion = hasLocalhost && !kIsWeb && Platform.isAndroid;

    if (needsConversion) {
      print("Cảnh báo: URL hình ảnh sử dụng localhost: $url");
      print("Trên thiết bị Android, cần sử dụng 10.0.2.2 thay cho localhost");
    }

    return hasValidProtocol && hasValidExtension;
  }

  // Tạo widget avatar mặc định với chữ cái đầu
  Widget _buildDefaultAvatar(String name) {
    String initial = '?';
    if (name.isNotEmpty) {
      initial = name[0].toUpperCase();
    }

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

  // Chuyển đổi URL localhost sang URL phù hợp với thiết bị
  String _convertLocalhostUrl(String url) {
    if (url.isEmpty) return url;

    // Chỉ xử lý khi URL chứa localhost hoặc 127.0.0.1
    if (url.contains('localhost') || url.contains('127.0.0.1')) {
      if (kIsWeb) {
        // Trên web giữ nguyên, vì localhost là server
        return url;
      } else if (Platform.isAndroid) {
        // Trên Android, thay thế localhost bằng 10.0.2.2 (IP của máy host từ emulator)
        return url
            .replaceAll('localhost', '10.0.2.2')
            .replaceAll('127.0.0.1', '10.0.2.2');
      } else if (Platform.isIOS) {
        // Trên iOS simulator, localhost là máy host
        return url;
      }
    }
    return url;
  }

  // Lấy Widget hiển thị avatar từ URL hoặc chữ cái đầu
  Widget getAvatarWidget(Profile profile, double size) {
    if (isValidImageUrl(profile.photo)) {
      // Nếu có ảnh hợp lệ từ URL, hiển thị từ URL
      String imageUrl = _convertLocalhostUrl(profile.photo);
      print("Đang tải ảnh từ URL: $imageUrl (gốc: ${profile.photo})");

      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: primaryColor,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print("Lỗi hiển thị ảnh từ URL: $imageUrl - Lỗi: $error");
          return _buildDefaultAvatar(profile.full_name);
        },
      );
    } else if (profile.photo.startsWith('asset://')) {
      // Hiển thị ảnh từ asset
      String assetPath = profile.photo.replaceFirst('asset://', '');
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Lỗi hiển thị ảnh asset: $error");
          return _buildDefaultAvatar(profile.full_name);
        },
      );
    } else {
      // Không có ảnh hợp lệ, hiển thị avatar với chữ cái đầu
      return _buildDefaultAvatar(profile.full_name);
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final profileState = ref.watch(profileProvider);

    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double imgHeight = Constant.getPercentSize(screenHeight, 16);
    double appBarPadding = getAppBarPadding();

    return WillPopScope(
      onWillPop: () async {
        _requestPop();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          title: Text(
            'Hồ sơ của tôi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _requestPop,
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
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              )
            : currentProfile == null
                ? Center(
                    child: Text("Không thể tải thông tin hồ sơ"),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Profile Header with background
                        Container(
                          width: double.infinity,
                          color: AppColors.primaryColor,
                          child: Column(
                            children: [
                              SizedBox(height: 20),
                              // Profile photo container
                              Stack(
                                children: [
                                  Container(
                                    width: imgHeight,
                                    height: imgHeight,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.cardColor,
                                      border: Border.all(
                                          color: Colors.white, width: 3),
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
                                      child: getAvatarWidget(
                                          currentProfile!, imgHeight),
                                    ),
                                  ),
                                ],
                              ),
                              // Name
                              Padding(
                                padding: EdgeInsets.only(
                                    top: 16, left: 20, right: 20),
                                child: Text(
                                  currentProfile!.full_name,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // Email
                              Padding(
                                padding: EdgeInsets.only(
                                    top: 4, bottom: 25, left: 20, right: 20),
                                child: Text(
                                  currentProfile!.email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Contact Information Section
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Phone Number
                              _buildContactRow(
                                Icons.phone,
                                "Số điện thoại",
                                currentProfile!.phone.isNotEmpty
                                    ? currentProfile!.phone
                                    : "Chưa có thông tin",
                              ),
                              SizedBox(height: 20),
                              // Address
                              _buildContactRow(
                                Icons.home,
                                "Địa chỉ",
                                currentProfile!.address.isNotEmpty
                                    ? currentProfile!.address
                                    : "Chưa có thông tin",
                              ),
                            ],
                          ),
                        ),

                        Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.dividerColor,
                        ),

                        // Tài khoản Section
                        Container(
                          padding: EdgeInsets.all(20),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Tài khoản",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.fontBlack,
                                ),
                              ),
                              SizedBox(height: 16),
                              // Order History Button
                              _buildActionButton(
                                Icons.history,
                                "Lịch sử đơn hàng",
                                "Xem các đơn hàng đã đặt",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          OrderHistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 12),
                              // Edit Profile Button
                              _buildActionButton(
                                Icons.edit,
                                "Chỉnh sửa hồ sơ",
                                "Cập nhật thông tin cá nhân",
                                () async {
                                  if (currentProfile != null) {
                                    final updatedProfile = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProfileScreen(
                                          currentProfile: currentProfile!,
                                        ),
                                      ),
                                    );
                                    if (updatedProfile != null) {
                                      setState(() {
                                        currentProfile = updatedProfile;
                                      });
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget getSeparateDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: getAppBarPadding()),
      child: Divider(
        height: 1,
        color: Colors.grey.shade200,
      ),
    );
  }

  Widget getRowWidget(String title, String desc, String icon) {
    double iconSize = Constant.getHeightPercentSize(3.8);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: _getIconForName(icon, iconSize * 0.6),
          ),
        ),
        getHorSpace(Constant.getWidthPercentSize(2)),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: greyFont,
                ),
              ),
              getSpace(6),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: fontBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to get icon based on name
  Widget _getIconForName(String iconName, double size) {
    if (iconName == "phone.svg") {
      return Icon(Icons.phone, color: primaryColor, size: size);
    } else if (iconName == "address.svg") {
      return Icon(Icons.home, color: primaryColor, size: size);
    } else if (iconName == "email.svg") {
      return Icon(Icons.email, color: primaryColor, size: size);
    } else {
      return Icon(Icons.info, color: primaryColor, size: size);
    }
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryColor,
            size: 20,
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.greyFont,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.fontBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      IconData icon, String title, String subtitle, VoidCallback onPressed) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.fontBlack,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppColors.greyFont,
            fontSize: 12,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.grey.shade400),
        onTap: onPressed,
      ),
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

  // Hiển thị tùy chọn nhanh cho avatar
  Future<void> _showQuickAvatarOptions() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thay đổi ảnh đại diện',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.greyFont),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Tùy chọn 1: Chỉnh sửa đầy đủ (mở màn hình edit profile)
                    _buildAvatarOption(
                      icon: Icons.edit,
                      label: 'Chỉnh sửa đầy đủ',
                      onTap: () async {
                        Navigator.pop(context); // Đóng dialog
                        if (currentProfile != null) {
                          final updatedProfile = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                currentProfile: currentProfile!,
                              ),
                            ),
                          );
                          if (updatedProfile != null) {
                            setState(() {
                              currentProfile = updatedProfile;
                            });
                          }
                        }
                      },
                    ),
                    // Tùy chọn 2: Chọn nhanh từ ảnh có sẵn
                    _buildAvatarOption(
                      icon: Icons.face,
                      label: 'Ảnh có sẵn',
                      onTap: () {
                        Navigator.pop(context);
                        _showPresetAvatarsDialog();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      backgroundColor: ThemeController.isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Hủy'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget cho các tùy chọn avatar
  Widget _buildAvatarOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primaryColor,
              size: 30,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.fontBlack,
            ),
          ),
        ],
      ),
    );
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
          backgroundColor: AppColors.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                SizedBox(height: 5),
                Text(
                  'Ảnh có dấu khung cam là ảnh đang sử dụng',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.greyFont,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 15),
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
                      // Kiểm tra xem có phải avatar đang được chọn hay không
                      bool isCurrentAvatar = false;

                      if (currentProfile != null) {
                        if (presetAvatars[index]['type'] == 'asset' &&
                            currentProfile!.photo
                                .contains(presetAvatars[index]['image'])) {
                          isCurrentAvatar = true;
                        } else if (presetAvatars[index]['type'] == 'network' &&
                            currentProfile!.photo ==
                                presetAvatars[index]['image']) {
                          isCurrentAvatar = true;
                        }
                      }

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
                                  color: isCurrentAvatar
                                      ? Colors.orange
                                      : AppColors.primaryColor.withOpacity(0.5),
                                  width: isCurrentAvatar ? 3 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipOval(
                                    child: presetAvatars[index]['type'] ==
                                            'asset'
                                        ? Image.asset(
                                            presetAvatars[index]['image'],
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              print(
                                                  "Error loading avatar: $error");
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
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
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

                                  // Hiển thị biểu tượng đánh dấu trên ảnh đang dùng
                                  if (isCurrentAvatar)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              presetAvatars[index]['name'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrentAvatar
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isCurrentAvatar
                                    ? Colors.orange
                                    : AppColors.fontBlack,
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
                      backgroundColor: AppColors.cardColor,
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
      // Hiển thị loading overlay
      _showLoadingDialog('Đang cập nhật ảnh đại diện...');

      try {
        // Lưu avatar đã chọn trước
        Map<String, dynamic>? previousAvatar;
        if (currentProfile != null) {
          previousAvatar = {
            'photo': currentProfile!.photo,
            'avatarType': currentProfile!.avatarType,
            'avatarAssetPath': currentProfile!.avatarAssetPath,
          };
        }

        setState(() {
          if (selectedAvatar['type'] == 'network') {
            // Đây là ảnh từ mạng, cập nhật URL trực tiếp
            currentProfile?.photo = selectedAvatar['image'];
            currentProfile?.avatarType = 'network';
            currentProfile?.avatarAssetPath = null;
          } else {
            // Đây là ảnh asset thông thường, ta lưu đường dẫn
            String assetPath = selectedAvatar['image'];

            // Đánh dấu đây là asset để hiển thị đúng loại ảnh
            currentProfile?.photo = 'asset://$assetPath';

            // Lưu loại avatar đã chọn để xử lý khi lưu
            currentProfile?.avatarType = 'preset_avatar';
            currentProfile?.avatarAssetPath = assetPath;
          }
        });

        // Cập nhật profile trong SharedPreferences
        if (currentProfile != null) {
          await _updateSharedPreferences(currentProfile!);

          // Cập nhật lên server
          final profileNotifier = ref.read(profileProvider.notifier);
          final result = await profileNotifier.updateProfile(currentProfile!);

          // Đóng dialog loading
          Navigator.of(context).pop();

          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ảnh đại diện đã được cập nhật'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            // Khôi phục avatar cũ nếu cập nhật thất bại
            setState(() {
              if (previousAvatar != null) {
                currentProfile?.photo = previousAvatar['photo'];
                currentProfile?.avatarType = previousAvatar['avatarType'];
                currentProfile?.avatarAssetPath =
                    previousAvatar['avatarAssetPath'];
              }
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Không thể cập nhật ảnh đại diện: ${result['message']}'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          // Đóng dialog loading
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Đóng dialog loading nếu có lỗi
        Navigator.of(context).pop();

        print("Lỗi khi cập nhật ảnh đại diện: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi khi cập nhật ảnh đại diện'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Hiển thị dialog loading khi đang xử lý
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primaryColor),
                SizedBox(height: 20),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.fontBlack,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
