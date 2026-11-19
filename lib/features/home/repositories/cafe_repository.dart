import '../../../core/network/api_client.dart';
import '../models/cafe.dart';

class CafeRepository {
  CafeRepository._();
  static final CafeRepository instance = CafeRepository._();

  final ApiClient _api = ApiClient.instance;

  Future<List<Cafe>> getCafes({
    String? search,
    String? tag,
    String? area,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      // Backend uses 'q' for search query
      if (search != null && search.isNotEmpty) query['q'] = search;
      if (tag != null && tag.isNotEmpty) query['tag'] = tag;
      if (area != null && area.isNotEmpty) query['area'] = area;

      final response = await _api.get('/cafes', queryParameters: query);

      if (response is List) {
        return response.map((item) => Cafe.fromJson(item as Map<String, dynamic>)).toList();
      }
      if (response is Map && response['data'] is List) {
        return (response['data'] as List).map((item) => Cafe.fromJson(item as Map<String, dynamic>)).toList();
      }
      return _filterFallback(search, tag, area);
    } catch (_) {
      return _filterFallback(search, tag, area);
    }
  }

  Future<Cafe> getCafeById(String id) async {
    try {
      final response = await _api.get('/cafes/$id');
      if (response is Map<String, dynamic>) {
        return Cafe.fromJson(response);
      }
    } catch (_) {}
    return _defaultCafes().firstWhere(
      (c) => c.id == id,
      orElse: () => _defaultCafes().first,
    );
  }

  List<Cafe> _filterFallback(String? search, String? tag, String? area) {
    var list = _defaultCafes();
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((c) => c.name.toLowerCase().contains(q) || c.address.toLowerCase().contains(q)).toList();
    }
    if (tag != null && tag.isNotEmpty) {
      final t = tag.toLowerCase();
      list = list.where((c) => c.facilities.any((f) => f.toLowerCase().contains(t))).toList();
    }
    if (area != null && area.isNotEmpty) {
      final a = area.toLowerCase();
      list = list.where((c) => c.address.toLowerCase().contains(a)).toList();
    }
    return list;
  }

  List<Cafe> _defaultCafes() {
    return const [
      Cafe(
        id: 'cafe-1',
        name: 'Anomali Coffee',
        address: 'Jl. Senopati No. 41, Kebayoran Baru, Jakarta Selatan',
        latitude: -6.2305,
        longitude: 106.8115,
        priceRange: 'Rp30.000 - Rp65.000',
        facilities: ['Free Wi-Fi', 'Air Conditioning', 'Indoor Seating', 'Work', 'Study'],
        rating: 4.8,
        reviewsCount: 142,
        openingHours: '08:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600&q=80',
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-2',
        name: 'Kopi Tuku',
        address: 'Jl. Cipete Raya No. 7, Cipete, Jakarta Selatan',
        latitude: -6.2622,
        longitude: 106.7901,
        priceRange: 'Rp20.000 - Rp45.000',
        facilities: ['Free Wi-Fi', 'Outdoor Area', 'Pet Friendly', 'Aesthetic'],
        rating: 4.6,
        reviewsCount: 198,
        openingHours: '07:00 - 21:00',
        photos: [
          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=600&q=80',
          'https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-3',
        name: 'Common Grounds',
        address: 'Jl. Wijaya I No. 42, Kebayoran Baru, Jakarta Selatan',
        latitude: -6.2390,
        longitude: 106.8152,
        priceRange: 'Rp35.000 - Rp80.000',
        facilities: ['Free Wi-Fi', 'Parking', 'Air Conditioning', 'Work', 'Study'],
        rating: 4.7,
        reviewsCount: 86,
        openingHours: '08:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1445116572660-236099ec97a0?w=600&q=80',
          'https://images.unsplash.com/photo-1517705008128-361805f42e86?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-4',
        name: 'Tanamera Coffee',
        address: 'Jl. Ampera Raya No. 5, Cilandak, Jakarta Selatan',
        latitude: -6.2756,
        longitude: 106.8190,
        priceRange: 'Rp28.000 - Rp55.000',
        facilities: ['Free Wi-Fi', 'Air Conditioning', 'Study', 'Work'],
        rating: 4.5,
        reviewsCount: 210,
        openingHours: '07:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600&q=80',
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-5',
        name: 'Nook',
        address: 'Jl. Senayan, Kebayoran Baru, Jakarta Selatan',
        latitude: -6.2290,
        longitude: 106.8020,
        priceRange: 'Rp25.000 - Rp50.000',
        facilities: ['Free Wi-Fi', 'Aesthetic', 'Pet Friendly', 'Outdoor Area'],
        rating: 4.4,
        reviewsCount: 95,
        openingHours: '09:00 - 21:00',
        photos: [
          'https://images.unsplash.com/photo-1453614512568-c4024d13c247?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-6',
        name: 'Copper & Zinc',
        address: 'Jl. Palmerah Utara No. 1, Jakarta Barat',
        latitude: -6.2100,
        longitude: 106.7950,
        priceRange: 'Rp30.000 - Rp60.000',
        facilities: ['Free Wi-Fi', 'Air Conditioning', 'Work', 'Study'],
        rating: 4.5,
        reviewsCount: 77,
        openingHours: '08:00 - 21:00',
        photos: [
          'https://images.unsplash.com/photo-1534040385115-33dcb3acba5b?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-7',
        name: 'Kopi Janji Jiwa',
        address: 'Jl. Mangga Besar, Taman Sari, Jakarta Barat',
        latitude: -6.1480,
        longitude: 106.8260,
        priceRange: 'Rp15.000 - Rp30.000',
        facilities: ['Takeaway', 'Air Conditioning'],
        rating: 4.3,
        reviewsCount: 320,
        openingHours: '07:00 - 23:00',
        photos: [
          'https://images.unsplash.com/photo-1511537190424-bbbab87ac5eb?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-8',
        name: 'Saturdays Coffee',
        address: 'Jl. Pangeran Jayakarta, Pademangan, Jakarta Utara',
        latitude: -6.1350,
        longitude: 106.8350,
        priceRange: 'Rp25.000 - Rp55.000',
        facilities: ['Free Wi-Fi', 'Aesthetic', 'Outdoor Area', 'Pet Friendly'],
        rating: 4.6,
        reviewsCount: 115,
        openingHours: '08:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1522992319-0365e5f11656?w=600&q=80',
        ],
      ),
    ];
  }
}
