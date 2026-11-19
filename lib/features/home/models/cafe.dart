class Cafe {
  final String id;
  final String name;
  final String address;
  final String area;
  final double? latitude;
  final double? longitude;
  final String? priceRange;
  final List<String> facilities;
  final double rating;
  final int reviewsCount;
  final List<String> photos;
  final String? openingHours;
  final bool isSaved;

  const Cafe({
    required this.id,
    required this.name,
    required this.address,
    this.area = 'Jaksel',
    this.latitude,
    this.longitude,
    this.priceRange,
    this.facilities = const [],
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.photos = const [],
    this.openingHours,
    this.isSaved = false,
  });

  factory Cafe.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    return Cafe(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Cafe',
      address: json['address']?.toString() ?? json['location']?.toString() ?? 'Jakarta',
      area: json['area']?.toString() ?? 'Jaksel',
      latitude: json['latitude'] != null ? parseDouble(json['latitude']) : null,
      longitude: json['longitude'] != null ? parseDouble(json['longitude']) : null,
      priceRange: json['price_range']?.toString(),
      facilities: parseStringList(json['facilities']),
      rating: parseDouble(json['rating'] ?? json['average_rating']),
      reviewsCount: parseInt(json['reviews_count']),
      photos: parseStringList(json['photos']),
      openingHours: json['opening_hours']?.toString(),
      isSaved: json['is_saved'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'area': area,
        'latitude': latitude,
        'longitude': longitude,
        'price_range': priceRange,
        'facilities': facilities,
        'rating': rating,
        'reviews_count': reviewsCount,
        'photos': photos,
        'opening_hours': openingHours,
        'is_saved': isSaved,
      };
}
