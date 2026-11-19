import 'dart:io';

class CommunityReply {
  final String? id;
  final String name;
  final String text;
  final DateTime? createdAt;

  CommunityReply({
    this.id,
    required this.name,
    required this.text,
    this.createdAt,
  });

  factory CommunityReply.fromJson(Map<String, dynamic> json) {
    String author = 'Anonymous';
    if (json['author'] is Map) {
      author = json['author']['full_name'] ?? json['author']['username'] ?? author;
    } else if (json['user'] is Map) {
      author = json['user']['full_name'] ?? json['user']['username'] ?? author;
    } else if (json['name'] != null) {
      author = json['name'].toString();
    }

    return CommunityReply(
      id: json['id']?.toString(),
      name: author,
      text: json['content']?.toString() ?? json['text']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class CommunityComment {
  final String? id;
  final String? postId;
  final String name;
  final String text;
  int likes;
  bool liked;
  final List<CommunityReply> replies;
  final DateTime? createdAt;

  CommunityComment({
    this.id,
    this.postId,
    required this.name,
    required this.text,
    this.likes = 0,
    this.liked = false,
    List<CommunityReply>? replies,
    this.createdAt,
  }) : replies = replies ?? [];

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    String author = 'Anonymous';
    if (json['author'] is Map) {
      author = json['author']['full_name'] ?? json['author']['username'] ?? author;
    } else if (json['user'] is Map) {
      author = json['user']['full_name'] ?? json['user']['username'] ?? author;
    } else if (json['name'] != null) {
      author = json['name'].toString();
    }

    List<CommunityReply> reps = [];
    if (json['replies'] is List) {
      reps = (json['replies'] as List)
          .map((r) => CommunityReply.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return CommunityComment(
      id: json['id']?.toString(),
      postId: json['post_id']?.toString(),
      name: author,
      text: json['content']?.toString() ?? json['text']?.toString() ?? '',
      likes: (json['likes_count'] as num?)?.toInt() ?? (json['likes'] as num?)?.toInt() ?? 0,
      liked: json['is_liked'] == true || json['liked'] == true,
      replies: reps,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class CommunityPost {
  final String? id;
  final String? userId;
  final String name;
  final String? avatarUrl;
  final String location;
  final String caption;
  final File? image;
  final String? imageUrl;
  int likes;
  bool liked;
  final List<CommunityComment> comments;
  final DateTime? createdAt;

  CommunityPost({
    this.id,
    this.userId,
    required this.name,
    this.avatarUrl,
    required this.location,
    required this.caption,
    this.image,
    this.imageUrl,
    this.likes = 0,
    this.liked = false,
    List<CommunityComment>? comments,
    this.createdAt,
  }) : comments = comments ?? [];

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    String author = 'Pengguna KopiFinder';
    String? avatar;
    if (json['author'] is Map) {
      author = json['author']['full_name']?.toString() ??
          json['author']['username']?.toString() ??
          json['author']['name']?.toString() ??
          author;
      avatar = json['author']['avatar_url']?.toString();
    } else if (json['user'] is Map) {
      author = json['user']['full_name']?.toString() ??
          json['user']['username']?.toString() ??
          json['user']['name']?.toString() ??
          author;
      avatar = json['user']['avatar_url']?.toString();
    } else if (json['name'] != null && json['name'].toString().isNotEmpty) {
      author = json['name'].toString();
    }

    String loc = 'Jakarta';
    if (json['cafe'] is Map) {
      loc = json['cafe']['name']?.toString() ?? loc;
    } else if (json['location'] != null) {
      loc = json['location'].toString();
    }

    List<CommunityComment> comms = [];
    if (json['comments'] is List) {
      comms = (json['comments'] as List)
          .map((c) => CommunityComment.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    String? photo;
    if (json['photo_url'] != null) {
      photo = json['photo_url'].toString();
    } else if (json['photos'] is List && (json['photos'] as List).isNotEmpty) {
      photo = (json['photos'] as List).first.toString();
    }

    return CommunityPost(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      name: author,
      avatarUrl: avatar,
      location: loc,
      caption: json['caption']?.toString() ?? '',
      imageUrl: photo,
      likes: (json['likes_count'] as num?)?.toInt() ?? (json['likes'] as num?)?.toInt() ?? 0,
      liked: json['is_liked'] == true || json['liked'] == true,
      comments: comms,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
