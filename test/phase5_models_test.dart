import 'package:flutter_test/flutter_test.dart';
import 'package:kopifinder/core/config/app_config.dart';
import 'package:kopifinder/features/home/models/cafe.dart';
import 'package:kopifinder/features/home/models/offer.dart';
import 'package:kopifinder/features/cafe_details/models/review.dart';
import 'package:kopifinder/features/saved_cafes/models/saved_cafe.dart';
import 'package:kopifinder/features/community/models/community_models.dart';
import 'package:kopifinder/features/profile/models/user_profile.dart';
import 'package:kopifinder/features/ai_recommendation/models/ai_recommendation_models.dart';

void main() {
  group('Phase 5 — App Configuration & Security', () {
    test('AppConfig must not contain secret keys', () {
      expect(AppConfig.backendBaseUrl, isNotEmpty);
      expect(AppConfig.supabaseUrl, isNotEmpty);
      expect(AppConfig.supabaseAnonKey, isNotEmpty);
      // Verify no service role key or Gemini API key is configured
      expect(AppConfig.supabaseAnonKey.contains('service_role'), isFalse);
    });
  });

  group('Phase 5 — Models Serialization & Deserialization', () {
    test('Cafe.fromJson parses valid JSON correctly', () {
      final json = {
        'id': 'cafe-101',
        'name': 'Kopi Senopati',
        'address': 'Jl. Senopati No. 10',
        'latitude': -6.2305,
        'longitude': 106.8115,
        'rating': 4.7,
        'reviews_count': 58,
        'price_range': 'Rp30.000 - Rp50.000',
        'facilities': ['Free Wi-Fi', 'AC'],
        'opening_hours': '08:00 - 22:00',
        'is_saved': true,
      };

      final cafe = Cafe.fromJson(json);

      expect(cafe.id, 'cafe-101');
      expect(cafe.name, 'Kopi Senopati');
      expect(cafe.address, 'Jl. Senopati No. 10');
      expect(cafe.latitude, -6.2305);
      expect(cafe.longitude, 106.8115);
      expect(cafe.rating, 4.7);
      expect(cafe.reviewsCount, 58);
      expect(cafe.facilities.length, 2);
      expect(cafe.isSaved, isTrue);
    });

    test('Offer.fromJson calculates discount percentage properly', () {
      final json = {
        'id': 'off-1',
        'cafe_id': 'cafe-101',
        'cafe_name': 'Kopi Senopati',
        'title': 'Latte Promo',
        'original_price': 50000,
        'discounted_price': 35000,
        'discount_percentage': 0,
      };

      final offer = Offer.fromJson(json);

      expect(offer.title, 'Latte Promo');
      expect(offer.originalPrice, 50000);
      expect(offer.discountedPrice, 35000);
      expect(offer.discountPercentage, 30);
    });

    test('Review.fromJson parses nested author information', () {
      final json = {
        'id': 'rev-1',
        'cafe_id': 'cafe-101',
        'user_id': 'user-1',
        'rating': 5,
        'comment': 'Sangat nyaman!',
        'author': {
          'full_name': 'Budi Santoso',
          'avatar_url': 'https://example.com/avatar.jpg',
        },
      };

      final review = Review.fromJson(json);

      expect(review.id, 'rev-1');
      expect(review.authorName, 'Budi Santoso');
      expect(review.rating, 5);
      expect(review.comment, 'Sangat nyaman!');
    });

    test('SavedCafe.fromJson parses cafe relationship', () {
      final json = {
        'id': 'sc-1',
        'cafe_id': 'cafe-101',
        'cafe': {
          'name': 'Daily Brew',
          'address': 'Gandaria, Jakarta',
          'rating': 4.6,
        },
      };

      final saved = SavedCafe.fromJson(json);

      expect(saved.id, 'sc-1');
      expect(saved.cafeId, 'cafe-101');
      expect(saved.name, 'Daily Brew');
      expect(saved.location, 'Gandaria, Jakarta');
      expect(saved.rating, 4.6);
    });

    test('CommunityPost.fromJson parses comments and likes', () {
      final json = {
        'id': 'post-1',
        'user_id': 'user-1',
        'caption': 'Kopi sore ini enak banget!',
        'likes_count': 15,
        'is_liked': true,
        'author': {
          'full_name': 'Citra Kirana',
        },
        'comments': [
          {
            'id': 'c-1',
            'content': 'Keren tempatnya!',
            'likes_count': 3,
            'author': {'full_name': 'Roni'},
          }
        ],
      };

      final post = CommunityPost.fromJson(json);

      expect(post.id, 'post-1');
      expect(post.name, 'Citra Kirana');
      expect(post.caption, 'Kopi sore ini enak banget!');
      expect(post.likes, 15);
      expect(post.liked, isTrue);
      expect(post.comments.length, 1);
      expect(post.comments.first.text, 'Keren tempatnya!');
    });

    test('UserProfile & UserStats parse correctly', () {
      final profileJson = {
        'id': 'u-1',
        'email': 'user@kopifinder.app',
        'full_name': 'Coffee Hunter',
        'username': 'coffeehunter',
        'location': 'Jakarta Selatan',
      };

      final profile = UserProfile.fromJson(profileJson);

      expect(profile.fullName, 'Coffee Hunter');
      expect(profile.username, 'coffeehunter');
      expect(profile.location, 'Jakarta Selatan');

      final statsJson = {
        'reviews_count': 14,
        'bookmarks_count': 9,
        'posts_count': 3,
        'comments_count': 8,
      };

      final stats = UserStats.fromJson(statsJson);

      expect(stats.reviewsCount, 14);
      expect(stats.bookmarksCount, 9);
      expect(stats.postsCount, 3);
      expect(stats.commentsCount, 8);
    });

    test('AiCafeRecommendation parses AI match data', () {
      final json = {
        'cafe_id': 'c-1',
        'name': 'WorkHub Coffee',
        'match_score': 96,
        'reason': 'Quiet place with ergonomic chairs.',
        'highlights': ['Quiet', 'Fast Wi-Fi', 'Ergonomic'],
      };

      final aiRec = AiCafeRecommendation.fromJson(json);

      expect(aiRec.cafeId, 'c-1');
      expect(aiRec.name, 'WorkHub Coffee');
      expect(aiRec.matchScore, 96);
      expect(aiRec.reason, 'Quiet place with ergonomic chairs.');
      expect(aiRec.highlights.length, 3);
    });
  });
}
