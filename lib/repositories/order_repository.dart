import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/models/order.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class OrderRepository {
  // Thời gian cache hợp lệ (1 giờ)
  static const int _cacheDurationMinutes = 60;

  // Key lưu cache
  static const String _ordersCacheKey = 'orders_cache';
  static const String _ordersCacheTimestampKey = 'orders_cache_timestamp';

  // Timeout cho request
  static const Duration _requestTimeout = Duration(seconds: 15);

  // Hàm xử lý chuỗi JSON có escape không hợp lệ - tái sử dụng từ ProductRepository
  String _fixInvalidJsonEscapes(String jsonString) {
    print('Fixing invalid JSON escapes in response');

    // Mẫu regex để tìm các chuỗi escape không hợp lệ như \00e0 thay vì \u00e0
    RegExp invalidEscape = RegExp(r'\\([0-9][0-9][a-fA-F0-9][a-fA-F0-9])');

    // Đếm số lượng thay thế để debug
    int replaceCount = 0;

    // Thay thế các chuỗi không hợp lệ bằng chuỗi hợp lệ thêm 'u'
    String fixedJson = jsonString.replaceAllMapped(invalidEscape, (Match m) {
      replaceCount++;
      return '\\u${m[1]}';
    });

    print('Fixed $replaceCount invalid Unicode escape sequences');

    // Xử lý các escape không hợp lệ như \' và \"
    int quoteReplaceCount = 0;

    // Đếm số lần thay thế dấu nháy đơn
    int singleQuoteCount = fixedJson.split("\\'").length - 1;
    fixedJson = fixedJson.replaceAll("\\'", "'");

    // Đếm số lần thay thế dấu nháy kép
    int doubleQuoteCount = fixedJson.split('\\"').length - 1;
    fixedJson = fixedJson.replaceAll('\\"', '"');

    quoteReplaceCount = singleQuoteCount + doubleQuoteCount;
    print('Fixed $quoteReplaceCount invalid quote escapes');

    // Kiểm tra các escape sequences khác có thể gây lỗi
    RegExp otherEscapes = RegExp(r'\\([^\"\\\/bfnrtu])');
    int otherReplaceCount = 0;

    fixedJson = fixedJson.replaceAllMapped(otherEscapes, (Match m) {
      otherReplaceCount++;
      // Chỉ giữ lại ký tự sau dấu \
      return '${m[1]}';
    });

    if (otherReplaceCount > 0) {
      print('Fixed $otherReplaceCount other invalid escape sequences');
    }

    return fixedJson;
  }

  // Lấy cache từ local storage
  Future<List<Order>?> _getOrdersFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimestampStr = prefs.getString(_ordersCacheTimestampKey);

      // Nếu không có timestamp, tức là không có cache
      if (cacheTimestampStr == null) return null;

      // Kiểm tra cache còn hợp lệ không
      final cacheTimestamp = DateTime.parse(cacheTimestampStr);
      final now = DateTime.now();
      final difference = now.difference(cacheTimestamp).inMinutes;

      // Nếu cache quá cũ, trả về null để lấy dữ liệu mới
      if (difference > _cacheDurationMinutes) {
        print('Cache expired ($difference minutes old)');
        return null;
      }

      // Lấy dữ liệu cache
      final jsonString = prefs.getString(_ordersCacheKey);
      if (jsonString == null || jsonString.isEmpty) return null;

      // Parse dữ liệu JSON
      final List<dynamic> ordersJson = json.decode(jsonString);
      final orders = ordersJson.map((item) => Order.fromJson(item)).toList();

      print('Successfully loaded ${orders.length} orders from cache');
      return orders;
    } catch (e) {
      print('Error loading orders from cache: $e');
      return null;
    }
  }

  // Lưu cache vào local storage
  Future<void> _saveOrdersToCache(List<Order> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toIso8601String();

      // Lưu timestamp
      await prefs.setString(_ordersCacheTimestampKey, now);

      // Chuyển đổi orders sang JSON
      final List<Map<String, dynamic>> ordersJson =
          orders.map((order) => order.toJson()).toList();
      final jsonString = json.encode(ordersJson);

      // Lưu dữ liệu
      await prefs.setString(_ordersCacheKey, jsonString);
      print('Saved ${orders.length} orders to cache');
    } catch (e) {
      print('Error saving orders to cache: $e');
    }
  }

  // Lấy danh sách đơn hàng
  Future<List<Order>> getOrders({bool forceRefresh = false}) async {
    // Nếu không bắt buộc làm mới, thử lấy từ cache trước
    if (!forceRefresh) {
      final cachedOrders = await _getOrdersFromCache();
      if (cachedOrders != null && cachedOrders.isNotEmpty) {
        print('Returning ${cachedOrders.length} orders from cache');
        return cachedOrders;
      }
    }

    try {
      final uri = Uri.parse(api_orders);
      final responseCompleter = Completer<http.Response>();

      // Thiết lập timeout
      Timer(_requestTimeout, () {
        if (!responseCompleter.isCompleted) {
          print('Request timed out after ${_requestTimeout.inSeconds} seconds');
          responseCompleter
              .completeError(TimeoutException('Request timed out'));
        }
      });

      // Thực hiện request
      http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (g_token.isNotEmpty) 'Authorization': 'Bearer $g_token',
          // Thêm header Cache-Control để buộc server không trả về dữ liệu cache
          if (forceRefresh) 'Cache-Control': 'no-cache, no-store',
          if (forceRefresh) 'Pragma': 'no-cache',
        },
      ).then((response) {
        if (!responseCompleter.isCompleted) {
          responseCompleter.complete(response);
        }
      }).catchError((e) {
        if (!responseCompleter.isCompleted) {
          responseCompleter.completeError(e);
        }
      });

      // Đợi response hoặc timeout
      final response = await responseCompleter.future;

      print('Request URL: $uri');
      print('Force refresh: $forceRefresh');
      print('Response Status: ${response.statusCode}');
      print('Response Body Length: ${response.body.length}');

      // Kiểm tra response body có đầy đủ không
      if (response.body.isEmpty) {
        throw Exception('Empty response received');
      }

      if (response.statusCode == 200) {
        try {
          // Sửa lỗi escape trong JSON trước khi phân tích
          String fixedJsonString = _fixInvalidJsonEscapes(response.body);

          final Map<String, dynamic> data = json.decode(fixedJsonString);

          if (data['status'] == true &&
              data['data'] != null &&
              data['data']['orders'] != null) {
            final List<dynamic> ordersData = data['data']['orders'];
            final List<Order> orders = [];

            for (var item in ordersData) {
              try {
                orders.add(Order.fromJson(item));
              } catch (e) {
                print('Error parsing order: $e');
              }
            }

            print('Successfully loaded ${orders.length} orders from API');

            // Lưu dữ liệu vào cache
            if (orders.isNotEmpty) {
              _saveOrdersToCache(orders);
            }

            return orders;
          }
          throw Exception(data['message'] ?? 'Failed to load orders');
        } catch (e) {
          print('JSON parsing error in getOrders: $e');
          print(
              'First 1000 chars of response: ${response.body.substring(0, response.body.length > 1000 ? 1000 : response.body.length)}');
          print(
              'Last 1000 chars of response: ${response.body.substring(response.body.length - (response.body.length > 1000 ? 1000 : response.body.length))}');

          // Nếu lỗi parse JSON, thử lấy từ cache để không hiển thị màn hình trống
          final cachedOrders = await _getOrdersFromCache();
          if (cachedOrders != null && cachedOrders.isNotEmpty) {
            print('Using cached data after JSON parse error');
            return cachedOrders;
          }

          throw Exception('Failed to parse order data: $e');
        }
      }

      // Nếu API trả về lỗi, thử dùng dữ liệu cache
      final cachedOrders = await _getOrdersFromCache();
      if (cachedOrders != null && cachedOrders.isNotEmpty) {
        print(
            'Using cached data after API error (status ${response.statusCode})');
        return cachedOrders;
      }

      // Hiển thị nội dung lỗi từ response
      try {
        print('API Error Response: ${response.body}');
        final errorData = json.decode(response.body);
        throw Exception(
            'Server error: ${errorData['message'] ?? errorData.toString()}');
      } catch (jsonError) {
        // Nếu không parse được JSON, hiện response body
        throw Exception(
            'Failed to load orders: Status ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getOrders: $e');

      // Nếu có lỗi kết nối, thử dùng dữ liệu cache
      final cachedOrders = await _getOrdersFromCache();
      if (cachedOrders != null && cachedOrders.isNotEmpty) {
        print('Using cached data after connection error');
        return cachedOrders;
      }

      throw Exception('Failed to load orders: $e');
    }
  }

  // Cập nhật trạng thái thanh toán cho các đơn hàng cụ thể
  Future<bool> updatePaymentStatus(List<int> orderIds) async {
    try {
      final uri = Uri.parse('$base/orders/update-payment-status');

      final responseCompleter = Completer<http.Response>();

      // Thiết lập timeout
      Timer(_requestTimeout, () {
        if (!responseCompleter.isCompleted) {
          print('Request timed out after ${_requestTimeout.inSeconds} seconds');
          responseCompleter
              .completeError(TimeoutException('Request timed out'));
        }
      });

      print('Updating payment status for orders: $orderIds');

      // Thực hiện request
      http
          .post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (g_token.isNotEmpty) 'Authorization': 'Bearer $g_token',
        },
        body: json.encode({
          'order_ids': orderIds,
        }),
      )
          .then((response) {
        if (!responseCompleter.isCompleted) {
          responseCompleter.complete(response);
        }
      }).catchError((e) {
        if (!responseCompleter.isCompleted) {
          responseCompleter.completeError(e);
        }
      });

      // Đợi response hoặc timeout
      final response = await responseCompleter.future;

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == true) {
          // Xóa cache để buộc làm mới dữ liệu
          await _clearOrderCache();
          return true;
        }
        return false;
      }
      return false;
    } catch (e) {
      print('Error updating payment status: $e');
      return false;
    }
  }

  // Đồng bộ tất cả trạng thái thanh toán
  Future<bool> syncPaymentStatus() async {
    try {
      final uri = Uri.parse('$base/orders/sync-payment-status');

      final responseCompleter = Completer<http.Response>();

      // Thiết lập timeout
      Timer(_requestTimeout, () {
        if (!responseCompleter.isCompleted) {
          print('Request timed out after ${_requestTimeout.inSeconds} seconds');
          responseCompleter
              .completeError(TimeoutException('Request timed out'));
        }
      });

      // Thực hiện request
      http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (g_token.isNotEmpty) 'Authorization': 'Bearer $g_token',
        },
      ).then((response) {
        if (!responseCompleter.isCompleted) {
          responseCompleter.complete(response);
        }
      }).catchError((e) {
        if (!responseCompleter.isCompleted) {
          responseCompleter.completeError(e);
        }
      });

      // Đợi response hoặc timeout
      final response = await responseCompleter.future;

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == true) {
          // Xóa cache để buộc làm mới dữ liệu
          await _clearOrderCache();
          return true;
        }
        return false;
      }
      return false;
    } catch (e) {
      print('Error syncing payment status: $e');
      return false;
    }
  }

  // Xóa cache orders để buộc làm mới dữ liệu
  Future<void> _clearOrderCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ordersCacheKey);
      await prefs.remove(_ordersCacheTimestampKey);
      print('Order cache cleared successfully');
    } catch (e) {
      print('Error clearing order cache: $e');
    }
  }
}
