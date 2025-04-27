// import 'package:shoplite/models/user.dart';

// Tạo mô hình CommentUser riêng biệt
class CommentUser {
  final int? id;
  final String full_name;
  final String photo;

  CommentUser({
    this.id,
    required this.full_name,
    required this.photo,
  });

  factory CommentUser.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CommentUser(
        id: null,
        full_name: 'Người dùng ẩn danh',
        photo: '',
      );
    }

    return CommentUser(
      id: json['id'] as int?,
      full_name: json['full_name'] as String? ?? 'Người dùng ẩn danh',
      photo: json['photo'] as String? ?? '',
    );
  }
}

class Comment {
  final int? id;
  final int productId;
  final int userId;
  final String comment;
  final int rating;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final CommentUser? user; // Đã thay đổi từ User thành CommentUser

  Comment({
    this.id,
    required this.productId,
    required this.userId,
    required this.comment,
    required this.rating,
    this.status = 'approved',
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    try {
      // Phân tích trường user một cách an toàn
      CommentUser? userObj;
      if (json['user'] != null) {
        try {
          userObj = CommentUser.fromJson(json['user'] as Map<String, dynamic>);
        } catch (e) {
          print('Lỗi khi phân tích user: $e');
          userObj = CommentUser(full_name: 'Người dùng ẩn danh', photo: '');
        }
      }

      return Comment(
        id: json['id'] as int?,
        productId: json['product_id'] as int? ?? 0,
        userId: json['user_id'] as int? ?? 0,
        comment: json['comment'] as String? ?? '',
        rating: json['rating'] as int? ?? 5,
        status: json['status'] as String? ?? 'approved',
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
        user: userObj,
      );
    } catch (e) {
      print('Lỗi trong Comment.fromJson: $e');
      // Trả về đối tượng bình luận tối thiểu để tránh null
      return Comment(
        userId: 0,
        productId: 0,
        comment: 'Lỗi khi tải bình luận',
        rating: 5,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'comment': comment,
      'rating': rating,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Tạo một bản sao của Comment với các thuộc tính mới
  Comment copyWith({
    int? id,
    int? userId,
    int? productId,
    String? comment,
    int? rating,
    String? status,
    String? createdAt,
    String? updatedAt,
    CommentUser? user, // Đã thay đổi từ User thành CommentUser
  }) {
    return Comment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      comment: comment ?? this.comment,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
    );
  }
}

class CommentResponse {
  final bool success;
  final int totalComments;
  final double averageRating;
  final List<Comment> comments;

  CommentResponse({
    required this.success,
    required this.totalComments,
    required this.averageRating,
    required this.comments,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) {
    try {
      final commentsList = json['comments'] as List<dynamic>? ?? [];
      List<Comment> parsedComments = [];

      for (final commentJson in commentsList) {
        try {
          parsedComments
              .add(Comment.fromJson(commentJson as Map<String, dynamic>));
        } catch (e) {
          print('Lỗi khi phân tích bình luận đơn: $e');
          // Tiếp tục với bình luận tiếp theo ngay cả khi có lỗi
        }
      }

      return CommentResponse(
        success: json['success'] as bool? ?? false,
        totalComments: json['total_comments'] as int? ?? 0,
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
        comments: parsedComments,
      );
    } catch (e) {
      print('Lỗi trong CommentResponse.fromJson: $e');
      return CommentResponse(
        success: false,
        totalComments: 0,
        averageRating: 0.0,
        comments: [],
      );
    }
  }
}
