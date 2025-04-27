import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/payment_provider.dart';
import '../../constants/color_data.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'dart:developer' as developer;
import 'package:shoplite/widgets/chat_icon_badge.dart';
import 'package:shoplite/repositories/payment_repository.dart';
import 'package:shoplite/models/payment_transaction.dart';

// Import thêm để lấy userAgent
import 'dart:io' show Platform;

// Thêm lớp WebView đơn giản để xử lý thanh toán VNPay
class SimplePaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final double amount;

  SimplePaymentWebView({required this.paymentUrl, required this.amount});

  @override
  _SimplePaymentWebViewState createState() => _SimplePaymentWebViewState();
}

class _SimplePaymentWebViewState extends State<SimplePaymentWebView> {
  bool isLoading = true;
  String? currentUrl;
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          height: 70 + MediaQuery.of(context).padding.top,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDarkColor,
                AppColors.primaryColor,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withOpacity(0.2),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context, false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "VNPay Payment",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (webViewController != null) {
                        setState(() {
                          isLoading = true;
                        });
                        webViewController!.reload();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const ChatIconBadge(size: 26),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(
              url: WebUri(widget.paymentUrl),
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Accept':
                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
                'Accept-Language': 'vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7',
                'Cache-Control': 'max-age=0',
                'Connection': 'keep-alive',
              },
            ),
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                javaScriptEnabled: true,
                javaScriptCanOpenWindowsAutomatically: true,
                useOnLoadResource: true,
                transparentBackground: true,
                supportZoom: false,
              ),
              android: AndroidInAppWebViewOptions(
                useHybridComposition: true,
                safeBrowsingEnabled: false,
              ),
              ios: IOSInAppWebViewOptions(
                allowsInlineMediaPlayback: true,
              ),
            ),
            onWebViewCreated: (InAppWebViewController controller) {
              webViewController = controller;
              developer.log("🌐 WebView đã được tạo", name: "VNPay");

              // Xóa đoạn code gọi getOptions() gây lỗi
              developer.log(
                  "🔹 User-Agent: ${Platform.isAndroid ? 'Mozilla/5.0 (Linux; Android 11; Pixel 4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.104 Mobile Safari/537.36' : 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1'}",
                  name: "VNPay");
            },
            onLoadStart: (controller, url) {
              setState(() {
                isLoading = true;
                currentUrl = url.toString();
              });
              developer.log("🌐 Bắt đầu tải: ${url.toString()}", name: "VNPay");
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              developer.log(
                  "🔄 Đang chuyển hướng đến: ${navigationAction.request.url}",
                  name: "VNPay");
              return NavigationActionPolicy.ALLOW;
            },
            onLoadStop: (controller, url) {
              setState(() {
                isLoading = false;
                currentUrl = url.toString();
              });
              developer.log("✅ Tải hoàn tất: ${url.toString()}", name: "VNPay");

              // Inject JavaScript để debug
              controller.evaluateJavascript(source: '''
                console.log("Trang đã tải xong");
                if (document.body) {
                  console.log("Body height: " + document.body.scrollHeight);
                  console.log("QR elements: " + document.querySelectorAll('.qrcode-area').length);
                }
              ''');

              final urlString = url.toString();
              // Kiểm tra URL kết quả từ VNPay
              if (urlString.contains("vnpay-return") ||
                  urlString.contains("vnp_ResponseCode=") ||
                  urlString.contains("vnp_TransactionStatus=")) {
                // Kiểm tra kết quả thanh toán dựa trên mã phản hồi của VNPay
                final success = urlString.contains("vnp_ResponseCode=00") ||
                    urlString.contains("vnp_TransactionStatus=00");

                developer.log(
                    "💰 Kết quả thanh toán: ${success ? 'Thành công' : 'Thất bại'} - $urlString",
                    name: "VNPay");

                // Trích xuất mã đơn hàng từ URL
                String? orderId;
                if (urlString.contains("vnp_TxnRef=")) {
                  final txnRefPattern = RegExp(r"vnp_TxnRef=([^&]+)");
                  final match = txnRefPattern.firstMatch(urlString);
                  if (match != null && match.groupCount >= 1) {
                    orderId = match.group(1);

                    // Xử lý tiền tố "MEM" nếu có
                    if (orderId != null && orderId.startsWith("MEM")) {
                      orderId = orderId.substring(3); // Bỏ tiền tố "MEM"
                    }

                    developer.log("🔑 Mã đơn hàng đã xử lý: $orderId",
                        name: "VNPay");
                  }
                }

                // Đảm bảo trả về kết quả đúng định dạng
                final Map<String, dynamic> result = {
                  "success": success,
                  "orderId": orderId,
                  "amount": widget.amount
                };
                developer.log("🔑 Kết quả trả về: $result", name: "VNPay");

                // Trả về kết quả cho màn hình trước và đóng WebView an toàn
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.of(context).pop(result);
                  }
                });
              }
            },
            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              developer.log(
                  "🔒 Xử lý chứng chỉ SSL cho host: ${challenge.protectionSpace.host}",
                  name: "VNPay");
              // Tự động chấp nhận tất cả chứng chỉ SSL
              return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.PROCEED,
              );
            },
            onLoadError: (controller, url, code, message) {
              setState(() {
                isLoading = false;
              });
              developer.log("❌ Lỗi tải trang: $message (code: $code)",
                  name: "VNPay");

              // Kiểm tra xem URL có phải là URL trả về từ VNPay không
              final urlString = url.toString();
              if (urlString.contains("vnpay/return") &&
                  (urlString.contains("vnp_ResponseCode=00") ||
                      urlString.contains("vnp_TransactionStatus=00"))) {
                // Đây là URL trả về thành công từ VNPay, không hiển thị thông báo lỗi
                developer.log(
                    "ℹ️ Bỏ qua thông báo lỗi cho URL trả về VNPay thành công",
                    name: "VNPay");
                return;
              }

              // Hiển thị thông báo lỗi
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Không thể tải trang thanh toán: $message"),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: "Thử lại",
                    onPressed: () {
                      controller.reload();
                    },
                  ),
                ),
              );
            },
            onConsoleMessage: (controller, consoleMessage) {
              developer.log("🖥️ Console: ${consoleMessage.message}",
                  name: "VNPay");
            },
            onLoadResource: (controller, resource) {
              developer.log("📦 Tải tài nguyên: ${resource.url.toString()}",
                  name: "VNPay");
            },
            onUpdateVisitedHistory: (controller, url, androidIsReload) {
              setState(() {
                currentUrl = url.toString();
              });
              developer.log("🔄 Cập nhật lịch sử: ${url.toString()}",
                  name: "VNPay");
            },
          ),
          if (isLoading)
            Container(
              color:
                  isDarkMode ? AppColors.backgroundColor : AppColors.fontLight,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryColor),
                    SizedBox(height: 16),
                    Text(
                      "Đang kết nối đến cổng thanh toán...",
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? AppColors.fontLight
                            : AppColors.greyFont,
                      ),
                    ),
                    if (currentUrl != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "URL: ${currentUrl!.substring(0, currentUrl!.length > 50 ? 50 : currentUrl!.length)}...",
                          style: TextStyle(
                              fontSize: 12, color: AppColors.greyFont),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.open_in_browser),
        backgroundColor: AppColors.primaryColor,
        onPressed: () async {
          // Mở URL trong trình duyệt bên ngoài
          try {
            final url = Uri.parse(widget.paymentUrl);
            if (await url_launcher.canLaunchUrl(url)) {
              await url_launcher.launchUrl(url,
                  mode: url_launcher.LaunchMode.externalApplication);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Không thể mở trình duyệt")));
            }
          } catch (e) {
            developer.log("❌ Lỗi khi mở URL: $e", name: "VNPay");
          }
        },
        tooltip: 'Mở trong trình duyệt',
      ),
    );
  }
}

