import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/supabase_service.dart';
import '../models/user_profile.dart';

class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  final ApiClient _api = ApiClient.instance;

  Future<UserProfile> getProfile() async {
    final sb = SupabaseService.instance;
    final currentUser = sb.currentUser;

    // 1. Direct fetch from Supabase database if authenticated
    if (sb.isInitialized && currentUser != null && sb.client != null) {
      try {
        final data = await sb.client!
            .from('users')
            .select('id,username,full_name,avatar_url,role,created_at,updated_at')
            .eq('id', currentUser.id)
            .maybeSingle();

        if (data != null) {
          final dbFullName = data['full_name']?.toString().trim();
          final metaFullName = (currentUser.userMetadata?['full_name'] ?? currentUser.userMetadata?['name'])?.toString().trim();
          final finalFullName = (dbFullName != null && dbFullName.isNotEmpty)
              ? dbFullName
              : ((metaFullName != null && metaFullName.isNotEmpty) ? metaFullName : 'Stephanie');

          final dbUsername = data['username']?.toString().trim();
          final metaUsername = currentUser.userMetadata?['username']?.toString().trim();
          final finalUsername = (dbUsername != null && dbUsername.isNotEmpty)
              ? dbUsername
              : ((metaUsername != null && metaUsername.isNotEmpty) ? metaUsername : 'stephanieee');

          return UserProfile(
            id: currentUser.id,
            email: currentUser.email ?? '',
            fullName: finalFullName,
            username: finalUsername,
            avatarUrl: data['avatar_url']?.toString(),
            location: 'Jakarta, Indonesia',
            createdAt: data['created_at'] != null ? DateTime.tryParse(data['created_at'].toString()) : null,
          );
        }
      } catch (_) {}
    }

    // 2. Fetch via Backend API
    try {
      final response = await _api.get('/users/me');
      if (response is Map<String, dynamic>) {
        return UserProfile.fromJson(response);
      }
    } catch (_) {}

    // 3. Fallback to Supabase auth metadata if currentUser is present
    if (currentUser != null) {
      final metaFullName = (currentUser.userMetadata?['full_name'] ?? currentUser.userMetadata?['name'])?.toString().trim() ?? 'Stephanie';
      final metaUsername = currentUser.userMetadata?['username']?.toString().trim() ?? 'stephanieee';
      return UserProfile(
        id: currentUser.id,
        email: currentUser.email ?? '',
        fullName: metaFullName.isNotEmpty ? metaFullName : 'Stephanie',
        username: metaUsername.isNotEmpty ? metaUsername : 'stephanieee',
        location: 'Jakarta, Indonesia',
      );
    }

    return _defaultProfile();
  }

  Future<UserProfile> updateProfile({
    required String fullName,
    required String username,
    String location = 'Jakarta, Indonesia',
    String? bio,
  }) async {
    final sb = SupabaseService.instance;
    final currentUser = sb.currentUser;

    // 1. Sync directly to Supabase users table and user metadata
    if (sb.isInitialized && currentUser != null && sb.client != null) {
      try {
        await sb.client!.from('users').update({
          'full_name': fullName,
          'username': username,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', currentUser.id);

        await sb.client!.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': fullName,
              'username': username,
            },
          ),
        );
      } catch (_) {}
    }

    // 2. Also notify Backend API
    try {
      final response = await _api.patch(
        '/users/me',
        body: {
          'full_name': fullName,
          'username': username,
          'location': 'Jakarta, Indonesia',
          if (bio != null) 'bio': bio,
        },
      );
      if (response is Map<String, dynamic>) {
        return UserProfile.fromJson(response);
      }
    } catch (_) {}

    return UserProfile(
      id: currentUser?.id ?? 'local-user',
      email: currentUser?.email ?? 'user@kopifinder.app',
      fullName: fullName,
      username: username,
      location: 'Jakarta, Indonesia',
      bio: bio,
    );
  }

  Future<UserStats> getStats() async {
    final sb = SupabaseService.instance;
    final currentUser = sb.currentUser;

    // 1. Count directly in Supabase for accuracy
    if (sb.isInitialized && currentUser != null && sb.client != null) {
      try {
        final client = sb.client!;
        final results = await Future.wait([
          client.from('saved_cafes').select('id').eq('user_id', currentUser.id),
          client.from('posts').select('id').eq('user_id', currentUser.id),
        ]);

        final savedCount = (results[0] as List).length;
        final postsCount = (results[1] as List).length;

        return UserStats(
          reviewsCount: 0,
          bookmarksCount: savedCount,
          postsCount: postsCount,
        );
      } catch (_) {}
    }

    // 2. Fetch from Backend API
    try {
      final response = await _api.get('/users/me/stats');
      if (response is Map<String, dynamic>) {
        return UserStats.fromJson(response);
      }
    } catch (_) {}

    return const UserStats(reviewsCount: 0, bookmarksCount: 0, postsCount: 0);
  }

  UserProfile _defaultProfile() {
    return const UserProfile(
      id: 'usr-1',
      email: 'stephanie.halim06@gmail.com',
      fullName: 'Stephanie',
      username: 'stephanieee',
      location: 'Jakarta, Indonesia',
      bio: 'Coffee enthusiast & casual barista | Exploring every corner of Jakarta ☕',
    );
  }
}
