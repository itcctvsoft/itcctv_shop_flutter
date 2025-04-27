import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shoplite/constants/apilist.dart'; // Đường dẫn API
import 'package:shoplite/models/Address.dart'; // Model Address

class AddressRepository {
  final String apiGetAddressBook = api_get_addressbook;
  final String apiAddAddressBook = api_po_addressbook;
  final String apiDeleteAddressBook = api_delete_addressbook;

  // Hàm gửi yêu cầu HTTP chung
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
      switch (method) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(url, headers: headers, body: json.encode(body));
          break;
        case 'PUT':
          response = await http.put(url, headers: headers, body: json.encode(body));
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers, body: json.encode(body));
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // Log request để debug
      print('🔹 Request: $method $url');
      print('🔹 Headers: $headers');
      if (body != null) print('🔹 Body: ${json.encode(body)}');

      // Kiểm tra response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        print('✅ Response Data: $data');

        if (data['status'] == false) {
          throw Exception(data['message'] ?? 'An error occurred');
        }
        return data;
      } else {
        throw Exception(
          'HTTP error: ${response.statusCode} - ${response.reasonPhrase}\nResponse Body: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Lỗi khi gửi request: $e');
      throw Exception('Lỗi khi gửi request: $e');
    }
  }

  // Lấy danh sách AddressBook
  Future<List<Address>> getAddressBook(String token) async {
    final url = Uri.parse(apiGetAddressBook);

    try {
      print('📩 Gửi yêu cầu GET danh sách AddressBook đến URL: $url');
      final data = await _sendRequest(url, method: 'GET', token: token);

      if (data['addresses'] == null || (data['addresses'] as List).isEmpty) {
        print('⚠️ AddressBook trống.');
        return [];
      }

      List<Address> addressList = (data['addresses'] as List)
          .map((item) => Address.fromJson(item))
          .toList();

      print('📌 Số lượng địa chỉ trong AddressBook: ${addressList.length}');
      return addressList;
    } catch (e) {
      print('❌ Lỗi khi lấy danh sách AddressBook: $e');
      rethrow;
    }
  }

  // Thêm địa chỉ vào AddressBook
  Future<void> addAddress(String token, Address address) async {
    final url = Uri.parse(apiAddAddressBook);

    try {
      await _sendRequest(
        url,
        method: 'POST',
        token: token,
        body: address.toJson(),
      );

      print('✅ Địa chỉ đã được thêm vào AddressBook: ${address.fullName}');
    } catch (e) {
      print('❌ Lỗi khi thêm địa chỉ vào AddressBook: $e');
      rethrow;
    }
  }

  // Xóa địa chỉ khỏi AddressBook
  Future<void> deleteAddress(String token, int addressId) async {
    final url = Uri.parse("$apiDeleteAddressBook/$addressId"); // ⚠️ Cần có ID trong URL

    try {
      print('📮 Gửi yêu cầu DELETE địa chỉ: Address ID $addressId');
      await _sendRequest(
        url,
        method: 'DELETE',
        token: token,
      );

      print('✅ Địa chỉ đã được xóa khỏi AddressBook: $addressId');
    } catch (e) {
      print('❌ Lỗi khi xóa địa chỉ khỏi AddressBook: $e');
      rethrow;
    }
  }
}
