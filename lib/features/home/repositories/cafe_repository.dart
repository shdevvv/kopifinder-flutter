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
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (tag != null && tag.isNotEmpty) query['tag'] = tag;
      if (area != null && area.isNotEmpty) query['area'] = area;

      final response = await _api.get('/cafes', queryParameters: query);

      if (response is List) {
        return response.map((item) => Cafe.fromJson(item as Map<String, dynamic>)).toList();
      }
      return _defaultCafes();
    } catch (_) {
      // Graceful fallback for offline / development
      return _filterFallback(search, tag);
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

  List<Cafe> _filterFallback(String? search, String? tag) {
    var list = _defaultCafes();
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((c) => c.name.toLowerCase().contains(q) || c.address.toLowerCase().contains(q)).toList();
    }
    if (tag != null && tag.isNotEmpty) {
      list = list.where((c) => c.facilities.any((f) => f.toLowerCase().contains(tag.toLowerCase()))).toList();
    }
    return list;
  }

  List<Cafe> _defaultCafes() {
    return const [
      Cafe(
        id: 'cafe-1',
        name: 'First Coffee',
        address: 'Jl. Senopati No. 41, Jakarta Selatan',
        latitude: -6.2305,
        longitude: 106.8115,
        priceRange: 'Rp30.000 - Rp65.000',
        facilities: ['Free Wi-Fi', 'Air Conditioning', 'Indoor Seating', 'Work', 'Study'],
        rating: 4.8,
        reviewsCount: 142,
        openingHours: '08:00 - 22:00',
      ),
      Cafe(
        id: 'cafe-2',
        name: 'Daily Brew',
        address: 'Jl. Gandaria I No. 18, Jakarta Selatan',
        latitude: -6.2422,
        longitude: 106.7901,
        priceRange: 'Rp25.000 - Rp50.000',
        facilities: ['Free Wi-Fi', 'Outdoor Area', 'Pet Friendly', 'Aesthetic'],
        rating: 4.6,
        reviewsCount: 98,
        openingHours: '07:30 - 21:00',
      ),
      Cafe(
        id: 'cafe-3',
        name: 'The Coffee Room',
        address: 'Jl. Cikajang No. 12, Kebayoran Baru, Jakarta Selatan',
        latitude: -6.2390,
        longitude: 106.8152,
        priceRange: 'Rp35.000 - Rp80.000',
        facilities: ['Free Wi-Fi', 'Parking', 'Air Conditioning', 'Work'],
        rating: 4.7,
        reviewsCount: 86,
        openingHours: '09:00 - 23:00',
      ),
      Cafe(
        id: 'cafe-4',
        name: 'Kopi Kenangan Senopati',
        address: 'Jl. Suryo No. 25, Senopati, Jakarta Selatan',
        latitude: -6.2356,
        longitude: 106.8190,
        priceRange: 'Rp18.000 - Rp40.000',
        facilities: ['Takeaway', 'Air Conditioning', 'Study'],
        rating: 4.5,
        reviewsCount: 210,
        openingHours: '07:00 - 22:00',
      ),
    ];
  }
}
