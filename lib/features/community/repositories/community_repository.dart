import '../../../core/network/api_client.dart';
import '../../../core/services/supabase_service.dart';
import '../models/community_models.dart';

class CommunityRepository {
  CommunityRepository._();
  static final CommunityRepository instance = CommunityRepository._();

  final ApiClient _api = ApiClient.instance;

  Future<List<CommunityPost>> getPosts({int page = 1, int limit = 20}) async {
    final sb = SupabaseService.instance;

    // 1. Direct fetch from Supabase table 'posts'
    if (sb.isInitialized && sb.client != null) {
      try {
        final data = await sb.client!
            .from('posts')
            .select('id,user_id,cafe_id,caption,photo_url,likes_count,comments_count,created_at')
            .order('created_at', ascending: false)
            .limit(limit);

        if (data.isNotEmpty) {
          final userIds = data
              .map((p) => p['user_id']?.toString())
              .where((id) => id != null && id.isNotEmpty)
              .toSet()
              .toList();

          Map<String, Map<String, dynamic>> profiles = {};
          if (userIds.isNotEmpty) {
            try {
              final usersData = await sb.client!
                  .from('users')
                  .select('id,full_name,username,avatar_url')
                  .filter('id', 'in', userIds);
              for (final u in (usersData as List)) {
                profiles[u['id'].toString()] = u as Map<String, dynamic>;
              }
            } catch (_) {}
          }

          Set<String> myLikes = {};
          if (sb.currentUser != null) {
            try {
              final likesData = await sb.client!
                  .from('post_likes')
                  .select('post_id')
                  .eq('user_id', sb.currentUser!.id);
              for (final l in (likesData as List)) {
                myLikes.add(l['post_id'].toString());
              }
            } catch (_) {}
          }

          return data.map((p) {
            final uid = p['user_id']?.toString();
            final profile = uid != null ? profiles[uid] : null;
            final author = profile?['full_name']?.toString() ??
                profile?['username']?.toString() ??
                (uid == sb.currentUser?.id ? 'Stephanie' : 'Coffee Explorer');

            return CommunityPost(
              id: p['id']?.toString(),
              userId: uid,
              name: author,
              avatarUrl: profile?['avatar_url']?.toString(),
              location: 'Jakarta',
              caption: p['caption']?.toString() ?? '',
              imageUrl: p['photo_url']?.toString(),
              likes: (p['likes_count'] as num?)?.toInt() ?? 0,
              liked: myLikes.contains(p['id']?.toString()),
              createdAt: p['created_at'] != null ? DateTime.tryParse(p['created_at'].toString()) : null,
            );
          }).toList();
        }
      } catch (_) {}
    }

    // 2. Fetch via Backend API
    try {
      final response = await _api.get('/posts', queryParameters: {'page': page, 'limit': limit});
      if (response is List && response.isNotEmpty) {
        return response.map((p) => CommunityPost.fromJson(p as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return _defaultPosts();
  }

  Future<CommunityPost> createPost({
    required String caption,
    String? cafeId,
    List<String> photos = const [],
    String? photoUrl,
  }) async {
    final sb = SupabaseService.instance;
    final currentUser = sb.currentUser;

    // 1. Direct Supabase insertion if authenticated
    if (sb.isInitialized && currentUser != null && sb.client != null) {
      try {
        final inserted = await sb.client!.from('posts').insert({
          'user_id': currentUser.id,
          'caption': caption,
          if (cafeId != null && cafeId.isNotEmpty) 'cafe_id': cafeId,
          if (photoUrl != null && photoUrl.isNotEmpty) 'photo_url': photoUrl,
        }).select('id,user_id,caption,photo_url,likes_count,comments_count,created_at').single();

        String authorName = currentUser.userMetadata?['full_name']?.toString() ??
            currentUser.userMetadata?['name']?.toString() ??
            'Stephanie';
        try {
          final u = await sb.client!.from('users').select('full_name,username').eq('id', currentUser.id).maybeSingle();
          if (u != null && u['full_name'] != null && u['full_name'].toString().isNotEmpty) {
            authorName = u['full_name'].toString();
          }
        } catch (_) {}

        return CommunityPost(
          id: inserted['id']?.toString(),
          userId: currentUser.id,
          name: authorName,
          location: 'Jakarta',
          caption: caption,
          imageUrl: photoUrl,
          createdAt: DateTime.now(),
        );
      } catch (_) {}
    }

    // 2. Fallback to Backend API
    try {
      final response = await _api.post(
        '/posts',
        body: {
          'caption': caption,
          if (cafeId != null && cafeId.isNotEmpty) 'cafe_id': cafeId,
          if (photoUrl != null && photoUrl.isNotEmpty) 'photo_path': photoUrl,
        },
      );
      if (response is Map<String, dynamic>) {
        return CommunityPost.fromJson(response);
      }
    } catch (_) {}

    return CommunityPost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Stephanie',
      location: 'Jakarta',
      caption: caption,
      createdAt: DateTime.now(),
    );
  }

  Future<bool> toggleLike(String postId, bool currentlyLiked) async {
    final sb = SupabaseService.instance;
    final currentUser = sb.currentUser;

    if (sb.isInitialized && currentUser != null && sb.client != null) {
      try {
        if (currentlyLiked) {
          await sb.client!.from('post_likes').delete().eq('post_id', postId).eq('user_id', currentUser.id);
          return false;
        } else {
          await sb.client!.from('post_likes').upsert({
            'post_id': postId,
            'user_id': currentUser.id,
          }, onConflict: 'post_id,user_id');
          return true;
        }
      } catch (_) {}
    }

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
    final sb = SupabaseService.instance;
    final currentUser = sb.currentUser;

    if (sb.isInitialized && currentUser != null && sb.client != null) {
      try {
        final inserted = await sb.client!.from('comments').insert({
          'post_id': postId,
          'user_id': currentUser.id,
          'text': text,
          if (parentCommentId != null) 'parent_id': parentCommentId,
        }).select('id,post_id,parent_id,text,created_at').single();

        String authorName = currentUser.userMetadata?['full_name']?.toString() ??
            currentUser.userMetadata?['name']?.toString() ??
            'Stephanie';
        try {
          final u = await sb.client!.from('users').select('full_name,username').eq('id', currentUser.id).maybeSingle();
          if (u != null && u['full_name'] != null && u['full_name'].toString().isNotEmpty) {
            authorName = u['full_name'].toString();
          }
        } catch (_) {}

        return CommunityComment(
          id: inserted['id']?.toString(),
          postId: postId,
          name: authorName,
          text: text,
          createdAt: DateTime.now(),
        );
      } catch (_) {}
    }

    final response = await _api.post(
      '/posts/$postId/comments',
      body: {
        'text': text,
        if (parentCommentId != null) 'parent_id': parentCommentId,
      },
    );
    if (response is Map<String, dynamic>) {
      return CommunityComment.fromJson(response);
    }
    return CommunityComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: postId,
      name: 'Stephanie',
      text: text,
      createdAt: DateTime.now(),
    );
  }

  Future<void> deletePost(String postId) async {
    final sb = SupabaseService.instance;
    if (sb.isInitialized && sb.client != null) {
      try {
        await sb.client!.from('posts').delete().eq('id', postId);
      } catch (_) {}
    }
    try {
      await _api.delete('/posts/$postId');
    } catch (_) {}
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
            name: 'Stephanie',
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
