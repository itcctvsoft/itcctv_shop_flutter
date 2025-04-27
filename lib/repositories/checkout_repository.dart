import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/checkout.dart';
import '../constants/apilist.dart';
import '../constants/pref_data.dart';

class CheckoutRepository {
  final String apiUrl = api_get_checkout;

  Future<dynamic> _sendRequest(
      Uri url, {
        required String method,
        required String token,
        Map<String, dynamic>? body,
      }) async {
    if (token.isEmpty) {
      throw Exception('Authentication token is missing. Please login.');
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      http.Response response;
      if (method == 'GET') {
        response = await http.get(url, headers: headers);
      } else if (method == 'POST') {
        response = await http.post(url, headers: headers, body: json.encode(body));
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      print('Request URL: $url');
      print('Request Method: $method');
      print('Request Headers: $headers');
      if (body != null) print('Request Body: ${json.encode(body)}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        print('Response Data: $data');
        if (data['status'] == false) {
          throw Exception(data['message'] ?? 'An error occurred');
        }
        return data;
      } else {
        throw Exception(
            'HTTP error: ${response.statusCode} - ${response.reasonPhrase}\nResponse Body: ${response.body}');
      }
    } catch (e) {
      print('Failed to send request: $e');
      throw Exception('Failed to send request: $e');
    }
  }

  Future<CheckoutResponse> fetchCheckoutData(String token) async {
    final url = Uri.parse(apiUrl);
    try {
      final data = await _sendRequest(url, method: 'GET', token: token);
      return CheckoutResponse.fromJson(data);
    } catch (e) {
      print('Lỗi khi lấy dữ liệu checkout: $e');
      rethrow;
    }
  }
}