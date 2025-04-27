class SiteSetting {
  int id;
  String company_name;
  String web_title;
  String address;
  String logo;
  String email;
  String short_name;
  String icon;
  String hotline;
  String paymentinfo;
  String lazada;
  String shopee;
  String facebook;
  String memory;

  SiteSetting({
    required this.id,
    required this.company_name,
    this.web_title = "",
    this.address = "",
    required this.logo,
    this.email = '',
    this.short_name = '',
    this.icon = '',
    this.hotline = '',
    this.paymentinfo = '',
    this.lazada = '',
    this.shopee = '',
    this.facebook = '',
    this.memory = '',
  });

  // Tạo phương thức từ JSON
  factory SiteSetting.fromJson(Map<String, dynamic> json) {
    return SiteSetting(
      id: json['id'],
      company_name: json['company_name'],
      web_title: json['web_title'] ?? '',
      address: json['address'] ?? '',
      logo: json['logo'],
      email: json['email'] ?? '',
      short_name: json['short_name'] ?? '',
      icon: json['icon'] ?? '',
      hotline: json['hotline'] ?? '',
      paymentinfo: json['paymentinfo'] ?? '',
      lazada: json['lazada'] ?? '',
      facebook: json['facebook'] ?? '',
      shopee: json['shopee'] ?? '',
      memory: json['memory'] ?? '',
    );
  }

  // Chuyển đổi Profile thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': company_name,
      'web_title': web_title,
      'address': address,
      'logo': logo,
      'email': email,
      'short_name': short_name,
      'icon': icon,
      'hotline': hotline,
      'paymentinfo': paymentinfo,
      'lazada': lazada,
      'facebook': facebook,
      'shopee': shopee,
      'memory': memory,
    };
  }

  SiteSetting copyWith({
    int? id,
    String? company_name,
    String? web_title,
    String? address,
    String? logo,
    String? email,
    String? short_name,
    String? icon,
    String? hotline,
    String? paymentinfo,
    String? lazada,
    String? shopee,
    String? facebook,
    String? memory,
  }) {
    return SiteSetting(
      id: id ?? this.id,
      company_name: company_name ?? this.company_name,
      web_title: web_title ?? this.web_title,
      address: address ?? this.address,
      logo: logo ?? this.logo,
      email: email ?? this.email,
      short_name: short_name ?? this.short_name,
      icon: icon ?? this.icon,
      hotline: hotline ?? this.hotline,
      paymentinfo: paymentinfo ?? this.paymentinfo,
      lazada: lazada ?? this.lazada,
      shopee: shopee ?? this.shopee,
      facebook: facebook ?? this.facebook,
      memory: memory ?? this.memory,
    );
  }
}
