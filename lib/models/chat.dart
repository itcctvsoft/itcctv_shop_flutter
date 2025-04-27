import 'dart:convert';

class Chat {
  final int id;
  final String name;
  final bool isPrivate;
  final int createdBy;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chat({
    required this.id,
    required this.name,
    required this.isPrivate,
    required this.createdBy,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      name: json['name'],
      isPrivate: json['is_private'] == 1 || json['is_private'] == true,
      createdBy: json['created_by'],
      type: json['type'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_private': isPrivate,
      'created_by': createdBy,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
