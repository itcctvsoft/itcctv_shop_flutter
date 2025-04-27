class Category {
  final int id;
  final String title;
  final String slug;
  final List<String> photos;
  final String description;
  final int isParent;

  Category({
    required this.id,
    required this.title,
    required this.slug,
    required this.photos,
    required this.isParent,
    required this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    List<String> photosList = [];
    if (json['photos'] is List) {
      photosList = List<String>.from(json['photos']);
    } else if (json['photo'] != null) {
      final photoString = json['photo'].toString();
      final photoList =
          photoString.split(',').where((p) => p.trim().isNotEmpty).toList();
      photosList = photoList.map((photo) => photo.trim()).toList();
    }

    if (photosList.isEmpty) {
      photosList
          .add('https://via.placeholder.com/150/cccccc/000000?text=No+Image');
    }

    return Category(
      id: json['id'] as int,
      title: json['title'] as String,
      slug: json['slug'] as String,
      photos: photosList,
      description: json['description'] as String,
      isParent: json['is_parent'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'photos': photos,
      'description': description,
      'is_parent': isParent,
    };
  }

  String get mainPhoto => photos.isNotEmpty ? photos.first : '';
}

class CategoryApiResponse {
  final List<Category> categories;
  final Pagination pagination;

  CategoryApiResponse({
    required this.categories,
    required this.pagination,
  });

  factory CategoryApiResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    // Parse categories
    final categoriesList = data['categories'] as List<dynamic>;
    final categories =
        categoriesList.map((item) => Category.fromJson(item)).toList();

    // Parse pagination
    final paginationData = data['pagination'] as Map<String, dynamic>;
    final pagination = Pagination.fromJson(paginationData);

    return CategoryApiResponse(
      categories: categories,
      pagination: pagination,
    );
  }
}

class Pagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
    };
  }
}
