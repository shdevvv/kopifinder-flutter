import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/supabase_service.dart';
import '../models/user_profile.dart';

class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  final SupabaseService _supabase = SupabaseService.instance;
  final ApiClient _api = ApiClient.instance;

  Future<UserProfile> getProfile() async {
    final currentUser = _supabase.currentUser;

    // 1. Fetch from Supabase direct client if user is logged in
    if (_supabase.isInitialized && currentUser != null) {
      final metaFullName = (currentUser.userMetadata?['full_name'] ?? currentUser.userMetadata?['name'])?.toString().trim();
      final metaUsername = currentUser.userMetadata?['username']?.toString().trim();
      final fallbackName = (metaFullName != null && metaFullName.isNotEmpty)
          ? metaFullName
          : (currentUser.email?.split('@').first ?? 'User');
      final fallbackUser = (metaUsername != null && metaUsername.isNotEmpty)
          ? metaUsername
          : (currentUser.email?.split('@').first ?? 'user');

      try {
        final client = Supabase.instance.client;
        final data = await client
            .from('users')
            .select('id,username,full_name,avatar_url,role,created_at,updated_at')
            .eq('id', currentUser.id)
            .maybeSingle();

        if (data != null) {
          final dbFullName = data['full_name']?.toString().trim();
          final finalFullName = (dbFullName != null && dbFullName.isNotEmpty) ? dbFullName : fallbackName;

          final dbUsername = data['username']?.toString().trim();
          final finalUsername = (dbUsername != null && dbUsername.isNotEmpty) ? dbUsername : fallbackUser;

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
      final metaFullName = (currentUser.userMetadata?['full_name'] ?? currentUser.userMetadata?['name'])?.toString().trim();
      final metaUsername = currentUser.userMetadata?['username']?.toString().trim();
      final fallbackName = (metaFullName != null && metaFullName.isNotEmpty)
          ? metaFullName
          : (currentUser.email?.split('@').first ?? 'User');
      final fallbackUser = (metaUsername != null && metaUsername.isNotEmpty)
          ? metaUsername
          : (currentUser.email?.split('@').first ?? 'user');

      return UserProfile(
        id: currentUser.id,
        email: currentUser.email ?? '',
        fullName: fallbackName,
        username: fallbackUser,
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
    final currentUser = _supabase.currentUser;

    // 1. Direct Supabase update
    if (_supabase.isInitialized && currentUser != null) {
      try {
        final client = Supabase.instance.client;
        final res = await client
            .from('users')
            .update({
              'full_name': fullName.trim(),
              'username': username.trim().toLowerCase(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', currentUser.id)
            .select('id,username,full_name,avatar_url,role,updated_at')
            .single();

        // Sinkronkan juga metadata auth
        try {
          await client.auth.updateUser(
            UserAttributes(
              data: {
                'full_name': fullName.trim(),
                'name': fullName.trim(),
                'username': username.trim().toLowerCase(),
              },
            ),
          );
        } catch (_) {}

        return UserProfile(
          id: currentUser.id,
          email: currentUser.email ?? '',
          fullName: res['full_name']?.toString() ?? fullName,
          username: res['username']?.toString() ?? username,
          avatarUrl: res['avatar_url']?.toString(),
          location: 'Jakarta, Indonesia',
          createdAt: DateTime.now(),
        );
      } catch (_) {}
    }

    // 2. Backend API fallback
    try {
      final response = await _api.patch(
        '/users/me',
        body: {
          'full_name': fullName.trim(),
          'name': fullName.trim(),
          'username': username.trim().toLowerCase(),
          'location': 'Jakarta, Indonesia',
          if (bio != null) 'bio': bio,
        },
      );
      if (response is Map<String, dynamic>) {
        return UserProfile.fromJson(response);
      }
    } catch (_) {}

    return UserProfile(
      id: currentUser?.id ?? 'usr-1',
      email: currentUser?.email ?? '',
      fullName: fullName,
      username: username,
      location: 'Jakarta, Indonesia',
    );
  }

  Future<UserStats> getStats() async {
    final currentUser = _supabase.currentUser;

    // 1. Fetch real counts directly from Supabase tables
    if (_supabase.isInitialized && currentUser != null) {
      try {
        final client = Supabase.instance.client;
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
      id: 'guest',
      email: '',
      fullName: 'Tamu KopiFinder',
      username: 'guest_user',
      location: 'Jakarta, Indonesia',
      bio: 'Pencinta kopi Jakarta ☕',
    );
  }
}
