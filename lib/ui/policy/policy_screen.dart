import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/widget_utils.dart';

// Enum để phân loại các loại chính sách
enum PolicyType {
  privacy,
  terms,
  returns,
  warranty,
  shipping,
}

class PolicyScreen extends StatefulWidget {
  final PolicyType policyType;

  const PolicyScreen({Key? key, required this.policyType}) : super(key: key);

  @override
  _PolicyScreenState createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    isDarkMode = ThemeController.isDarkMode;
    ThemeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {
      isDarkMode = ThemeController.isDarkMode;
    });
  }

  String _getPolicyTitle() {
    switch (widget.policyType) {
      case PolicyType.privacy:
        return "Chính sách bảo mật";
      case PolicyType.terms:
        return "Điều khoản và quy định";
      case PolicyType.returns:
        return "Chính sách hoàn trả";
      case PolicyType.warranty:
        return "Chính sách bảo hành";
      case PolicyType.shipping:
        return "Chính sách giao vận";
    }
  }

  List<Map<String, String>> _getPolicyContent() {
    switch (widget.policyType) {
      case PolicyType.privacy:
        return [
          {
            "title": "1. Thu thập thông tin",
            "content":
                "Chúng tôi thu thập thông tin cá nhân của bạn khi bạn đăng ký tài khoản, đặt hàng hoặc liên hệ với chúng tôi. Thông tin cá nhân có thể bao gồm tên, địa chỉ email, số điện thoại, địa chỉ thanh toán và giao hàng."
          },
          {
            "title": "2. Sử dụng thông tin",
            "content":
                "Thông tin cá nhân của bạn được sử dụng để xử lý đơn hàng, cung cấp dịch vụ khách hàng, cải thiện trải nghiệm mua sắm và gửi thông tin cập nhật về sản phẩm hoặc khuyến mãi (nếu bạn đồng ý)."
          },
          {
            "title": "3. Bảo vệ thông tin",
            "content":
                "Chúng tôi cam kết bảo vệ thông tin cá nhân của bạn bằng các biện pháp bảo mật vật lý, điện tử và thủ tục. Chúng tôi không bán, trao đổi hoặc cho thuê thông tin cá nhân của bạn cho bên thứ ba."
          },
          {
            "title": "4. Cookie và công nghệ theo dõi",
            "content":
                "Chúng tôi sử dụng cookie để cải thiện trải nghiệm của bạn trên trang web và ứng dụng của chúng tôi. Bạn có thể kiểm soát cookie thông qua cài đặt trình duyệt của mình."
          },
          {
            "title": "5. Quyền của bạn",
            "content":
                "Bạn có quyền truy cập, sửa đổi hoặc xóa thông tin cá nhân của mình bất kỳ lúc nào. Liên hệ với chúng tôi nếu bạn muốn thực hiện quyền này."
          }
        ];
      case PolicyType.terms:
        return [
          {
            "title": "1. Điều khoản sử dụng",
            "content":
                "Bằng cách truy cập và sử dụng ứng dụng của chúng tôi, bạn đồng ý tuân thủ các điều khoản và điều kiện này. Nếu bạn không đồng ý với bất kỳ phần nào của điều khoản, vui lòng không sử dụng ứng dụng của chúng tôi."
          },
          {
            "title": "2. Tài khoản người dùng",
            "content":
                "Khi tạo tài khoản, bạn phải cung cấp thông tin chính xác và cập nhật. Bạn chịu trách nhiệm duy trì tính bảo mật của tài khoản và mật khẩu của mình."
          },
          {
            "title": "3. Quyền sở hữu trí tuệ",
            "content":
                "Tất cả nội dung trên ứng dụng, bao gồm văn bản, đồ họa, logo và hình ảnh, đều thuộc sở hữu của chúng tôi hoặc các nhà cung cấp nội dung của chúng tôi và được bảo vệ bởi luật sở hữu trí tuệ."
          },
          {
            "title": "4. Hành vi bị cấm",
            "content":
                "Bạn không được sử dụng ứng dụng cho bất kỳ mục đích bất hợp pháp hoặc bị cấm, hoặc gây hại đến hoạt động của ứng dụng hoặc bất kỳ người dùng nào khác."
          },
          {
            "title": "5. Thay đổi điều khoản",
            "content":
                "Chúng tôi có thể cập nhật điều khoản này vào bất kỳ lúc nào. Việc tiếp tục sử dụng ứng dụng sau khi thay đổi đồng nghĩa với việc bạn chấp nhận các điều khoản mới."
          }
        ];
      case PolicyType.returns:
        return [
          {
            "title": "1. Thời gian hoàn trả",
            "content":
                "Bạn có thể trả lại sản phẩm trong vòng 30 ngày kể từ ngày nhận hàng. Sản phẩm phải còn nguyên trạng, chưa qua sử dụng và trong bao bì gốc."
          },
          {
            "title": "2. Quy trình hoàn trả",
            "content":
                "Để bắt đầu quy trình hoàn trả, vui lòng liên hệ với bộ phận dịch vụ khách hàng của chúng tôi. Bạn sẽ nhận được hướng dẫn chi tiết về cách trả lại sản phẩm."
          },
          {
            "title": "3. Hoàn tiền",
            "content":
                "Sau khi nhận được sản phẩm trả lại và kiểm tra, chúng tôi sẽ xử lý hoàn tiền trong vòng 7-14 ngày làm việc. Hoàn tiền sẽ được thực hiện qua phương thức thanh toán ban đầu."
          },
          {
            "title": "4. Sản phẩm không đủ điều kiện",
            "content":
                "Một số sản phẩm không thể trả lại vì lý do vệ sinh hoặc bảo vệ sức khỏe. Sản phẩm đã qua sử dụng, bị hư hỏng hoặc thiếu bao bì gốc có thể không đủ điều kiện hoàn trả."
          },
          {
            "title": "5. Chi phí vận chuyển",
            "content":
                "Chi phí vận chuyển cho việc trả lại sản phẩm do khách hàng chịu, trừ khi sản phẩm bị lỗi hoặc giao nhầm."
          }
        ];
      case PolicyType.warranty:
        return [
          {
            "title": "1. Thời hạn bảo hành",
            "content":
                "Các sản phẩm của chúng tôi được bảo hành trong thời gian 12 tháng kể từ ngày mua cho các lỗi về sản xuất."
          },
          {
            "title": "2. Phạm vi bảo hành",
            "content":
                "Bảo hành chỉ áp dụng cho các lỗi về vật liệu và tay nghề trong điều kiện sử dụng bình thường. Bảo hành không bao gồm hao mòn thông thường hoặc hư hỏng do sử dụng không đúng cách."
          },
          {
            "title": "3. Quy trình bảo hành",
            "content":
                "Nếu sản phẩm của bạn cần bảo hành, vui lòng liên hệ với bộ phận hỗ trợ khách hàng với biên lai mua hàng và mô tả về vấn đề."
          },
          {
            "title": "4. Sửa chữa hoặc thay thế",
            "content":
                "Chúng tôi sẽ sửa chữa hoặc thay thế sản phẩm bị lỗi theo quyết định của chúng tôi. Trong trường hợp không thể sửa chữa hoặc thay thế, chúng tôi có thể cung cấp khoản hoàn tiền."
          },
          {
            "title": "5. Giới hạn bảo hành",
            "content":
                "Bảo hành này không áp dụng cho hư hỏng do tai nạn, sử dụng sai, lạm dụng, cháy, nước, thiên tai hoặc sửa đổi trái phép."
          }
        ];
      case PolicyType.shipping:
        return [
          {
            "title": "1. Thời gian giao hàng",
            "content":
                "Thời gian giao hàng dự kiến là 2-5 ngày làm việc cho các khu vực đô thị và 5-7 ngày làm việc cho các khu vực ngoại thành và nông thôn, tùy thuộc vào địa điểm giao hàng."
          },
          {
            "title": "2. Phí vận chuyển",
            "content":
                "Phí vận chuyển được tính dựa trên trọng lượng, kích thước của sản phẩm và địa điểm giao hàng. Phí vận chuyển sẽ được hiển thị trong quá trình thanh toán."
          },
          {
            "title": "3. Miễn phí vận chuyển",
            "content":
                "Đơn hàng có tổng giá trị từ 500.000đ trở lên sẽ được miễn phí vận chuyển cho các khu vực nội thành."
          },
          {
            "title": "4. Theo dõi đơn hàng",
            "content":
                "Sau khi đơn hàng được xác nhận, bạn sẽ nhận được email xác nhận đơn hàng với mã theo dõi. Bạn có thể theo dõi trạng thái đơn hàng của mình thông qua ứng dụng hoặc trang web của chúng tôi."
          },
          {
            "title": "5. Giao hàng quốc tế",
            "content":
                "Chúng tôi cung cấp dịch vụ giao hàng quốc tế đến một số quốc gia. Thời gian giao hàng và phí vận chuyển quốc tế sẽ khác với giao hàng trong nước."
          }
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final policyContent = _getPolicyContent();
    final appBarPadding = getAppBarPadding();
    final themeData = Theme.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        title: Text(
          _getPolicyTitle(),
          style: TextStyle(
            color: AppColors.fontLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: AppColors.fontLight,
              size: 20,
            ),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDarkMode
                        ? AppColors.primaryColor.withOpacity(0.2)
                        : AppColors.primaryColor.withOpacity(0.05),
                    isDarkMode ? const Color(0xFF121212) : Colors.white,
                  ],
                  stops: isDarkMode ? const [0.0, 0.35] : const [0.0, 0.3],
                ),
              ),
            ),
          ),
          // Original content
          Container(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPolicyHeader(),
                  SizedBox(height: 20),
                  ...policyContent
                      .map((section) => _buildPolicySection(section)),
                  SizedBox(height: 20),
                  _buildContactSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyHeader() {
    String headerImage;
    String headerText;

    switch (widget.policyType) {
      case PolicyType.privacy:
        headerImage = "security.svg";
        headerText =
            "Chúng tôi cam kết bảo vệ quyền riêng tư và thông tin cá nhân của bạn.";
        break;
      case PolicyType.terms:
        headerImage = "Document.svg";
        headerText =
            "Vui lòng đọc kỹ các điều khoản và điều kiện sử dụng dịch vụ của chúng tôi.";
        break;
      case PolicyType.returns:
        headerImage = "Rotate_Left.svg";
        headerText =
            "Chúng tôi muốn bạn hoàn toàn hài lòng với mọi giao dịch mua hàng.";
        break;
      case PolicyType.warranty:
        headerImage = "Question.svg";
        headerText =
            "Chúng tôi cung cấp bảo hành cho sản phẩm để đảm bảo sự hài lòng của bạn.";
        break;
      case PolicyType.shipping:
        headerImage = "shipping_location.svg";
        headerText =
            "Chúng tôi cam kết giao hàng đúng hẹn và an toàn đến tay bạn.";
        break;
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: isDarkMode ? AppColors.cardColor : AppColors.fontLight,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 15,
            cornerSmoothing: 0.6,
          ),
        ),
        shadows: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          getSvgImage(headerImage, 50.0, color: AppColors.primaryColor),
          SizedBox(height: 16),
          Text(
            headerText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.fontBlack,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(Map<String, String> section) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: ShapeDecoration(
        color: isDarkMode ? AppColors.cardColor : AppColors.fontLight,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 12,
            cornerSmoothing: 0.6,
          ),
        ),
        shadows: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.06),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        backgroundColor: Colors.transparent,
        collapsedIconColor: AppColors.primaryColor,
        iconColor: AppColors.primaryColor,
        title: Text(
          section["title"]!,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.fontBlack,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(
              section["content"]!,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.greyFont,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: isDarkMode
            ? AppColors.primaryColor.withOpacity(0.2)
            : AppColors.primaryColor.withOpacity(0.1),
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 15,
            cornerSmoothing: 0.6,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Cần hỗ trợ thêm?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.fontBlack,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Nếu bạn có bất kỳ câu hỏi nào về ${_getPolicyTitle().toLowerCase()}, vui lòng liên hệ với chúng tôi qua:",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.greyFont,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          _buildContactRow(Icons.email_outlined, "support@shoplite.vn"),
          SizedBox(height: 8),
          _buildContactRow(Icons.phone_outlined, "1800-1234"),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Xử lý sự kiện khi nút được nhấn
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonColor,
                foregroundColor: AppColors.fontLight,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: Text(
                "Liên hệ hỗ trợ",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primaryColor,
        ),
        SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.fontBlack,
          ),
        ),
      ],
    );
  }
}
