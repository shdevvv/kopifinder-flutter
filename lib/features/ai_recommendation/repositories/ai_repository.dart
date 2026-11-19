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
      // Map UI labels to backend-accepted enum values
      final purposeMap = {
        'work': 'Work',
        'study': 'Study',
        'aesthetic': 'Aesthetic',
        'pet friendly': 'Pet Friendly',
      };
      final budgetMap = {
        '15k-30k': '15k-30k',
        '30k-60k': '30k-60k',
        '60k-80k': '60k-80k',
        'more than 80k': '>80k',
      };

      final purposeKey = purpose.toLowerCase().trim();
      final budgetKey = budget.toLowerCase().trim();

      final mappedPurpose = purposeMap[purposeKey] ?? 'Work';
      final mappedBudget = budgetMap[budgetKey] ?? '30k-60k';

      final response = await _api.post(
        '/ai/recommend',
        body: {
          'purpose': mappedPurpose,
          'budget': mappedBudget,
          if (details != null && details.isNotEmpty) 'preferences': details,
        },
      );

      if (response is Map<String, dynamic> && response['recommendations'] is List) {
        final list = response['recommendations'] as List;
        if (list.isEmpty) return [];
        return list
            .map((item) => AiCafeRecommendation.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is List) {
        return response
            .map((item) => AiCafeRecommendation.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
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
}
