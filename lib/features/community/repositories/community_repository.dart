import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
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
            .select('id,user_id,cafe_id,caption,photo_url,likes_count,comments_count,created_at,users(id,full_name,username,avatar_url)')
            .order('created_at', ascending: false)
            .limit(limit);

        if (data.isNotEmpty) {
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
            final userObj = p['users'] as Map<String, dynamic>?;
            final currentMeta = sb.currentUser?.userMetadata;
            final myName = (currentMeta?['full_name'] ?? currentMeta?['name'] ?? currentMeta?['username'])?.toString();
            final author = userObj?['full_name']?.toString() ??
                userObj?['username']?.toString() ??
                (uid == sb.currentUser?.id ? (myName ?? '') : '');

            return CommunityPost(
              id: p['id']?.toString(),
              userId: uid,
              name: author.isNotEmpty ? author : (myName ?? 'Stephanie Halim'),
              avatarUrl: userObj?['avatar_url']?.toString(),
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
    File? imageFile,
  }) async {
    final sb = SupabaseService.instance;
    final currentUser = sb.currentUser;

    // Upload image to Supabase Storage if provided
    String? resolvedPhotoUrl = photoUrl;
    if (imageFile != null && resolvedPhotoUrl == null) {
      resolvedPhotoUrl = await uploadPostPhoto(imageFile);
    }

    // 1. Direct Supabase insertion if authenticated
    if (sb.isInitialized && currentUser != null && sb.client != null) {
      try {
        final inserted = await sb.client!.from('posts').insert({
          'user_id': currentUser.id,
          'caption': caption,
          if (cafeId != null && cafeId.isNotEmpty) 'cafe_id': cafeId,
          if (resolvedPhotoUrl != null && resolvedPhotoUrl.isNotEmpty) 'photo_url': resolvedPhotoUrl,
        }).select('id,user_id,caption,photo_url,likes_count,comments_count,created_at').single();

        String authorName = currentUser.userMetadata?['full_name']?.toString() ??
            currentUser.userMetadata?['name']?.toString() ??
            currentUser.userMetadata?['username']?.toString() ??
            'User';
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
          imageUrl: resolvedPhotoUrl,
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
          if (resolvedPhotoUrl != null && resolvedPhotoUrl.isNotEmpty) 'photo_path': resolvedPhotoUrl,
        },
      );
      if (response is Map<String, dynamic>) {
        return CommunityPost.fromJson(response);
      }
    } catch (_) {}

    final meta = currentUser?.userMetadata;
    return CommunityPost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: (meta?['full_name'] ?? meta?['name'] ?? meta?['username'] ?? 'User').toString(),
      location: 'Jakarta',
      caption: caption,
      imageUrl: resolvedPhotoUrl,
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
          'content': text,
          if (parentCommentId != null) 'parent_id': parentCommentId,
        }).select('id,post_id,parent_id,content,created_at').single();

        String authorName = currentUser.userMetadata?['full_name']?.toString() ??
            currentUser.userMetadata?['name']?.toString() ??
            currentUser.userMetadata?['username']?.toString() ??
            'User';
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
    final meta = currentUser?.userMetadata;
    return CommunityComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: postId,
      name: (meta?['full_name'] ?? meta?['name'] ?? meta?['username'] ?? 'User').toString(),
      text: text,
      createdAt: DateTime.now(),
    );
  }

  Future<void> deletePost(String postId, {String? photoUrl}) async {
    final sb = SupabaseService.instance;
    if (sb.isInitialized && sb.client != null) {
      try {
        await sb.client!.from('posts').delete().eq('id', postId);
      } catch (_) {}
      // Delete photo from storage if exists
      if (photoUrl != null && photoUrl.isNotEmpty) {
        try {
          final uri = Uri.tryParse(photoUrl);
          if (uri != null) {
            final segments = uri.pathSegments;
            final idx = segments.indexOf('post-photos');
            if (idx != -1 && idx < segments.length - 1) {
              final filePath = segments.sublist(idx + 1).join('/');
              await sb.client!.storage.from('post-photos').remove([filePath]);
            }
          }
        } catch (_) {}
      }
    }
    try {
      await _api.delete('/posts/$postId');
    } catch (_) {}
  }

  Future<void> updatePost(String postId, String newCaption) async {
    final sb = SupabaseService.instance;
    if (sb.isInitialized && sb.client != null) {
      try {
        await sb.client!.from('posts').update({'caption': newCaption}).eq('id', postId);
        return;
      } catch (_) {}
    }
    try {
      await _api.patch('/posts/$postId', body: {'caption': newCaption});
    } catch (_) {}
  }

  /// Upload a local image file to Supabase Storage post-photos bucket.
  /// Returns the public URL of the uploaded image, or null on failure.
  Future<String?> uploadPostPhoto(File imageFile) async {
    final sb = SupabaseService.instance;
    final currentUser = sb.currentUser;
    if (!sb.isInitialized || currentUser == null || sb.client == null) return null;
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${currentUser.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await sb.client!.storage.from('post-photos').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );
      final url = sb.client!.storage.from('post-photos').getPublicUrl(fileName);
      return url;
    } catch (_) {
      return null;
    }
  }

  List<CommunityPost> _defaultPosts() {
    return [];
  }
}
