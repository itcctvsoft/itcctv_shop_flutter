import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/models/blog.dart';
import 'package:flutter/foundation.dart';

class BlogRepository {
  // Get all blogs with pagination
  Future<BlogPagination> getAllBlogs({int page = 1}) async {
    try {
      final url = '${api_ge_blog_list}?page=$page';

      if (kDebugMode) {
        print('📡 Making request to: $url');
        print(
            '🔑 Using token: ${g_token.isNotEmpty ? 'Yes (length: ${g_token.length})' : 'No'}');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (g_token.isNotEmpty) 'Authorization': 'Bearer $g_token',
        },
      );

      if (kDebugMode) {
        print('📥 Response status: ${response.statusCode}');
        print(
            '📥 Response body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == true) {
          return BlogPagination.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Failed to load blogs');
        }
      } else {
        // Parse error response if possible
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          if (errorData['message']?.contains('BlogResource not found') ==
              true) {
            throw Exception(
                'Tính năng blog chưa được cài đặt trên máy chủ. Vui lòng liên hệ quản trị viên.');
          }
          throw Exception(
              'Lỗi máy chủ: ${errorData['message'] ?? 'Không rõ nguyên nhân'}');
        } catch (e) {
          throw Exception(
              'Server returned status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error in getAllBlogs: $e');
      }
      throw Exception('Failed to connect to server: $e');
    }
  }

  // Get blog detail by slug
  Future<Map<String, dynamic>> getBlogDetail(String slug) async {
    try {
      final url = '${api_ge_blog_list}/$slug';

      if (kDebugMode) {
        print('📡 Making request to: $url');
        print(
            '🔑 Using token: ${g_token.isNotEmpty ? 'Yes (length: ${g_token.length})' : 'No'}');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (g_token.isNotEmpty) 'Authorization': 'Bearer $g_token',
        },
      );

      if (kDebugMode) {
        print('📥 Response status: ${response.statusCode}');
        print(
            '📥 Response body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == true) {
          // Parse blog, related blogs, and tags
          final Blog blog = Blog.fromJson(data['data']);
          final List<Blog> relatedBlogs = (data['related_blogs'] as List)
              .map((blogJson) => Blog.fromJson(blogJson))
              .toList();
          final List<BlogTag> tags = (data['tags'] as List)
              .map((tagJson) => BlogTag.fromJson(tagJson))
              .toList();

          return {
            'blog': blog,
            'relatedBlogs': relatedBlogs,
            'tags': tags,
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to load blog details');
        }
      } else {
        // Parse error response if possible
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          if (errorData['message']?.contains('BlogResource not found') ==
              true) {
            throw Exception(
                'Tính năng blog chưa được cài đặt trên máy chủ. Vui lòng liên hệ quản trị viên.');
          }
          throw Exception(
              'Lỗi máy chủ: ${errorData['message'] ?? 'Không rõ nguyên nhân'}');
        } catch (e) {
          throw Exception(
              'Server returned status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error in getBlogDetail: $e');
      }
      throw Exception('Failed to connect to server: $e');
    }
  }
}
