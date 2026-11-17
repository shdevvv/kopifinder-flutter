class AiCafeRecommendation {
  final String? cafeId;
  final String name;
  final int matchScore;
  final String? reason;
  final List<String> highlights;

  const AiCafeRecommendation({
    this.cafeId,
    required this.name,
    required this.matchScore,
    this.reason,
    this.highlights = const [],
  });

  factory AiCafeRecommendation.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, [int fallback = 90]) {
      if (val == null) return fallback;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    List<String> parseList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    return AiCafeRecommendation(
      cafeId: json['cafe_id']?.toString() ?? json['id']?.toString(),
      name: json['name']?.toString() ?? 'Recommended Cafe',
      matchScore: parseInt(json['match_score'] ?? json['match'], 90),
      reason: json['reason']?.toString(),
      highlights: parseList(json['highlights']),
    );
  }
}

class AiHistoryItem {
  final String id;
  final String purpose;
  final String budget;
  final String? preferences;
  final List<AiCafeRecommendation> recommendations;
  final DateTime createdAt;

  const AiHistoryItem({
    required this.id,
    required this.purpose,
    required this.budget,
    this.preferences,
    required this.recommendations,
    required this.createdAt,
  });

  factory AiHistoryItem.fromJson(Map<String, dynamic> json) {
    List<AiCafeRecommendation> recs = [];
    if (json['recommendations'] is List) {
      recs = (json['recommendations'] as List)
          .map((r) => AiCafeRecommendation.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return AiHistoryItem(
      id: json['id']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? 'General',
      budget: json['budget']?.toString() ?? 'Any',
      preferences: json['preferences']?.toString(),
      recommendations: recs,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
