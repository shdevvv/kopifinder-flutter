class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final String location;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.location = 'Jakarta, Indonesia',
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final email = json['email']?.toString() ?? '';
    final defaultUsername = email.isNotEmpty ? email.split('@').first : 'user';
    final defaultName = email.isNotEmpty ? email.split('@').first : 'User';

    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: email,
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? defaultName,
      username: json['username']?.toString() ?? defaultUsername,
      avatarUrl: json['avatar_url']?.toString(),
      bio: json['bio']?.toString(),
      location: json['location']?.toString() ?? 'Jakarta, Indonesia',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'username': username,
        'avatar_url': avatarUrl,
        'bio': bio,
        'location': location,
      };
}

class UserStats {
  final int reviewsCount;
  final int bookmarksCount;
  final int postsCount;
  final int commentsCount;

  const UserStats({
    this.reviewsCount = 0,
    this.bookmarksCount = 0,
    this.postsCount = 0,
    this.commentsCount = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    return UserStats(
      reviewsCount: parseInt(json['reviews_count'] ?? json['reviews']),
      bookmarksCount: parseInt(json['bookmarks_count'] ?? json['saved_cafes_count'] ?? json['saved_cafes'] ?? json['saved']),
      postsCount: parseInt(json['posts_count'] ?? json['posts']),
      commentsCount: parseInt(json['comments_count'] ?? json['comments']),
    );
  }
}
