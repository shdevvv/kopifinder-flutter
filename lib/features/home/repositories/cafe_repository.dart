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

  List<Cafe> getCafesSync() {
    return _defaultCafes().where((c) => !c.name.toLowerCase().contains('cacaote')).toList();
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
    var list = (sourceCafes ?? _defaultCafes())
        .where((c) => !c.name.toLowerCase().contains('cacaote'))
        .toList();

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
      return cafeArea == 'jaksel' || cafeAddress.contains('selatan') || cafeAddress.contains('senopati') || cafeAddress.contains('cipete') || cafeAddress.contains('kebayoran') || cafeAddress.contains('cilandak') || cafeAddress.contains('tebet');
    }
    if (inputArea.contains('jakut') || inputArea.contains('utara')) {
      return cafeArea == 'jakut' || cafeAddress.contains('utara') || cafeAddress.contains('pik') || cafeAddress.contains('sunter') || cafeAddress.contains('kelapa gading') || cafeAddress.contains('pluit');
    }
    if (inputArea.contains('jakbar') || inputArea.contains('barat')) {
      return cafeArea == 'jakbar' || cafeAddress.contains('barat') || cafeAddress.contains('puri') || cafeAddress.contains('palmerah') || cafeAddress.contains('kembangan') || cafeAddress.contains('tanjung duren') || cafeAddress.contains('kebon jeruk');
    }
    if (inputArea.contains('jakpus') || inputArea.contains('pusat')) {
      return cafeArea == 'jakpus' || cafeAddress.contains('pusat') || cafeAddress.contains('sabang') || cafeAddress.contains('menteng') || cafeAddress.contains('thamrin') || cafeAddress.contains('cikini') || cafeAddress.contains('sudirman') || cafeAddress.contains('glodok');
    }
    if (inputArea.contains('jaktim') || inputArea.contains('timur')) {
      return cafeArea == 'jaktim' || cafeAddress.contains('timur') || cafeAddress.contains('rawamangun') || cafeAddress.contains('cipayung') || cafeAddress.contains('duren sawit') || cafeAddress.contains('kalimalang') || cafeAddress.contains('pulogadung');
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
        address: 'Jl. Senopati No. 19, Kebayoran Baru, Jakarta Selatan',
        area: 'Jaksel',
        latitude: -6.2305,
        longitude: 106.8115,
        priceRange: 'Rp30.000 - Rp65.000',
        facilities: ['Free Wi-Fi', 'Air Conditioning', 'Indoor Seating', 'Work', 'Study'],
        rating: 4.8,
        reviewsCount: 240,
        openingHours: '07:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600&q=80',
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-2',
        name: 'Tuku Cipete',
        address: 'Jl. Cipete Raya No. 7, Cilandak, Jakarta Selatan',
        area: 'Jaksel',
        latitude: -6.2622,
        longitude: 106.7901,
        priceRange: 'Rp20.000 - Rp45.000',
        facilities: ['Free Wi-Fi', 'Outdoor Area', 'Pet Friendly', 'Aesthetic'],
        rating: 4.7,
        reviewsCount: 380,
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
        rating: 4.8,
        reviewsCount: 190,
        openingHours: '08:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1445116572660-236099ec97a0?w=600&q=80',
          'https://images.unsplash.com/photo-1517705008128-361805f42e86?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-4',
        name: 'One-Fifthy Coffee Gandaria',
        address: 'Jl. Gandaria I No. 63, Kebayoran Baru, Jakarta Selatan',
        area: 'Jaksel',
        latitude: -6.2435,
        longitude: 106.7890,
        priceRange: 'Rp35.000 - Rp75.000',
        facilities: ['Free Wi-Fi', 'Aesthetic', 'Work', 'Indoor Seating'],
        rating: 4.9,
        reviewsCount: 260,
        openingHours: '08:00 - 21:00',
        photos: [
          'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-5',
        name: 'Tanamera Coffee Senopati',
        address: 'Jl. KH Ahmad Dahlan No. 16, Kebayoran Baru, Jakarta Selatan',
        area: 'Jaksel',
        latitude: -6.2410,
        longitude: 106.7925,
        priceRange: 'Rp30.000 - Rp65.000',
        facilities: ['Free Wi-Fi', 'Air Conditioning', 'Study', 'Work'],
        rating: 4.7,
        reviewsCount: 310,
        openingHours: '07:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-6',
        name: 'Kopi Nako Tebet',
        address: 'Jl. Tebet Barat Dalam No. 12, Tebet, Jakarta Selatan',
        area: 'Jaksel',
        latitude: -6.2260,
        longitude: 106.8480,
        priceRange: 'Rp20.000 - Rp45.000',
        facilities: ['Free Wi-Fi', 'Outdoor Area', 'Pet Friendly', 'Aesthetic'],
        rating: 4.6,
        reviewsCount: 210,
        openingHours: '08:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&q=80',
        ],
      ),

      // JAKARTA UTARA (JAKUT)
      Cafe(
        id: 'cafe-7',
        name: 'Ombe Kopi PIK',
        address: 'Ruko Cordoba Blok E No. 8, Pantai Indah Kapuk, Jakarta Utara',
        area: 'Jakut',
        latitude: -6.1105,
        longitude: 106.7412,
        priceRange: 'Rp35.000 - Rp70.000',
        facilities: ['Free Wi-Fi', 'Aesthetic', 'Pet Friendly', 'Work'],
        rating: 4.8,
        reviewsCount: 220,
        openingHours: '08:00 - 20:00',
        photos: [
          'https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-8',
        name: 'Six Ounce Coffee Kelapa Gading',
        address: 'Jl. Boulevard Raya WB2 No. 1, Kelapa Gading, Jakarta Utara',
        area: 'Jakut',
        latitude: -6.1578,
        longitude: 106.9088,
        priceRange: 'Rp35.000 - Rp80.000',
        facilities: ['Free Wi-Fi', 'Work', 'Pet Friendly', 'Aesthetic'],
        rating: 4.8,
        reviewsCount: 195,
        openingHours: '08:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1497636577773-f1231844b336?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-9',
        name: 'Bukanagara Coffee Sunter',
        address: 'Jl. Danau Sunter Utara No. 42, Tanjung Priok, Jakarta Utara',
        area: 'Jakut',
        latitude: -6.1389,
        longitude: 106.8654,
        priceRange: 'Rp30.000 - Rp60.000',
        facilities: ['Free Wi-Fi', 'Air Conditioning', 'Study', 'Outdoor Area'],
        rating: 4.7,
        reviewsCount: 140,
        openingHours: '08:00 - 21:00',
        photos: [
          'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-10',
        name: 'Kopi Se-Indonesia Pluit',
        address: 'Jl. Pluit Karang Cantik No. 18, Penjaringan, Jakarta Utara',
        area: 'Jakut',
        latitude: -6.1210,
        longitude: 106.7910,
        priceRange: 'Rp20.000 - Rp45.000',
        facilities: ['Free Wi-Fi', 'Pet Friendly', 'Outdoor Area'],
        rating: 4.5,
        reviewsCount: 110,
        openingHours: '09:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-11',
        name: 'Caffè Milano PIK Avenue',
        address: 'PIK Avenue GF Floor, Pantai Indah Kapuk, Jakarta Utara',
        area: 'Jakut',
        latitude: -6.1080,
        longitude: 106.7390,
        priceRange: 'Rp40.000 - Rp90.000',
        facilities: ['Free Wi-Fi', 'Aesthetic', 'Work', 'Indoor Seating'],
        rating: 4.7,
        reviewsCount: 180,
        openingHours: '10:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=600&q=80',
        ],
      ),

      // JAKARTA BARAT (JAKBAR)
      Cafe(
        id: 'cafe-12',
        name: 'Tanamera Coffee Puri',
        address: 'Puri Indah CBD Blok T2 No. 1, Kembangan, Jakarta Barat',
        area: 'Jakbar',
        latitude: -6.1891,
        longitude: 106.7382,
        priceRange: 'Rp30.000 - Rp65.000',
        facilities: ['Free Wi-Fi', 'Work', 'Study', 'Air Conditioning'],
        rating: 4.7,
        reviewsCount: 185,
        openingHours: '07:00 - 21:00',
        photos: [
          'https://images.unsplash.com/photo-1498804103079-a6351b050096?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-13',
        name: 'Say Something Coffee Central Park',
        address: 'Central Park Mall LG Floor, Tanjung Duren, Jakarta Barat',
        area: 'Jakbar',
        latitude: -6.1772,
        longitude: 106.7905,
        priceRange: 'Rp30.000 - Rp60.000',
        facilities: ['Free Wi-Fi', 'Aesthetic', 'Work', 'Pet Friendly'],
        rating: 4.6,
        reviewsCount: 160,
        openingHours: '10:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1507133750040-4a8f57021571?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-14',
        name: 'Headline Espresso Palmerah',
        address: 'Jl. Kemanggisan Utama No. 8, Palmerah, Jakarta Barat',
        area: 'Jakbar',
        latitude: -6.2100,
        longitude: 106.7950,
        priceRange: 'Rp25.000 - Rp50.000',
        facilities: ['Free Wi-Fi', 'Air Conditioning', 'Work', 'Study'],
        rating: 4.6,
        reviewsCount: 110,
        openingHours: '08:00 - 21:00',
        photos: [
          'https://images.unsplash.com/photo-1534040385115-33dcb3acba5b?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-15',
        name: 'Onni House Tanjung Duren',
        address: 'Jl. Tanjung Duren Utara V No. 242, Grogol Petamburan, Jakarta Barat',
        area: 'Jakbar',
        latitude: -6.1720,
        longitude: 106.7840,
        priceRange: 'Rp30.000 - Rp70.000',
        facilities: ['Free Wi-Fi', 'Aesthetic', 'Outdoor Area', 'Pet Friendly'],
        rating: 4.7,
        reviewsCount: 220,
        openingHours: '10:00 - 21:00',
        photos: [
          'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=600&q=80',
        ],
      ),

      // JAKARTA PUSAT (JAKPUS)
      Cafe(
        id: 'cafe-16',
        name: 'Monolog Coffee Menteng',
        address: 'Jl. H. Agus Salim No. 38, Menteng, Jakarta Pusat',
        area: 'Jakpus',
        latitude: -6.1843,
        longitude: 106.8239,
        priceRange: 'Rp30.000 - Rp70.000',
        facilities: ['Work', 'Study', 'Free Wi-Fi', 'Air Conditioning'],
        rating: 4.7,
        reviewsCount: 230,
        openingHours: '07:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1511920170033-f8396924c348?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-17',
        name: 'Djournal Coffee Grand Indonesia',
        address: 'Grand Indonesia West Mall GF, Thamrin, Jakarta Pusat',
        area: 'Jakpus',
        latitude: -6.1950,
        longitude: 106.8211,
        priceRange: 'Rp35.000 - Rp75.000',
        facilities: ['Free Wi-Fi', 'Aesthetic', 'Work'],
        rating: 4.7,
        reviewsCount: 340,
        openingHours: '08:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-18',
        name: 'Workroom Coffee Cikini',
        address: 'Jl. Cikini Raya No. 9, Menteng, Jakarta Pusat',
        area: 'Jakpus',
        latitude: -6.1915,
        longitude: 106.8385,
        priceRange: 'Rp25.000 - Rp55.000',
        facilities: ['Work', 'Study', 'Free Wi-Fi', 'Air Conditioning'],
        rating: 4.6,
        reviewsCount: 175,
        openingHours: '08:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-19',
        name: 'Bukanagara Coffee Sudirman',
        address: 'Graha CIMB Niaga, Jl. Jend. Sudirman, Senayan, Jakarta Pusat',
        area: 'Jakpus',
        latitude: -6.2230,
        longitude: 106.8090,
        priceRange: 'Rp30.000 - Rp65.000',
        facilities: ['Free Wi-Fi', 'Aesthetic', 'Work', 'Outdoor Area'],
        rating: 4.8,
        reviewsCount: 290,
        openingHours: '07:00 - 20:00',
        photos: [
          'https://images.unsplash.com/photo-1517705008128-361805f42e86?w=600&q=80',
        ],
      ),

      // JAKARTA TIMUR (JAKTIM)
      Cafe(
        id: 'cafe-20',
        name: 'Kopikina Rawamangun',
        address: 'Jl. Mahoni No. 8, Rawamangun, Jakarta Timur',
        area: 'Jaktim',
        latitude: -6.1921,
        longitude: 106.8834,
        priceRange: 'Rp20.000 - Rp45.000',
        facilities: ['Study', 'Free Wi-Fi', 'Pet Friendly'],
        rating: 4.7,
        reviewsCount: 155,
        openingHours: '09:00 - 23:00',
        photos: [
          'https://images.unsplash.com/photo-1447933601403-0c6688de566e?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-21',
        name: 'Kopi Nako Duren Sawit',
        address: 'Jl. Raden Inten II No. 18, Duren Sawit, Jakarta Timur',
        area: 'Jaktim',
        latitude: -6.2310,
        longitude: 106.9080,
        priceRange: 'Rp20.000 - Rp45.000',
        facilities: ['Pet Friendly', 'Aesthetic', 'Outdoor Area', 'Free Wi-Fi'],
        rating: 4.6,
        reviewsCount: 280,
        openingHours: '08:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-22',
        name: 'Teras Rumah Kopi Cipayung',
        address: 'Jl. Raya Cipayung No. 15, Cipayung, Jakarta Timur',
        area: 'Jaktim',
        latitude: -6.3120,
        longitude: 106.9012,
        priceRange: 'Rp20.000 - Rp40.000',
        facilities: ['Pet Friendly', 'Aesthetic', 'Outdoor Area'],
        rating: 4.5,
        reviewsCount: 95,
        openingHours: '10:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600&q=80',
        ],
      ),
      Cafe(
        id: 'cafe-23',
        name: 'Kedai Kopi Local Rawamangun',
        address: 'Jl. Balai Pustaka Timur No. 12, Rawamangun, Jakarta Timur',
        area: 'Jaktim',
        latitude: -6.1950,
        longitude: 106.8920,
        priceRange: 'Rp18.000 - Rp38.000',
        facilities: ['Free Wi-Fi', 'Study', 'Air Conditioning'],
        rating: 4.6,
        reviewsCount: 130,
        openingHours: '08:00 - 22:00',
        photos: [
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=80',
        ],
      ),
    ];
  }
}
