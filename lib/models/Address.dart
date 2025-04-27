class Address {
  final int id;
  final String fullName;
  final String phone;
  final String address;

  Address({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.address,
  });

  // Hàm chuyển từ JSON sang Object
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? 0, // Nếu API không trả về id, gán mặc định là 0
      fullName: json['full_name'] ?? 'Unknown', // Tránh lỗi null
      phone: json['phone'] ?? 'No phone',
      address: json['address'] ?? 'No address',
    );
  }

  // Hàm chuyển từ Object sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'address': address,
    };
  }
}
