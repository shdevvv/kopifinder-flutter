import '../../../core/network/api_client.dart';
import '../models/review.dart';

class ReviewRepository {
  ReviewRepository._();
  static final ReviewRepository instance = ReviewRepository._();

  final ApiClient _api = ApiClient.instance;

  Future<List<Review>> getCafeReviews(String cafeId) async {
    try {
      final response = await _api.get('/cafes/$cafeId/reviews');
      if (response is List) {
        return response.map((item) => Review.fromJson(item as Map<String, dynamic>)).toList();
      }
      return _defaultReviews(cafeId);
    } catch (_) {
      return _defaultReviews(cafeId);
    }
  }

  Future<Review> addReview({
    required String cafeId,
    required int rating,
    required String comment,
    List<String> photos = const [],
  }) async {
    final response = await _api.post(
      '/cafes/$cafeId/reviews',
      body: {
        'rating': rating,
        'comment': comment,
        'photos': photos,
      },
    );
    if (response is Map<String, dynamic>) {
      return Review.fromJson(response);
    }
    return Review(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cafeId: cafeId,
      userId: 'current-user',
      authorName: 'You',
      rating: rating,
      comment: comment,
      photos: photos,
      createdAt: DateTime.now(),
    );
  }

  List<Review> _defaultReviews(String cafeId) {
    return [
      Review(
        id: 'rev-1',
        cafeId: cafeId,
        userId: 'u1',
        authorName: 'Rina S.',
        rating: 5,
        comment: 'Tempatnya sangat nyaman untuk WFC! Wi-Fi kencang dan banyak colokan listrik.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Review(
        id: 'rev-2',
        cafeId: cafeId,
        userId: 'u2',
        authorName: 'Budi Pratama',
        rating: 4,
        comment: 'Kopi susunya pas, tidak terlalu manis. Tempatnya estetik dan barista ramah.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }
}
