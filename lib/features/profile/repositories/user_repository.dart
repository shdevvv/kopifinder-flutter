import '../../../core/network/api_client.dart';
import '../models/user_profile.dart';

class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  final ApiClient _api = ApiClient.instance;

  Future<UserProfile> getProfile() async {
    try {
      final response = await _api.get('/users/me');
      if (response is Map<String, dynamic>) {
        return UserProfile.fromJson(response);
      }
      return _defaultProfile();
    } catch (_) {
      return _defaultProfile();
    }
  }

  Future<UserProfile> updateProfile({
    required String fullName,
    required String username,
    required String location,
    String? bio,
  }) async {
    final response = await _api.patch(
      '/users/me',
      body: {
        'full_name': fullName,
        'username': username,
        'location': location,
        if (bio != null) 'bio': bio,
      },
    );
    if (response is Map<String, dynamic>) {
      return UserProfile.fromJson(response);
    }
    return UserProfile(
      id: 'local-user',
      email: 'user@kopifinder.app',
      fullName: fullName,
      username: username,
      location: location,
      bio: bio,
    );
  }

  Future<UserStats> getStats() async {
    try {
      final response = await _api.get('/users/me/stats');
      if (response is Map<String, dynamic>) {
        return UserStats.fromJson(response);
      }
      return const UserStats(reviewsCount: 12, bookmarksCount: 8, postsCount: 5);
    } catch (_) {
      return const UserStats(reviewsCount: 12, bookmarksCount: 8, postsCount: 5);
    }
  }

  UserProfile _defaultProfile() {
    return const UserProfile(
      id: 'usr-1',
      email: 'coffee.lover@example.com',
      fullName: 'Coffee Lover',
      username: 'coffeelover',
      location: 'Jakarta, Indonesia',
      bio: 'Coffee enthusiast & casual barista | Exploring every corner of Jakarta ☕',
    );
  }
}
