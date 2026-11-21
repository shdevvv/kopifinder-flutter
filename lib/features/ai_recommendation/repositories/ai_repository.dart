import '../../../core/network/api_client.dart';
import '../../home/models/cafe.dart';
import '../../home/repositories/cafe_repository.dart';
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
        if (list.isNotEmpty) {
          return list
              .map((item) => AiCafeRecommendation.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      } else if (response is List && response.isNotEmpty) {
        return response
            .map((item) => AiCafeRecommendation.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return _generateDynamicRecommendations(purpose, budget, details);
    } catch (_) {
      // Graceful fallback to dynamic client-side AI recommendation scoring engine
      return _generateDynamicRecommendations(purpose, budget, details);
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

  /// Dynamic AI Recommendation & Match Score Engine based on Purpose, Budget, and Preferences
  List<AiCafeRecommendation> _generateDynamicRecommendations(
    String purpose,
    String budget,
    String? details,
  ) {
    // Fetch all active Jakarta cafes from repository
    final allCafes = CafeRepository.instance.getCafesSync();

    final pLower = purpose.toLowerCase().trim();
    final bLower = budget.toLowerCase().trim();
    final dLower = (details ?? '').toLowerCase().trim();

    final scoredCandidates = <Map<String, dynamic>>[];

    for (final cafe in allCafes) {
      double rawScore = 40.0; // Base baseline score

      // 1. Purpose Match Score (+22 max points)
      final purposeMatchFactor = _evalPurposeMatch(cafe, pLower);
      rawScore += purposeMatchFactor * 22.0;

      // 2. Budget Match Score (+20 max points, -10 points penalty if budget mismatch)
      final budgetScore = _evalBudgetMatch(cafe.priceRange, bLower);
      rawScore += budgetScore.toDouble();

      // 3. Preferences & Details Keywords (+3 points per keyword match)
      if (dLower.isNotEmpty) {
        final keywords = dLower.split(RegExp(r'\s+'));
        for (final kw in keywords) {
          if (kw.length >= 3) {
            if (cafe.facilities.any((f) => f.toLowerCase().contains(kw)) ||
                cafe.name.toLowerCase().contains(kw) ||
                cafe.address.toLowerCase().contains(kw)) {
              rawScore += 3.0;
            }
          }
        }
      }

      // 4. Rating Boost (+1 to +5 points)
      rawScore += ((cafe.rating - 4.0) * 5.0).clamp(0.0, 5.0);

      scoredCandidates.add({
        'cafe': cafe,
        'rawScore': rawScore,
        'budgetScore': budgetScore,
      });
    }

    // Sort by raw calculated score descending
    scoredCandidates.sort((a, b) => (b['rawScore'] as double).compareTo(a['rawScore'] as double));

    // Assign realistic, distinct match scores to top 4 candidates
    final results = <AiCafeRecommendation>[];
    for (int i = 0; i < scoredCandidates.length && i < 4; i++) {
      final cafe = scoredCandidates[i]['cafe'] as Cafe;
      final rawScore = scoredCandidates[i]['rawScore'] as double;
      final budgetScore = scoredCandidates[i]['budgetScore'] as int;

      int displayScore;
      if (i == 0) {
        displayScore = (rawScore >= 78) ? 98 : 94;
      } else if (i == 1) {
        displayScore = (rawScore >= 72) ? 93 : 89;
      } else if (i == 2) {
        displayScore = (rawScore >= 66) ? 87 : 83;
      } else {
        displayScore = (rawScore >= 60) ? 82 : 76;
      }

      final reasonText = _buildCustomReason(cafe, pLower, bLower, budgetScore);

      results.add(AiCafeRecommendation(
        cafeId: cafe.id,
        name: cafe.name,
        area: cafe.address.contains(',') ? cafe.address.split(',').last.trim() : cafe.area,
        matchScore: displayScore,
        reason: reasonText,
        highlights: cafe.facilities.take(4).toList(),
      ));
    }

    return results;
  }

  double _evalPurposeMatch(Cafe cafe, String purpose) {
    if (purpose.contains('work')) {
      if (cafe.facilities.any((f) => f.toLowerCase().contains('work'))) return 1.0;
      if (cafe.facilities.any((f) => f.toLowerCase().contains('wifi'))) return 0.7;
      return 0.3;
    }
    if (purpose.contains('study')) {
      if (cafe.facilities.any((f) => f.toLowerCase().contains('study'))) return 1.0;
      if (cafe.facilities.any((f) => f.toLowerCase().contains('work') || f.toLowerCase().contains('wifi'))) return 0.7;
      return 0.3;
    }
    if (purpose.contains('aesthetic')) {
      if (cafe.facilities.any((f) => f.toLowerCase().contains('aesthetic'))) return 1.0;
      if (cafe.facilities.any((f) => f.toLowerCase().contains('outdoor'))) return 0.6;
      return 0.3;
    }
    if (purpose.contains('pet')) {
      if (cafe.facilities.any((f) => f.toLowerCase().contains('pet'))) return 1.0;
      if (cafe.facilities.any((f) => f.toLowerCase().contains('outdoor'))) return 0.5;
      return 0.2;
    }
    return 0.5;
  }

  int _evalBudgetMatch(String? priceRange, String budget) {
    if (priceRange == null || priceRange.isEmpty) return 6;

    final lowerPrice = priceRange.toLowerCase();

    if (budget.contains('15k-30k') || budget.contains('15k')) {
      if (lowerPrice.contains('15.000') || lowerPrice.contains('20.000')) return 20;
      if (lowerPrice.contains('25.000') || lowerPrice.contains('30.000')) return 12;
      return -8; // Penalty for expensive budget mismatch
    }

    if (budget.contains('30k-60k') || budget.contains('30k')) {
      if (lowerPrice.contains('25.000') || lowerPrice.contains('30.000') || lowerPrice.contains('35.000') || lowerPrice.contains('50.000')) return 20;
      if (lowerPrice.contains('60.000') || lowerPrice.contains('65.000')) return 14;
      return 2;
    }

    if (budget.contains('60k-80k') || budget.contains('60k')) {
      if (lowerPrice.contains('60.000') || lowerPrice.contains('65.000') || lowerPrice.contains('70.000') || lowerPrice.contains('75.000') || lowerPrice.contains('80.000')) return 20;
      if (lowerPrice.contains('35.000') || lowerPrice.contains('50.000')) return 12;
      return 0;
    }

    if (budget.contains('more than 80k') || budget.contains('80k')) {
      if (lowerPrice.contains('75.000') || lowerPrice.contains('80.000') || lowerPrice.contains('85.000')) return 20;
      if (lowerPrice.contains('60.000') || lowerPrice.contains('65.000')) return 12;
      return -5;
    }

    return 8;
  }

  String _buildCustomReason(Cafe cafe, String purpose, String budget, int budgetScore) {
    final facText = cafe.facilities.take(3).join(', ');
    final price = cafe.priceRange ?? 'Harga terjangkau';

    if (budgetScore >= 16) {
      return 'Kategori harga $price sangat pas dengan budget pilihan Anda! Menyediakan $facText.';
    } else if (purpose.isNotEmpty) {
      return 'Pilihan tepat untuk $purpose dengan kisaran $price. Dilengkapi $facText.';
    }
    return 'Rekomendasi kafe populer dengan rating ${cafe.rating} dan fasilitas $facText.';
  }
}
