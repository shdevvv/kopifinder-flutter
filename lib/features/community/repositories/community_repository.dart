import '../../../core/network/api_client.dart';
import '../models/community_models.dart';

class CommunityRepository {
  CommunityRepository._();
  static final CommunityRepository instance = CommunityRepository._();

  final ApiClient _api = ApiClient.instance;

  Future<List<CommunityPost>> getPosts({int page = 1, int limit = 20}) async {
    try {
      final response = await _api.get('/posts', queryParameters: {'page': page, 'limit': limit});
      if (response is List) {
        return response.map((p) => CommunityPost.fromJson(p as Map<String, dynamic>)).toList();
      }
      return _defaultPosts();
    } catch (_) {
      return _defaultPosts();
    }
  }

  Future<CommunityPost> createPost({
    required String caption,
    String? cafeId,
    List<String> photos = const [],
  }) async {
    final response = await _api.post(
      '/posts',
      body: {
        'caption': caption,
        if (cafeId != null) 'cafe_id': cafeId,
        'photos': photos,
      },
    );
    if (response is Map<String, dynamic>) {
      return CommunityPost.fromJson(response);
    }
    return CommunityPost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'You',
      location: 'Jakarta',
      caption: caption,
      createdAt: DateTime.now(),
    );
  }

  Future<bool> toggleLike(String postId, bool currentlyLiked) async {
    try {
      if (currentlyLiked) {
        await _api.delete('/posts/$postId/like');
        return false;
      } else {
        await _api.post('/posts/$postId/like');
        return true;
      }
    } catch (_) {
      return !currentlyLiked;
    }
  }

  Future<List<CommunityComment>> getComments(String postId) async {
    try {
      final response = await _api.get('/posts/$postId/comments');
      if (response is List) {
        return response.map((c) => CommunityComment.fromJson(c as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<CommunityComment> addComment({
    required String postId,
    required String text,
    String? parentCommentId,
  }) async {
    final response = await _api.post(
      '/posts/$postId/comments',
      body: {
        'content': text,
        if (parentCommentId != null) 'parent_comment_id': parentCommentId,
      },
    );
    if (response is Map<String, dynamic>) {
      return CommunityComment.fromJson(response);
    }
    return CommunityComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: postId,
      name: 'You',
      text: text,
      createdAt: DateTime.now(),
    );
  }

  Future<void> deletePost(String postId) async {
    await _api.delete('/posts/$postId');
  }

  List<CommunityPost> _defaultPosts() {
    return [
      CommunityPost(
        id: 'post-1',
        name: 'Coffee Explorer',
        location: 'First Coffee, Senopati',
        caption: 'Menemukan tempat ngopi yang nyaman untuk kerja hari ini! Wi-Fi kencang dan suasananya tenang banget.',
        likes: 24,
        comments: [
          CommunityComment(
            id: 'c-1',
            postId: 'post-1',
            name: 'Coffee Lover',
            text: 'Tempatnya di mana persisnya?',
            likes: 2,
            replies: [
              CommunityReply(
                id: 'r-1',
                name: 'Coffee Explorer',
                text: 'Di Jl. Senopati No. 41, dekat lapangan sepak bola!',
              ),
            ],
          ),
        ],
      ),
      CommunityPost(
        id: 'post-2',
        name: 'Daily Coffee',
        location: 'Daily Brew, Gandaria',
        caption: 'Weekend paling pas ditemani secangkir latte dan pastry hangat ☕🥐',
        likes: 18,
      ),
    ];
  }
}
