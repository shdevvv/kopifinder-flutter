class Offer {
  final String id;
  final String cafeId;
  final String cafeName;
  final String title;
  final String? description;
  final int originalPrice;
  final int discountedPrice;
  final int discountPercentage;
  final String? validUntil;
  final String? photoUrl;

  const Offer({
    required this.id,
    required this.cafeId,
    required this.cafeName,
    required this.title,
    this.description,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercentage,
    this.validUntil,
    this.photoUrl,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, [int fallback = 0]) {
      if (val == null) return fallback;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    final orig = parseInt(json['original_price']);
    final disc = parseInt(json['discounted_price']);
    int pct = parseInt(json['discount_percentage']);
    if (pct == 0 && orig > 0 && disc < orig) {
      pct = (((orig - disc) / orig) * 100).round();
    }

    return Offer(
      id: json['id']?.toString() ?? '',
      cafeId: json['cafe_id']?.toString() ?? '',
      cafeName: json['cafe_name']?.toString() ?? (json['cafes'] is Map ? json['cafes']['name']?.toString() ?? 'Cafe' : 'Cafe'),
      title: json['title']?.toString() ?? json['product_name']?.toString() ?? 'Special Offer',
      description: json['description']?.toString(),
      originalPrice: orig,
      discountedPrice: disc,
      discountPercentage: pct,
      validUntil: json['valid_until']?.toString(),
      photoUrl: json['photo_url']?.toString(),
    );
  }
}
