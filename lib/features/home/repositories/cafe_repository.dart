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
      if (search != null && search.isNotEmpty) query['q'] = search;
      if (tag != null && tag.isNotEmpty) query['tag'] = tag;
      if (area != null && area.isNotEmpty) query['area'] = area;

      final response = await _api.get('/cafes', queryParameters: query);

      List<Cafe> apiList = [];
      if (response is List) {
        apiList = response.map((item) => Cafe.fromJson(item as Map<String, dynamic>)).toList();
      } else if (response is Map && response['data'] is List) {
        apiList = (response['data'] as List).map((item) => Cafe.fromJson(item as Map<String, dynamic>)).toList();
      }

      if (apiList.isNotEmpty) {
        return _filterFallback(search, tag, area, sourceCafes: apiList);
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

  List<Cafe> _filterFallback(String? search, String? tag, String? area, {List<Cafe>? sourceCafes}) {
    var list = sourceCafes ?? _defaultCafes();

    // 1. Search Query Filter
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      return list.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.address.toLowerCase().contains(q) ||
        c.area.toLowerCase().contains(q)
      ).toList();
    }

    // 2. Tag / Facility Filter
    if (tag != null && tag.trim().isNotEmpty) {
      final t = tag.trim().toLowerCase();
      return list.where((c) => _matchesTag(c, t)).toList();
    }

    // 3. Area Filter (for Popular Near You)
    if (area != null && area.trim().isNotEmpty) {
      final a = area.trim().toLowerCase();
      final filteredByArea = list.where((c) {
        final cafeArea = c.area.toLowerCase();
        final cafeAddress = c.address.toLowerCase();
        return cafeArea == a ||
               cafeAddress.contains(a) ||
               _areaMatchesDistrict(a, cafeArea, cafeAddress);
      }).toList();

      if (filteredByArea.isNotEmpty) {
        return filteredByArea;
      }
    }

    // Fallback: return all cafes so Home Page is never empty!
    return list;
  }

  bool _areaMatchesDistrict(String inputArea, String cafeArea, String cafeAddress) {
    if (inputArea.contains('jaksel') || inputArea.contains('selatan')) {
      return cafeArea == 'jaksel' || cafeAddress.contains('selatan') || cafeAddress.contains('senopati') || cafeAddress.contains('cipete');
    }
    if (inputArea.contains('jakut') || inputArea.contains('utara')) {
      return cafeArea == 'jakut' || cafeAddress.contains('utara') || cafeAddress.contains('pik') || cafeAddress.contains('sunter') || cafeAddress.contains('kelapa gading');
    }
    if (inputArea.contains('jakbar') || inputArea.contains('barat')) {
      return cafeArea == 'jakbar' || cafeAddress.contains('barat') || cafeAddress.contains('puri') || cafeAddress.contains('palmerah') || cafeAddress.contains('taman sari');
    }
    if (inputArea.contains('jakpus') || inputArea.contains('pusat')) {
      return cafeArea == 'jakpus' || cafeAddress.contains('pusat') || cafeAddress.contains('sabang') || cafeAddress.contains('menteng') || cafeAddress.contains('thamrin');
    }
    if (inputArea.contains('jaktim') || inputArea.contains('timur')) {
      return cafeArea == 'jaktim' || cafeAddress.contains('timur') || cafeAddress.contains('rawamangun') || cafeAddress.contains('cipayung');
    }
    return false;
  }

  bool _matchesTag(Cafe cafe, String tag) {
    final t = tag.toLowerCase().trim();
    if (t == 'work') {
      return cafe.facilities.any((f) {
        final lower = f.toLowerCase();
        return lower.contains('work') || lower.contains('laptop') || lower.contains('wifi');
      });
    } else if (t == 'study') {
      return cafe.facilities.any((f) {
        final lower = f.toLowerCase();
        return lower.contains('study') || lower.contains('reading') || lower.contains('work');
      });
    } else if (t == 'aesthetic') {
      return cafe.facilities.any((f) {
        final lower = f.toLowerCase();
        return lower.contains('aesthetic') || lower.contains('instagrammable') || lower.contains('outdoor');
      });
    } else if (t == 'pet friendly' || t == 'pet') {
      return cafe.facilities.any((f) {
        final lower = f.toLowerCase();
        return lower.contains('pet');
      });
    }
    return cafe.facilities.any((f) => f.toLowerCase().contains(t));
  }

  List<Cafe> _defaultCafes() {
    return const [
      // JAKARTA SELATAN (JAKSEL)
      Cafe(
        id: 'cafe-1',
        name: 'Anomali Coffee Senopati',
        address: 'Jl. Senopati No. 41, Kebayoran Baru, Jakarta Selatan',
        area: 'Jaksel',
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
        name: 'Kopi Tuku Cipete',
        address: 'Jl. Cipete Raya No. 7, Cipete, Jakarta Selatan',
        area: 'Jaksel',
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
        name: 'Common Grounds Kebayoran',
        address: 'Jl. Wijaya I No. 42, Kebayoran Baru, Jakarta Selatan',
        area: 'Jaksel',
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
        name: 'Tanamera Coffee Ampera',
        address: 'Jl. Ampera Raya No. 5, Cilandak, Jakarta Selatan',
        area: 'Jaksel',
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
        name: 'Nook Kebayoran',
        address: 'Jl. Senayan, Kebayoran Baru, Jakarta Selatan',
        area: 'Jaksel',
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

      // JAKARTA BARAT (JAKBAR)
      Cafe(
        id: 'cafe-6',
        name: 'Copper & Zinc Palmerah',
        address: 'Jl. Palmerah Utara No. 1, Jakarta Barat',
        area: 'Jakbar',
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
        name: 'Kopi Janji Jiwa Taman Sari',
        address: 'Jl. Mangga Besar, Taman Sari, Jakarta Barat',
        area: 'Jakbar',
        latitude: -6.1480,
        longitude: 106.8260,
        priceRange: 'Rp15.000 - Rp30.000',
        facilities: ['Takeaway', 'Air Conditioning', 'Study'],
        rating: 4.3,
        reviewsCount: 320,
        openingHours: '07:00 - 23:00',
        photos: [
          'https://images.unsplash.com/photo-1511537190424-bbbab87ac5eb?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-8',
        name: 'Say Something Coffee Puri',
        address: 'Puri Indah CBD, Kembangan, Jakarta Barat',
        area: 'Jakbar',
        latitude: -6.1891,
        longitude: 106.7382,
        priceRange: 'Rp30.000 - Rp60.000',
        facilities: ['Free Wi-Fi', 'Aesthetic', 'Work', 'Pet Friendly'],
        rating: 4.6,
        reviewsCount: 92,
        openingHours: '10:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1507133750040-4a8f57021571?w=600&q=80',
        ],
      ),

      // JAKARTA UTARA (JAKUT)
      Cafe(
        id: 'cafe-9',
        name: 'Ombe Kopi PIK',
        address: 'Ruko Cordoba, Pantai Indah Kapuk, Jakarta Utara',
        area: 'Jakut',
        latitude: -6.1105,
        longitude: 106.7412,
        priceRange: 'Rp35.000 - Rp70.000',
        facilities: ['Free Wi-Fi', 'Aesthetic', 'Pet Friendly', 'Work'],
        rating: 4.8,
        reviewsCount: 135,
        openingHours: '08:00 - 20:00',
        photos: [
          'https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-10',
        name: 'Six Ounce Coffee Kelapa Gading',
        address: 'Jl. Boulevard Raya WB2 No. 1, Kelapa Gading, Jakarta Utara',
        area: 'Jakut',
        latitude: -6.1578,
        longitude: 106.9088,
        priceRange: 'Rp35.000 - Rp80.000',
        facilities: ['Free Wi-Fi', 'Work', 'Pet Friendly', 'Aesthetic'],
        rating: 4.7,
        reviewsCount: 120,
        openingHours: '08:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1497636577773-f1231844b336?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-11',
        name: 'Saturdays Coffee Pademangan',
        address: 'Jl. Pangeran Jayakarta, Pademangan, Jakarta Utara',
        area: 'Jakut',
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

      // JAKARTA PUSAT (JAKPUS)
      Cafe(
        id: 'cafe-12',
        name: 'Gits Coffee Sabang',
        address: 'Jl. H. Agus Salim No. 38, Menteng, Jakarta Pusat',
        area: 'Jakpus',
        latitude: -6.1843,
        longitude: 106.8239,
        priceRange: 'Rp25.000 - Rp50.000',
        facilities: ['Work', 'Study', 'Free Wi-Fi'],
        rating: 4.7,
        reviewsCount: 140,
        openingHours: '08:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1511920170033-f8396924c348?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-13',
        name: 'Djournal Coffee Thamrin',
        address: 'Grand Indonesia West Mall, Thamrin, Jakarta Pusat',
        area: 'Jakpus',
        latitude: -6.1950,
        longitude: 106.8211,
        priceRange: 'Rp35.000 - Rp75.000',
        facilities: ['Free Wi-Fi', 'Aesthetic', 'Work'],
        rating: 4.6,
        reviewsCount: 180,
        openingHours: '08:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600&q=80',
        ],
      ),

      // JAKARTA TIMUR (JAKTIM)
      Cafe(
        id: 'cafe-14',
        name: 'Kopikina Rawamangun',
        address: 'Jl. Mahoni No. 8, Rawamangun, Jakarta Timur',
        area: 'Jaktim',
        latitude: -6.1921,
        longitude: 106.8834,
        priceRange: 'Rp20.000 - Rp45.000',
        facilities: ['Study', 'Free Wi-Fi', 'Pet Friendly'],
        rating: 4.6,
        reviewsCount: 85,
        openingHours: '09:00 - 23:00',
        photos: [
          'https://images.unsplash.com/photo-1447933601403-0c6688de566e?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-15',
        name: 'Teras Rumah Kopi Cipayung',
        address: 'Jl. Raya Cipayung No. 15, Jakarta Timur',
        area: 'Jaktim',
        latitude: -6.3120,
        longitude: 106.9012,
        priceRange: 'Rp20.000 - Rp40.000',
        facilities: ['Pet Friendly', 'Aesthetic', 'Outdoor Area'],
        rating: 4.5,
        reviewsCount: 65,
        openingHours: '10:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&q=80',
        ],
      ),
    ];
  }
}
