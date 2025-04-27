import 'package:flutter/material.dart';
import 'dart:convert';

/// Extension để chuyển đổi chuỗi thành Color
extension ColorExtension on String {
  Color toColor() {
    var hexColor = replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
    // Trả về màu đen nếu không hợp lệ
    return Colors.black;
  }
}

/// Hàm xử lý URL ảnh để hoạt động trên các môi trường khác nhau
String getImageUrl(String url) {
  try {
    if (url.isEmpty) {
      // Trả về URL ảnh mặc định nếu URL rỗng
      return 'https://via.placeholder.com/150/cccccc/ffffff?text=No+Image';
    }

    // Chuẩn hóa URL: thay thế các ký tự không hợp lệ trong URL
    url = url.trim();

    // Hỗ trợ một số trường hợp cụ thể trong Laravel storage
    if (url.contains('storage/products/') && url.contains('/image_')) {
      // Đảm bảo không có khoảng trắng không mong muốn trong URL
      url = url.replaceAll(' ', '%20');
    }

    // Xử lý URL kép từ API (lỗi API trả về URL dạng http://http:// hoặc https://http://)
    if (url.contains('https://http://') || url.contains('http://http://')) {
      url = url.replaceAll('https://http://', 'http://');
      url = url.replaceAll('http://http://', 'http://');
    }

    // Xử lý đường dẫn tương đối đến /storage Laravel
    if (url.startsWith('/storage/') || url.startsWith('storage/')) {
      // Standardize to start with /storage/
      if (!url.startsWith('/')) {
        url = '/' + url;
      }

      // Kiểm tra xem URL đã là URL đầy đủ (đã có domain) từ API Laravel hay chưa
      bool isFullApiUrl = url.contains('caygiongtrungtam.com') ||
          url.contains('127.0.0.1') ||
          url.contains('localhost');

      if (!isFullApiUrl) {
        // Thêm domain vào trước URL nếu là đường dẫn tương đối
        url = 'http://10.0.2.2:8000' + url;

        // Fix double slashes if any
        url = url.replaceAll('//', '/').replaceAll('http:/', 'http://');
      }

      return url;
    }

    // Kiểm tra xem URL đã là URL đầy đủ (đã có domain) từ API Laravel hay chưa
    bool isFullApiUrl = url.contains('caygiongtrungtam.com') ||
        url.contains('127.0.0.1') ||
        url.contains('localhost');

    // Nếu URL bắt đầu bằng / (đường dẫn tương đối) và không phải URL đầy đủ
    if (url.startsWith('/') && !isFullApiUrl) {
      // Thêm domain vào trước URL
      url = 'https://caygiongtrungtam.com$url';
    }

    // Kiểm tra xem URL đã bắt đầu bằng http hay https chưa
    else if (!url.startsWith('http')) {
      // Nếu chưa có http, thêm vào
      url = 'http://$url';
    }

    // Xử lý URL từ Amazon S3 để tránh lỗi 403
    if (url.contains('amazonaws.com') || url.contains('amazon.com')) {
      // Kiểm tra và chuyển sang https nếu cần
      if (url.startsWith('http://')) {
        url = url.replaceFirst('http://', 'https://');
      }
      return url;
    }

    try {
      // Parse URL để phân tích thành các thành phần
      Uri uri = Uri.parse(url);
      String host = uri.host;

      // Thay thế localhost hoặc 127.0.0.1 bằng 10.0.2.2 (đặc biệt cho giả lập Android)
      if (host == 'localhost' || host == '127.0.0.1') {
        String newUrl = url.replaceFirst(host, '10.0.2.2');

        // Nếu path có ký tự đặc biệt, xử lý riêng
        if (uri.path.contains(' ') ||
            uri.path.contains('(') ||
            uri.path.contains(')') ||
            uri.path.contains('[') ||
            uri.path.contains(']')) {
          // Không trả về ngay, tiếp tục xử lý URL này
          url = newUrl;
        } else {
          return newUrl;
        }
      }
    } catch (e) {
      print("Error parsing URL: $e, URL: $url");
      // Continue with original URL if parsing fails
    }

    return url;
  } catch (e) {
    // Log lỗi và trả về URL gốc trong trường hợp có lỗi
    print("Error processing URL: $e, URL: $url");
    return url;
  }
}

/// Định dạng giá tiền với dấu phân cách hàng nghìn
String formatCurrency(double amount) {
  // Chuyển số thành chuỗi, loại bỏ phần thập phân nếu là số nguyên
  String priceString =
      amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);

  // Thêm dấu chấm phân cách hàng nghìn
  final result = StringBuffer();
  for (int i = 0; i < priceString.length; i++) {
    if (i > 0 &&
        (priceString.length - i) % 3 == 0 &&
        priceString[i - 1] != '.') {
      result.write('.');
    }
    result.write(priceString[i]);
  }

  return result.toString();
}

