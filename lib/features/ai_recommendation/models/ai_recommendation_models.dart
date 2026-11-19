class AiCafeRecommendation {
  final String? cafeId;
  final String name;
  final String? area;
  final int matchScore;
  final String? reason;
  final List<String> highlights;

  const AiCafeRecommendation({
    this.cafeId,
    required this.name,
    this.area,
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

    // Backend returns cafe_name (from join), name (from raw), or name from list
    final cafeName = json['cafe_name']?.toString() ??
        json['name']?.toString() ??
        'Recommended Cafe';

    return AiCafeRecommendation(
      cafeId: json['cafe_id']?.toString() ?? json['id']?.toString(),
      name: cafeName,
      area: json['area']?.toString(),
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
    if (json['result'] is Map && json['result']['recommendations'] is List) {
      recs = (json['result']['recommendations'] as List)
          .map((r) => AiCafeRecommendation.fromJson(r as Map<String, dynamic>))
          .toList();
    } else if (json['recommendations'] is List) {
      recs = (json['recommendations'] as List)
          .map((r) => AiCafeRecommendation.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return AiHistoryItem(
      id: json['id']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? 'General',
      budget: json['budget']?.toString() ?? 'Any',
      preferences: json['preferences']?.toString() ?? json['details']?.toString(),
      recommendations: recs,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
