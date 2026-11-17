class Review {
  final String id;
  final String cafeId;
  final String userId;
  final String authorName;
  final String? authorAvatar;
  final int rating;
  final String comment;
  final List<String> photos;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.cafeId,
    required this.userId,
    required this.authorName,
    this.authorAvatar,
    required this.rating,
    required this.comment,
    this.photos = const [],
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, [int fallback = 5]) {
      if (val == null) return fallback;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    String author = 'Anonymous';
    String? avatar;
    if (json['author'] is Map) {
      author = json['author']['full_name'] ?? json['author']['username'] ?? author;
      avatar = json['author']['avatar_url'];
    } else if (json['user'] is Map) {
      author = json['user']['full_name'] ?? json['user']['username'] ?? author;
      avatar = json['user']['avatar_url'];
    }

    List<String> photos = [];
    if (json['photos'] is List) {
      photos = (json['photos'] as List).map((e) => e.toString()).toList();
    }

    DateTime? created;
    if (json['created_at'] != null) {
      created = DateTime.tryParse(json['created_at'].toString());
    }

    return Review(
      id: json['id']?.toString() ?? '',
      cafeId: json['cafe_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      authorName: author,
      authorAvatar: avatar,
      rating: parseInt(json['rating'], 5),
      comment: json['comment']?.toString() ?? '',
      photos: photos,
      createdAt: created,
    );
  }
}
