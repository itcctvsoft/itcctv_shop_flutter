import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/models/product.dart';

class ProductRepository {
  // Hàm đơn giản hóa cho việc sửa JSON
  String _sanitizeJson(String jsonString) {
    // Thời gian bắt đầu
    DateTime start = DateTime.now();
    print('Begin sanitizing JSON of length ${jsonString.length}');

    // Bước 0: Xử lý đặc biệt cho trường hợp Z122 Ultra Series trước tiên
    String sanitized = jsonString;

    // Xử lý trực tiếp cho trường hợp đặc biệt Z122 Ultra Series
    if (jsonString.contains('Z122 Ultra Series') ||
        jsonString.contains('inch82 inch')) {
      print(
          'Found special case: Z122 Ultra Series pattern - applying direct fixes');
      sanitized = sanitized
          .replaceAll(
          'Z122 Ultra Series 281 inch82 inch', 'Z122 Ultra Series 28.1 inch')
          .replaceAll(
          'Z122 Ultra Series 281"82"', 'Z122 Ultra Series 28.1 inch')
          .replaceAll('"Z122 Ultra Series 281', '"Z122 Ultra Series 28.1')
          .replaceAll('inch82 inch', ' inch')
          .replaceAll('inch81 inch', ' inch')
          .replaceAll('inch80 inch', ' inch')
          .replaceAll(RegExp(r'inch\d+ inch'), ' inch');

      // In ra vị trí 559 và vùng xung quanh để kiểm tra
      if (sanitized.length > 580) {
        int checkPos = 559;
        int start = max(0, checkPos - 30);
        int end = min(sanitized.length, checkPos + 30);
        print(
            'Content around position 559: ${sanitized.substring(start, end)}');

        // Kiểm tra xem vẫn còn vấn đề tại vị trí 559 không
        if (checkPos < sanitized.length) {
          print(
              'Character at position 559: "${sanitized[checkPos]}" (code: ${sanitized.codeUnitAt(checkPos)})');

          // Nếu ký tự tại vị trí 559 vẫn có vấn đề, thay thế trực tiếp vùng đó
          if (sanitized[checkPos] == '"' || sanitized[checkPos] == '[') {
            int problemStart = max(0, checkPos - 20);
            int problemEnd = min(sanitized.length, checkPos + 20);
            String problemSection =
            sanitized.substring(problemStart, problemEnd);
            print('Problem section: $problemSection');

            // Tìm chuỗi chứa vấn đề và thay thế trực tiếp
            String replacement = problemSection
                .replaceAll(' inch"[', ' inch","')
                .replaceAll(' inch["', ' inch","')
                .replaceAll('inch82"[', 'inch","')
                .replaceAll('inch82["', 'inch","');

            sanitized = sanitized.substring(0, problemStart) +
                replacement +
                sanitized.substring(problemEnd);
          }
        }
      }
    }

    // Bước 1: Loại bỏ các ký tự điều khiển
    sanitized = sanitized.replaceAll(RegExp(r'[\u0000-\u001F]'), '');
    sanitized = sanitized.replaceAll(RegExp(r'[\uD800-\uDFFF]'), '');
    print(
        'Step 1: Removed control characters, new length: ${sanitized.length}');

    // Bước 2: Sửa các chuỗi JSON bị hỏng
    // Đảm bảo các dấu ngoặc kép trong key được escape đúng cách
    sanitized =
        sanitized.replaceAll(RegExp(r'([{,])\s*([^"{\s][^:]*):'), r'$1"$2":');
    print('Step 2: Fixed unquoted keys');

    // Bước 3: Thay thế các ký tự có thể gây lỗi trong mô tả sản phẩm
    sanitized = sanitized
        .replaceAll('"game changer"', 'game changer')
        .replaceAll('"gaming laptop"', 'gaming laptop')
        .replaceAll('"Premium"', 'Premium')
        .replaceAll('"Professional"', 'Professional')
        .replaceAll('"Full HD"', 'Full HD')
        .replaceAll('"Ultra HD"', 'Ultra HD')
        .replaceAll('"Business"', 'Business')
        .replaceAll('"high-quality"', 'high-quality')
        .replaceAll('\\u2013', '-') // em dash
        .replaceAll('\\u2014', '-') // em dash
        .replaceAll('\\u201c', '') // left smart quote
        .replaceAll('\\u201d', ''); // right smart quote

    // Handle size specifications with inch marks
    RegExp sizeWithInchRegex = RegExp(r'(\d+)"');
    sanitized = sanitized.replaceAllMapped(sizeWithInchRegex, (match) {
      return '${match.group(1)} inch';
    });

    // Sửa lỗi đặc biệt với chuỗi inch lặp lại (ví dụ: inch82 inch) - đây là bước dự phòng vì đã xử lý ở trên
    sanitized = sanitized
        .replaceAll('inch82 inch', 'inch')
        .replaceAll('inch81 inch', 'inch')
        .replaceAll('inch80 inch', 'inch')
        .replaceAll(RegExp(r'inch\d+ inch'), 'inch')
        .replaceAll(RegExp(r' inch inch'), ' inch');

    // Xử lý trường hợp đặc biệt của Z122 Ultra Series - đây là bước dự phòng vì đã xử lý ở trên
    sanitized = sanitized.replaceAll(
        'Z122 Ultra Series 281 inch', 'Z122 Ultra Series 28.1 inch');

    // Xử lý lỗi cụ thể tại vị trí 559 (nếu còn)
    if (sanitized.length > 560) {
      int problemPos = 559;
      if (problemPos < sanitized.length) {
        String char = sanitized[problemPos];
        if ((char == '"' || char == '[') && problemPos > 0) {
          // Giả sử đây là ranh giới giữa chuỗi và mảng ảnh, sửa định dạng cho đúng
          sanitized = sanitized.substring(0, problemPos) +
              '","' +
              sanitized.substring(problemPos + 1);
        }
      }
    }

    // Bước 4: Sửa các lỗi cú pháp phổ biến
    sanitized = sanitized
        .replaceAll(',]', ']')
        .replaceAll(',}', '}')
        .replaceAll('}{', '},{');
    print('Step 4: Fixed common syntax errors');

    // Bước 5: Xác nhận tính hợp lệ của định dạng JSON
    bool isValid = false;
    try {
      json.decode(sanitized);
      isValid = true;
      print('Step 5: JSON is valid after sanitization');
    } catch (e) {
      print('Step 5: JSON is still invalid: $e');

      // Bước 6: Sửa lỗi tại vị trí cụ thể
      if (e.toString().contains('at offset')) {
        // Trích xuất vị trí lỗi từ thông báo lỗi
        int errorPos = -1;
        try {
          final match = RegExp(r'at offset (\d+)').firstMatch(e.toString());
          if (match != null && match.group(1) != null) {
            errorPos = int.parse(match.group(1)!);
          }
        } catch (_) {}

        if (errorPos >= 0 && errorPos < sanitized.length) {
          print('Error at position $errorPos');

          // In ra một phần của chuỗi xung quanh vị trí lỗi
          int start = errorPos - 20 > 0 ? errorPos - 20 : 0;
          int end = errorPos + 20 < sanitized.length
              ? errorPos + 20
              : sanitized.length - 1;
          print('Context: "${sanitized.substring(start, end)}"');

          String charAtError = sanitized[errorPos];
          print(
              'Character at error position: "$charAtError" (code ${charAtError.codeUnitAt(0)})');

          // Fix specific character errors
          if (charAtError == '"' && errorPos > 0) {
            print('Fixing quotes in description');
            // Replace quote at error position
            sanitized = sanitized.substring(0, errorPos) +
                '\'' +
                sanitized.substring(errorPos + 1);
          } else if (charAtError == '(' && errorPos == 0) {
            print('Removing opening parenthesis and adding braces');
            sanitized = '{' + sanitized.substring(1);

            // If there's a closing parenthesis at the end, replace with brace
            if (sanitized.endsWith(')')) {
              sanitized = sanitized.substring(0, sanitized.length - 1) + '}';
            }
          } else if (charAtError == r'$'[0] &&
              errorPos < sanitized.length - 1) {
            // This likely means a regex replacement went wrong
            print('Fixing bad regex replacement pattern');

            // Try to find the end of the problematic pattern
            int patternEnd = sanitized.indexOf("'", errorPos);
            if (patternEnd > errorPos) {
              // Remove the whole problematic section
              sanitized = sanitized.substring(0, errorPos) +
                  sanitized.substring(patternEnd + 1);
            } else {
              // Just remove the $ character
              sanitized = sanitized.substring(0, errorPos) +
                  sanitized.substring(errorPos + 1);
            }
          }
        }
      }
    }

    // In thời gian hoàn thành
    Duration timeTaken = DateTime.now().difference(start);
    print('Completed JSON sanitization in ${timeTaken.inMilliseconds}ms');

    return sanitized;
  }

