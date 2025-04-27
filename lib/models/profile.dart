class Profile {
  String full_name;
  String phone;
  String address;
  String photo;
  String email;
  String username;
  String? avatarType; // Loại avatar: network, asset_svg, asset_png, ...
  String? avatarAssetPath; // Đường dẫn đến asset nếu sử dụng asset
  bool isGoogleAccount = false; // Xác định nếu là tài khoản Google

  Profile({
    required this.full_name,
    required this.phone,
    required this.address,
    required this.photo,
    required this.email,
    required this.username,
    this.avatarType,
    this.avatarAssetPath,
    this.isGoogleAccount = false,
  });

  // Tạo phương thức từ JSON
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      full_name: json['full_name'],
      phone: json['phone'],
      address: json['address'],
      photo: json['avatar_url'],
      email: json['email'],
      username: json['username'],
      avatarType: json['avatar_type'],
      avatarAssetPath: json['avatar_asset_path'],
      isGoogleAccount: json['is_google_account'] ?? false,
    );
  }

  // Chuyển đổi Profile thành JSON
  Map<String, dynamic> toJson() {
    return {
      'full_name': full_name,
      'phone': phone,
      'address': address,
      'avatar_url': photo,
      'username': username,
      'email': email,
      'avatar_type': avatarType,
      'avatar_asset_path': avatarAssetPath,
      'is_google_account': isGoogleAccount,
    };
  }

  Profile copyWith({
    String? full_name,
    String? phone,
    String? address,
    String? photo,
    String? email,
    String? username,
    String? avatarType,
    String? avatarAssetPath,
    bool? isGoogleAccount,
  }) {
    return Profile(
      full_name: full_name ?? this.full_name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      photo: photo ?? this.photo,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarType: avatarType ?? this.avatarType,
      avatarAssetPath: avatarAssetPath ?? this.avatarAssetPath,
      isGoogleAccount: isGoogleAccount ?? this.isGoogleAccount,
    );
  }
}