class PaymentScreen extends ConsumerWidget {
  final double amount;
  final String? existingOrderId;

  PaymentScreen({required this.amount, this.existingOrderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(paymentProvider);
    final isDarkMode = ThemeController.isDarkMode;

    // Nếu có existingOrderId, kiểm tra trạng thái thanh toán
    // Nếu không, tạo thanh toán mới
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (existingOrderId != null &&
          paymentState.orderId != existingOrderId &&
          !paymentState.isLoading) {
        print(
            "🔹 Kiểm tra trạng thái thanh toán cho đơn hàng: $existingOrderId");
        ref.read(paymentProvider.notifier).checkPaymentStatus(existingOrderId!);
      } else if (existingOrderId == null &&
          paymentState.paymentUrl.isEmpty &&
          !paymentState.isLoading) {
        print("🔹 Tạo yêu cầu thanh toán mới");
        ref.read(paymentProvider.notifier).generateVNPayUrl(amount);
      }
    });

    print("🔹 Payment URL: ${paymentState.paymentUrl}");
    print(
        "🔹 Payment Status: ${paymentState.transaction?.status ?? 'Chưa có'}");

    // Nếu đã thanh toán thành công, hiển thị thông báo
    if (paymentState.isPaid) {
      return _buildPaymentSuccessScreen(context, ref, paymentState);
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          height: 70 + MediaQuery.of(context).padding.top,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDarkColor,
                AppColors.primaryColor,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withOpacity(0.2),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context, false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Thanh toán VNPay",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const ChatIconBadge(size: 26),
                ],
              ),
            ),
          ),
        ),
      ),
      body: paymentState.isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryColor),
                  SizedBox(height: 16),
                  Text(
                    "Đang khởi tạo thanh toán...",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode
                          ? AppColors.fontLight
                          : AppColors.fontBlack,
                    ),
                  ),
                ],
              ),
            )
          : paymentState.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        "Lỗi thanh toán",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? AppColors.fontLight
                              : AppColors.fontBlack,
                        ),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          paymentState.errorMessage!,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode
                                ? AppColors.fontLight
                                : AppColors.fontBlack,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(paymentProvider.notifier)
                              .generateVNPayUrl(amount);
                        },
                        child: Text("Thử lại"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: AppColors.fontLight,
                        ),
                      ),
                    ],
                  ),
                )
              : paymentState.paymentUrl.isNotEmpty
                  ? FutureBuilder<dynamic>(
                      future: Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SimplePaymentWebView(
                            paymentUrl: paymentState.paymentUrl,
                            amount: amount,
                          ),
                        ),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.data != null) {
                            // Lấy kết quả từ màn hình thanh toán
                            final result =
                                snapshot.data as Map<String, dynamic>?;
                            print(
                                "💳 Nhận kết quả thanh toán từ WebView: $result");
                            final success = result?['success'] ?? false;
                            final orderId = result?['orderId'] as String?;
                            final paymentAmount =
                                result?['amount'] as double? ?? amount;

                            // Nếu thành công và có mã đơn hàng, coi như đã xác nhận
                            if (success && orderId != null) {
                              print(
                                  "🔹 Thanh toán VNPay báo thành công, coi như đã xác nhận");
                              print("🔹 Số tiền thanh toán: $paymentAmount đ");

                              // Hiển thị thông báo thành công
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text("Thanh toán thành công!"),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 3),
                              ));

                              // Đánh dấu thanh toán thành công và cập nhật giao dịch
                              _markPaymentAsSuccessful(
                                  ref, orderId, paymentAmount);

                              // Ngay sau khi đánh dấu thành công, kiểm tra lại trạng thái giao dịch
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ref
                                    .read(paymentProvider.notifier)
                                    .checkPaymentStatus(orderId);
                              });

                              // Hiển thị màn hình thành công
                              return _buildPaymentSuccessScreen(
                                  context, ref, paymentState);
                            }

                            // Nếu đã có trạng thái thanh toán, hiển thị kết quả
                            if (paymentState.isPaid) {
                              return _buildPaymentSuccessScreen(
                                  context, ref, paymentState);
                            }

                            // Hiển thị loading trong khi kiểm tra trạng thái
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                      color: AppColors.primaryColor),
                                  SizedBox(height: 16),
                                  Text(
                                    "Đang trở về...",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode
                                          ? AppColors.fontLight
                                          : AppColors.fontBlack,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        }

                        // Hiển thị SimplePaymentWebView mặc định nếu chưa có kết quả
                        return SimplePaymentWebView(
                            paymentUrl: paymentState.paymentUrl,
                            amount: amount);
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payment,
                              size: 64, color: AppColors.primaryColor),
                          SizedBox(height: 16),
                          Text(
                            "Thanh toán đơn hàng",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? AppColors.fontLight
                                  : AppColors.fontBlack,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Số tiền: ${_formatPrice(amount)} đ",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(paymentProvider.notifier)
                                  .generateVNPayUrl(amount);
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: Text(
                                "Tiếp tục thanh toán",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: AppColors.fontLight,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
      backgroundColor: AppColors.backgroundColor,
    );
  }

  Widget _buildPaymentSuccessScreen(
      BuildContext context, WidgetRef ref, PaymentState paymentState) {
    final isDarkMode = ThemeController.isDarkMode;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          height: 70 + MediaQuery.of(context).padding.top,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDarkColor,
                AppColors.primaryColor,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withOpacity(0.2),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context, true);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Thanh toán thành công",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const ChatIconBadge(size: 26),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 24),
            Text(
              "Thanh toán thành công!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.fontLight : AppColors.fontBlack,
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Mã đơn hàng: ${paymentState.orderId ?? paymentState.transaction?.orderId ?? 'N/A'}",
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? AppColors.fontLight : AppColors.fontBlack,
              ),
            ),
            if (paymentState.transaction != null) ...[
              SizedBox(height: 8),
              Text(
                "Số tiền: ${_formatPrice(paymentState.transaction!.price)} đ",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Text("Quay lại", style: TextStyle(fontSize: 16)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.fontLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.backgroundColor,
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  void _markPaymentAsSuccessful(
      WidgetRef ref, String orderId, double paymentAmount) {
    // Cập nhật state để lưu trạng thái giao dịch
    final transaction = PaymentTransaction(
      orderId: orderId,
      price: paymentAmount,
      status: 'Paid',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Cập nhật state
    ref.read(paymentProvider.notifier).setTransactionResult(transaction);

    // Cập nhật trạng thái đơn hàng trên repository
    final paymentRepo = PaymentRepository();
    paymentRepo.handleVNPayDirectResponse(orderId, paymentAmount);

    // Kiểm tra lại trạng thái thanh toán
    ref.read(paymentProvider.notifier).checkPaymentStatus(orderId);
  }
}