/// Helper function to fix improperly escaped Unicode characters
String _fixUnicodeEscapes(String input) {
  // First, replace known problematic sequences by specific replacements
  String sanitized = input
      // Specifically fix the problematic \u00fm sequence that appears in the JSON
      .replaceAll(r'\u00fm', 'ư') // Vietnamese character likely intended
      // Common Vietnamese Unicode escapes
      .replaceAll(r'\u1ed5', 'ổ')
      .replaceAll(r'\u1eaft', 'ắ')
      .replaceAll(r'\u00f4', 'ô')
      .replaceAll(r'\u00e2', 'â')
      .replaceAll(r'\u00e0', 'à')
      .replaceAll(r'\u00e1', 'á')
      .replaceAll(r'\u00f9', 'ù')
      .replaceAll(r'\u00fa', 'ú')
      .replaceAll(r'\u1ecb', 'ị')
      .replaceAll(r'\u1ec7', 'ệ')
      .replaceAll(r'\u00e8', 'è')
      .replaceAll(r'\u00e9', 'é')
      .replaceAll(r'\u1ea1', 'ạ')
      .replaceAll(r'\u0111', 'đ')
      .replaceAll(r'\u00f2', 'ò')
      .replaceAll(r'\u00f3', 'ó');

  // Then process any remaining valid Unicode escapes
  final regex = RegExp(r'\\u([0-9a-fA-F]{4})');

  return sanitized.replaceAllMapped(regex, (match) {
    try {
      // Convert hex to int and then to character
      final hexCode = match.group(1)!;
      final charCode = int.parse(hexCode, radix: 16);
      return String.fromCharCode(charCode);
    } catch (e) {
      // If conversion fails, return a safe replacement
      print('Failed to convert Unicode escape: ${match.group(0)}');
      return ' '; // Replace with space instead of keeping the broken sequence
    }
  });
}

/// Sanitizes and parses potentially malformed JSON
dynamic parseAndSanitizeJson(String jsonString) {
  try {
    // First attempt - try parsing directly
    return json.decode(jsonString);
  } catch (e) {
    print("First attempt at JSON parsing failed: $e");
    print("Begin sanitizing JSON of length ${jsonString.length}");

    // Step 1: Remove control characters
    String sanitized = jsonString.replaceAll(RegExp(r'[\u0000-\u001F]'), '');
    print(
        "Step 1: Removed control characters, new length: ${sanitized.length}");

    // Step 2: Fix URLs with escaped slashes
    sanitized = sanitized
        .replaceAll(r'http:\/\/', 'http://')
        .replaceAll(r'https:\/\/', 'https://');
    print("Step 2: Fixed escaped URLs");

    // Step 3: Fix improperly escaped Unicode
    sanitized = _fixUnicodeEscapes(sanitized);
    print("Step 3: Fixed Unicode escapes");

    // Step 4: Remove HTML content that might be causing issues
    sanitized = _removeProblematicHtml(sanitized);
    print("Step 4: Removed problematic HTML content");

    try {
      return json.decode(sanitized);
    } catch (e) {
      print("JSON parsing after sanitization failed: $e");

      // Step 5: More aggressive sanitization
      sanitized = sanitized
          // Replace all remaining Unicode escapes with spaces
          .replaceAll(RegExp(r'\\u[0-9a-fA-F]{2}[^0-9a-fA-F][^0-9a-fA-F]'), ' ')
          // Remove HTML entities
          .replaceAll(RegExp(r'&[a-zA-Z]+;'), ' ')
          // Replace all non-ASCII with spaces
          .replaceAll(RegExp(r'[^\x20-\x7E]'), ' ');

      try {
        return json.decode(sanitized);
      } catch (e) {
        print("Final attempt at parsing failed: $e");

        // Last resort: Strip out all description fields that are causing issues
        sanitized = _stripProblematicFields(sanitized);

        try {
          return json.decode(sanitized);
        } catch (e) {
          throw FormatException(
              "Unable to parse JSON after sanitization: ${e.toString()}");
        }
      }
    }
  }
}

/// Remove HTML content that might be causing issues
String _removeProblematicHtml(String input) {
  // Look for HTML style attributes that might contain problematic content
  String sanitized = input
      // Replace HTML style attributes with empty strings
      .replaceAll(RegExp(r'style="[^"]*"'), 'style=""')
      // Replace &nbsp; with space
      .replaceAll('&nbsp;', ' ');

  return sanitized;
}

/// Strip out problematic fields entirely as a last resort
String _stripProblematicFields(String input) {
  // Use regex to find and replace description fields with empty strings
  final regex = RegExp(r'"description"\s*:\s*"[^"]*"');
  return input.replaceAll(regex, '"description":""');
}

/// Encodes data to JSON with proper handling of Unicode characters
String encodeToJsonWithUnicode(dynamic data) {
  return json.encode(data, toEncodable: (object) {
    if (object is String) {
      return object
          .replaceAll('\u2028', ' ') // line separator
          .replaceAll('\u2029', ' ') // paragraph separator
          .replaceAll('\r', ' ') // carriage return
          .replaceAll('\n', ' '); // new line
    }
    return object;
  });
}
