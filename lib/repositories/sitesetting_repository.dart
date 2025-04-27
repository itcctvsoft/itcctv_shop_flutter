import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shoplite/constants/apilist.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoplite/models/site_setting.dart';

class ProfileRepository {
  final String apiUrl = api_sitesetting; // URL của API

  Future<void> fetchAndSaveSiteSetting() async {
    // Giả sử bạn gọi API để lấy dữ liệu site setting từ server
    final siteName = '';
    final logoUrl = '';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        // Lưu vào SharedPreferences
        final data = jsonDecode(response.body);
        // print(response.body);
        // Giả sử API trả về token trong response

        g_sitesetting = SiteSetting.fromJson(jsonDecode(data['setting']));
        // print(token);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('site_name', g_sitesetting.short_name);
        await prefs.setString('logo_url', g_sitesetting.logo);
      } else {
        print('Thất bại lấy thông tin: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<Map<String, String?>> loadSiteSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final siteName = prefs.getString('site_name');
    var logoUrl = prefs.getString('logo_url');
    if (app_type == "app") {
      logoUrl = logoUrl?.replaceAll('localhost', '10.0.2.2');
      logoUrl = logoUrl?.replaceAll('127.0.0.1', '10.0.2.2');
    }
    return {
      'site_name': siteName,
      'logo_url': logoUrl,
    };
  }
}