  // Hàm thử nhiều cách khác nhau để phân tích JSON
  Future<Map<String, dynamic>> _tryParseJson(String jsonString) async {
    try {
      // Cách 1: Thử trực tiếp
      return json.decode(jsonString);
    } catch (e) {
      print('First attempt at JSON parsing failed: $e');

      try {
        // Cách 2: Thử sau khi vệ sinh
        String sanitized = _sanitizeJson(jsonString);
        return json.decode(sanitized);
      } catch (e) {
        print('Second attempt at JSON parsing failed: $e');

        try {
          // Cách 3: Tìm một cấu trúc JSON hợp lệ trong chuỗi
          final match =
          RegExp(r'(\{.*\})', dotAll: true).firstMatch(jsonString);
          if (match != null && match.group(1) != null) {
            return json.decode(match.group(1)!);
          }
        } catch (e) {
          print('Third attempt at JSON parsing failed: $e');
        }

        // Nếu tất cả đều thất bại, thử tạo một JSON rỗng
        throw Exception(
            'Could not parse JSON response after multiple attempts');
      }
    }
  }

  Future<PaginationResponse<Product>> getProducts(int page, int perPage) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final uri =
        Uri.parse('$api_get_product_list?page=$page&per_page=$perPage');
        final response = await http.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (g_token.isNotEmpty) 'Authorization': 'Bearer $g_token',
          },
        );

        print('Request URL: $uri');
        print('Response Status: ${response.statusCode}');
        print('Response Length: ${response.body.length}');

        if (response.body.isEmpty) {
          throw Exception('Empty response received');
        }

        if (response.statusCode == 200) {
          try {
            // Sử dụng phương pháp phân tích JSON cải tiến
            final data = await _tryParseJson(response.body);

            if (data['status'] == true && data['data'] != null) {
              final productsData = data['data'];
              final List<Product> products = [];

              if (productsData['products'] is List) {
                for (var item in productsData['products']) {
                  try {
                    products.add(Product.fromJson(item));
                  } catch (e) {
                    print('Error parsing product: $e');
                    // Tiếp tục với sản phẩm tiếp theo
                  }
                }
              }

              // Xử lý pagination
              Pagination pagination;
              try {
                pagination = Pagination.fromJson(productsData['pagination']);
              } catch (e) {
                print('Error parsing pagination: $e. Using defaults');
                pagination = Pagination(
                  currentPage: page,
                  lastPage: page,
                  perPage: perPage,
                  total: products.length,
                );
              }

              return PaginationResponse(
                items: products,
                pagination: pagination,
              );
            }

            // Thử lại nếu dữ liệu không hợp lệ
            if (retryCount < maxRetries - 1) {
              retryCount++;
              print('Retry attempt $retryCount due to invalid data structure');
              continue;
            }
            throw Exception(data['message'] ??
                'Failed to load products: Invalid data structure');
          } catch (e) {
            // Thử lại nếu có lỗi khi phân tích JSON
            if (retryCount < maxRetries - 1) {
              retryCount++;
              print('Retry attempt $retryCount due to parsing error: $e');
              await Future.delayed(Duration(
                  milliseconds: 500)); // Chờ một chút trước khi thử lại
              continue;
            }

            // Nếu là trang > 1, trả về danh sách trống thay vì gây lỗi
            if (page > 1) {
              print(
                  'Returning empty results for page > 1 after $retryCount parsing failures');
              return PaginationResponse(
                items: [],
                pagination: Pagination(
                  currentPage: page,
                  lastPage: page,
                  perPage: perPage,
                  total: 0,
                ),
              );
            }
            throw Exception(
                'Failed to parse product data after $retryCount attempts: $e');
          }
        } else {
          // Thử lại nếu không phải HTTP 200
          if (retryCount < maxRetries - 1) {
            retryCount++;
            print(
                'Retry attempt $retryCount due to HTTP error: ${response.statusCode}');
            await Future.delayed(
                Duration(milliseconds: 500)); // Chờ một chút trước khi thử lại
            continue;
          }
          throw Exception(
              'HTTP error after $retryCount retries: ${response.statusCode}');
        }
      } catch (e) {
        // Thử lại nếu có lỗi network hoặc lỗi khác
        if (retryCount < maxRetries - 1) {
          retryCount++;
          print('Retry attempt $retryCount due to error: $e');
          await Future.delayed(Duration(milliseconds: 500));
          continue;
        }

        // Nếu là trang > 1, trả về danh sách trống thay vì gây lỗi
        if (page > 1) {
          print(
              'Returning empty results for page > 1 after $retryCount failures');
          return PaginationResponse(
            items: [],
            pagination: Pagination(
              currentPage: page,
              lastPage: page,
              perPage: perPage,
              total: 0,
            ),
          );
        }
        throw Exception(
            'Failed to load products after $retryCount retries: $e');
      }
    }

    // Code không bao giờ đến đây
    throw Exception('Unexpected error in product loading');
  }

  Future<PaginationResponse<Product>> getProductsByCategory(
      int categoryId, int page, int perPage) async {
    print('Gọi getProductsByCategory với categoryId=$categoryId, page=$page');

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final uri = Uri.parse(
            '$api_products_by_category?cat_id=$categoryId&page=$page&per_page=$perPage');
        final response = await http.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (g_token.isNotEmpty) 'Authorization': 'Bearer $g_token',
          },
        );

        print('Request URL: $uri');
        print('Response Status: ${response.statusCode}');
        print('Response Length: ${response.body.length}');

        if (response.body.isEmpty) {
          throw Exception('Empty response received');
        }

        if (response.statusCode == 200) {
          try {
            // Sử dụng phương pháp phân tích JSON cải tiến
            final data = await _tryParseJson(response.body);

            if (data['status'] == true && data['data'] != null) {
              final productsData = data['data'];
              final List<Product> products = [];

              if (productsData['products'] is List) {
                for (var item in productsData['products']) {
                  try {
                    products.add(Product.fromJson(item));
                  } catch (e) {
                    print('Error parsing product: $e');
                  }
                }
              }

              // Xử lý pagination
              Pagination pagination;
              try {
                pagination = Pagination.fromJson(productsData['pagination']);
              } catch (e) {
                print('Error parsing pagination: $e. Using defaults');
                pagination = Pagination(
                  currentPage: page,
                  lastPage: page,
                  perPage: perPage,
                  total: products.length,
                );
              }

              return PaginationResponse(
                items: products,
                pagination: pagination,
              );
            }

            throw Exception('Invalid data structure');
          } catch (e) {
            // Thử lại nếu có lỗi khi phân tích JSON
            if (retryCount < maxRetries - 1) {
              retryCount++;
              print('Retry attempt $retryCount due to parsing error: $e');
              await Future.delayed(Duration(milliseconds: 500));
              continue;
            }
            throw Exception('Failed to parse category product data: $e');
          }
        } else {
          // Thử lại nếu không phải HTTP 200
          if (retryCount < maxRetries - 1) {
            retryCount++;
            print(
                'Retry attempt $retryCount due to HTTP error: ${response.statusCode}');
            await Future.delayed(Duration(milliseconds: 500));
            continue;
          }
          throw Exception('HTTP error: ${response.statusCode}');
        }
      } catch (e) {
        // Thử lại nếu có lỗi network hoặc lỗi khác
        if (retryCount < maxRetries - 1) {
          retryCount++;
          print('Retry attempt $retryCount due to error: $e');
          await Future.delayed(Duration(milliseconds: 500));
          continue;
        }

        throw Exception('Failed to load products by category: $e');
      }
    }

    // Code không bao giờ đến đây
    throw Exception('Unexpected error in loading category products');
  }

  Future<PaginationResponse<Product>> searchProducts(
      String keyword,
      int page,
      int perPage, {
        String? sortBy,
        String? sortOrder,
        double? minPrice,
        double? maxPrice,
        List<int>? categoryIds,
      }) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        // Tạo URL với query parameters
        final queryParams = {
          'page': page.toString(),
          'limit': perPage.toString(),
          'keyword': keyword,
        };

        // Thêm các tham số tùy chọn nếu có
        if (sortBy != null && sortBy.isNotEmpty) {
          if (sortBy == 'name') {
            queryParams['sort_by'] = 'title'; // Đảm bảo trường sắp xếp đúng
          } else {
            queryParams['sort_by'] = sortBy;
          }
        }

        if (sortOrder != null && sortOrder.isNotEmpty) {
          queryParams['sort_order'] = sortOrder;
        }

        // Xử lý tham số giá, đảm bảo không truyền giá trị null hoặc không hợp lệ
        if (minPrice != null && minPrice > 0) {
          String priceMinStr = minPrice.toInt().toString();
          queryParams['price_min'] = priceMinStr;
          print('Áp dụng giá min: $priceMinStr');
        }

        if (maxPrice != null && maxPrice > 0) {
          String priceMaxStr = maxPrice.toInt().toString();
          queryParams['price_max'] = priceMaxStr;
          print('Áp dụng giá max: $priceMaxStr');
        }

        if (categoryIds != null && categoryIds.isNotEmpty)
          queryParams['category_ids'] = categoryIds.join(',');

        // In log để debug chi tiết
        print('Search params được gửi tới API: $queryParams');

        final uri = Uri.parse(api_products_search).replace(
          queryParameters: queryParams,
        );

        // Gửi yêu cầu
        final response = await http.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (g_token.isNotEmpty) 'Authorization': 'Bearer $g_token',
          },
        );

        print('Search request URL: $uri');
        print('Search response status: ${response.statusCode}');
        print('Search response body length: ${response.body.length}');
        if (response.body.length < 1000) {
          print('Response body: ${response.body}');
        }

        // Kiểm tra response status
        if (response.statusCode >= 200 && response.statusCode < 300) {
          Map<String, dynamic> data;
          try {
            data = await _tryParseJson(response.body);
          } catch (e) {
            print('Error parsing JSON from search request: $e');
            throw Exception('Không thể phân tích dữ liệu từ máy chủ');
          }

          // Check response format and extract products
          final List<Product> products = [];
          Pagination pagination;

          // Xử lý trường hợp data['data'] là Map hoặc List
          if (data['status'] == true && data['data'] != null) {
            final productsData = data['data'];

            if (productsData is Map && productsData['products'] is List) {
              // Trường hợp API trả về định dạng { "data": { "products": [...] } }
              for (var item in productsData['products']) {
                try {
                  products.add(Product.fromJson(item));
                } catch (e) {
                  print('Error parsing product: $e');
                }
              }

              // Xử lý pagination
              try {
                pagination =
                    Pagination.fromJson(productsData['pagination'] ?? {});
              } catch (e) {
                print('Error parsing pagination: $e. Using defaults');
                pagination = Pagination(
                  currentPage: page,
                  lastPage: page,
                  perPage: perPage,
                  total: products.length,
                );
              }
            } else if (productsData is List) {
              // Trường hợp API trả về định dạng { "data": [...] }
              for (var item in productsData) {
                try {
                  products.add(Product.fromJson(item));
                } catch (e) {
                  print('Error parsing product: $e');
                }
              }

              // Xử lý pagination từ data['pagination']
              try {
                pagination = Pagination.fromJson(data['pagination'] ?? {});
              } catch (e) {
                print('Error parsing pagination: $e. Using defaults');
                pagination = Pagination(
                  currentPage: page,
                  lastPage: page,
                  perPage: perPage,
                  total: products.length,
                );
              }
            } else {
              throw Exception('Định dạng dữ liệu không hợp lệ');
            }
          } else {
            // Trường hợp không có dữ liệu
            pagination = Pagination(
              total: 0,
              perPage: perPage,
              currentPage: page,
              lastPage: 1,
            );
          }

          return PaginationResponse<Product>(
            items: products,
            pagination: pagination,
          );
        } else if (response.statusCode == 404) {
          // Không tìm thấy sản phẩm
          return PaginationResponse<Product>(
            items: [],
            pagination: Pagination(
              total: 0,
              perPage: perPage,
              currentPage: page,
              lastPage: 1,
            ),
          );
        } else {
          throw Exception('Lỗi từ máy chủ: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          rethrow;
        }
        // Chờ một chút trước khi thử lại
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }

    // Nếu tất cả các lần thử đều thất bại, trả về danh sách rỗng
    throw Exception('Không thể tìm kiếm sản phẩm sau nhiều lần thử');
  }

  // Lấy chi tiết sản phẩm theo ID
  Future<Product?> getProductById(int productId) async {
    final url = Uri.parse('$api_product_detail/$productId');

    try {
      print('Gửi yêu cầu GET chi tiết sản phẩm đến URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (g_token.isNotEmpty) 'Authorization': 'Bearer $g_token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP Error: ${response.statusCode}');
      }

      final data = await _tryParseJson(response.body);

      if (data['data'] != null) {
        return Product.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy chi tiết sản phẩm: $e');
      rethrow;
    }
  }

  // Hàm chuyển đổi URL localhost sang địa chỉ IP máy chủ
  String _transformImageUrl(String url) {
    // Thay thế 127.0.0.1 or localhost bằng địa chỉ IP thực của máy chủ
    // Dành cho môi trường phát triển
    if (url.contains('127.0.0.1:8000') || url.contains('localhost:8000')) {
      // Dùng địa chỉ IP của máy tính trong mạng nội bộ
      // 10.0.2.2 là địa chỉ đặc biệt để từ emulator Android truy cập localhost của máy chủ
      return url
          .replaceFirst('127.0.0.1:8000', '10.0.2.2:8000')
          .replaceFirst('localhost:8000', '10.0.2.2:8000');
    }
    return url;
  }

  // Lấy danh sách sản phẩm yêu thích trực tiếp từ API
  Future<List<Product>> getWishlistProducts() async {
    if (g_token.isEmpty) {
      return [];
    }

    final url = Uri.parse(api_wishlist_view);

    try {
      print('Gửi yêu cầu GET danh sách sản phẩm yêu thích đến URL: $url');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $g_token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body length: ${response.body.length}');
      // Print first 200 characters to debug
      if (response.body.length > 0) {
        print(
            'Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true &&
            data['data'] != null &&
            data['data']['wishlists'] != null) {
          final List<dynamic> wishlistItems = data['data']['wishlists'];
          final List<Product> products = [];

          for (var item in wishlistItems) {
            if (item['product'] != null) {
              try {
                final productData = item['product'];
                print(
                    'Processing product: ${productData['id']} - ${productData['title']}');

                // Xử lý danh sách ảnh từ API mới
                List<String> processedPhotos = [];
                if (productData['photos'] is List) {
                  // API đã trả về mảng URLs - sử dụng trực tiếp
                  processedPhotos = List<String>.from(productData['photos'])
                      .map((url) => _transformImageUrl(url))
                      .toList();
                  print(
                      'Found ${processedPhotos.length} photos for product ${productData['id']}');
                  if (processedPhotos.isNotEmpty) {
                    print(
                        'First photo URL (transformed): ${processedPhotos.first}');
                  }
                } else if (productData['photos'] is String) {
                  // Nếu API trả về chuỗi duy nhất
                  String photoUrl = _transformImageUrl(productData['photos']);
                  if (photoUrl.isNotEmpty) {
                    processedPhotos.add(photoUrl);
                    print('Single photo URL (transformed): $photoUrl');
                  }
                }

                // Đảm bảo danh sách không rỗng
                if (processedPhotos.isEmpty) {
                  processedPhotos.add(
                      'https://via.placeholder.com/150/cccccc/ffffff?text=No+Image');
                  print('No photos found, using placeholder');
                }

                // Tạo đối tượng Product từ dữ liệu API
                final product = Product(
                  id: productData['id'],
                  title: productData['title'],
                  price: double.parse(productData['price'].toString()),
                  description: productData['description'] ?? '',
                  photos: processedPhotos,
                  categoryId: productData['category_id'] ?? 0,
                  brandId: productData['brand_id'] ?? 0,
                  stock: productData['stock'] ??
                      0, // Use stock from API or default to 0
                );
                products.add(product);
              } catch (e) {
                print('Lỗi khi xử lý dữ liệu sản phẩm: $e');
              }
            }
          }

          print('Tải thành công ${products.length} sản phẩm yêu thích');
          return products;
        }
      }

      return [];
    } catch (e) {
      print('Lỗi khi lấy danh sách sản phẩm yêu thích: $e');
      return [];
    }
  }

  Future<Product> getProductDetails(int productId) async {
    try {
      final url = Uri.parse('$api_product_detail/$productId');

      print('Sending GET request to: $url');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (g_token.isNotEmpty) 'Authorization': 'Bearer $g_token',
        },
      );

      print('Response status code: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('HTTP Error: ${response.statusCode}');
      }

      try {
        final data = await _tryParseJson(response.body);

        if (data['data'] != null) {
          final productData = data['data'];
          return Product.fromJson(productData);
        }

        throw Exception(data['message'] ?? 'Product data not found');
      } catch (e) {
        print('JSON parsing error: $e');
        throw Exception('Failed to parse product data: $e');
      }
    } catch (e) {
      print('Error in getProductDetails: $e');
      throw Exception('Failed to load product details: $e');
    }
  }
}
