import '../../../core/network/api_client.dart';
import '../models/ai_recommendation_models.dart';

class AiRepository {
  AiRepository._();
  static final AiRepository instance = AiRepository._();

  final ApiClient _api = ApiClient.instance;

  Future<List<AiCafeRecommendation>> getRecommendations({
    required String purpose,
    required String budget,
    String? details,
  }) async {
    try {
      final response = await _api.post(
        '/ai/recommend',
        body: {
          'purpose': purpose.toLowerCase(),
          'budget': budget.toLowerCase(),
          if (details != null && details.isNotEmpty) 'preferences': details,
        },
      );

      if (response is Map<String, dynamic> && response['recommendations'] is List) {
        return (response['recommendations'] as List)
            .map((item) => AiCafeRecommendation.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is List) {
        return response
            .map((item) => AiCafeRecommendation.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return _defaultRecommendations();
    } catch (_) {
      return _defaultRecommendations();
    }
  }

  Future<List<AiHistoryItem>> getHistory() async {
    try {
      final response = await _api.get('/ai/history');
      if (response is List) {
        return response
            .map((item) => AiHistoryItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  List<AiCafeRecommendation> _defaultRecommendations() {
    return const [
      AiCafeRecommendation(
        cafeId: 'cafe-1',
        name: 'First Coffee',
        matchScore: 98,
        reason: 'Cocok sekali untuk WFC dan meeting santai. Fasilitas Wi-Fi cepat dan colokan melimpah.',
        highlights: ['Fast Wi-Fi', 'Power Outlets', 'Quiet Ambience'],
      ),
      AiCafeRecommendation(
        cafeId: 'cafe-2',
        name: 'Daily Brew',
        matchScore: 94,
        reason: 'Pilihan hemat dengan suasana aesthetic outdoor yang ramah hewan peliharaan.',
        highlights: ['Budget Friendly', 'Aesthetic', 'Pet Friendly'],
      ),
      AiCafeRecommendation(
        cafeId: 'cafe-3',
        name: 'The Coffee Room',
        matchScore: 89,
        reason: 'Ruang kerja premium dengan kursi ergonomis dan parkiran luas.',
        highlights: ['Spacious Parking', 'Indoor Seating', 'Work-friendly'],
      ),
    ];
  }
}
