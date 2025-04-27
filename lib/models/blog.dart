class Blog {
  final int id;
  final String title;
  final String slug;
  final String content;
  final String photo;
  final int catId;
  final String status;
  final int hit;
  final String? categoryName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Blog({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    required this.photo,
    required this.catId,
    required this.status,
    required this.hit,
    this.categoryName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      content: json['content'],
      photo: json['photo'],
      catId: json['cat_id'],
      status: json['status'],
      hit: json['hit'],
      categoryName: json['category_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'content': content,
      'photo': photo,
      'cat_id': catId,
      'status': status,
      'hit': hit,
      'category_name': categoryName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class BlogPagination {
  final List<Blog> blogs;
  final int total;
  final int currentPage;
  final int perPage;
  final int lastPage;

  BlogPagination({
    required this.blogs,
    required this.total,
    required this.currentPage,
    required this.perPage,
    required this.lastPage,
  });

  factory BlogPagination.fromJson(Map<String, dynamic> json) {
    var blogsList = (json['data'] as List)
        .map((blogJson) => Blog.fromJson(blogJson))
        .toList();

    return BlogPagination(
      blogs: blogsList,
      total: json['total'],
      currentPage: json['current_page'],
      perPage: json['per_page'],
      lastPage: json['last_page'],
    );
  }
}

class BlogTag {
  final int id;
  final String name;
  final String status;

  BlogTag({
    required this.id,
    required this.name,
    required this.status,
  });

  factory BlogTag.fromJson(Map<String, dynamic> json) {
    return BlogTag(
      id: json['id'],
      name: json['name'],
      status: json['status'],
    );
  }
}
