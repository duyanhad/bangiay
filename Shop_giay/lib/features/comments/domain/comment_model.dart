class Reply {
  final String content;
  final DateTime createdAt;

  Reply({required this.content, required this.createdAt});

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      content: json['content'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class Comment {
  final String id;
  final String userName;
  final String content;
  final int? rating;
  final List<String> images; // ✅ THÊM BIẾN NÀY
  final DateTime createdAt;
  final List<Reply> replies;

  Comment({
    required this.id,
    required this.userName,
    required this.content,
    this.rating,
    required this.images,
    required this.createdAt,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'] ?? '',
      userName: json['userName'] ?? 'Người dùng',
      content: json['content'] ?? '',
      rating: json['rating'],
      // ✅ PARSE MẢNG ẢNH TỪ JSON
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      replies: (json['replies'] as List?)?.map((e) => Reply.fromJson(e)).toList() ?? [],
    );
  }
}