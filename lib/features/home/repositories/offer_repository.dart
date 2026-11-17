import '../../../core/network/api_client.dart';
import '../models/offer.dart';

class OfferRepository {
  OfferRepository._();
  static final OfferRepository instance = OfferRepository._();

  final ApiClient _api = ApiClient.instance;

  Future<List<Offer>> getOffers() async {
    try {
      final response = await _api.get('/offers');
      if (response is List) {
        return response.map((item) => Offer.fromJson(item as Map<String, dynamic>)).toList();
      }
      return _defaultOffers();
    } catch (_) {
      return _defaultOffers();
    }
  }

  List<Offer> _defaultOffers() {
    return const [
      Offer(
        id: 'offer-1',
        cafeId: 'cafe-1',
        cafeName: 'First Coffee',
        title: 'Caramel Macchiato Special',
        description: 'Diskon 30% untuk Caramel Macchiato ukuran Large setiap hari kerja!',
        originalPrice: 45000,
        discountedPrice: 31500,
        discountPercentage: 30,
        validUntil: '2026-12-31',
      ),
      Offer(
        id: 'offer-2',
        cafeId: 'cafe-2',
        cafeName: 'Daily Brew',
        title: 'Morning Brew Combo',
        description: 'Beli 1 Kopi Susu dapat 1 Croissant gratis sebelum jam 10:00.',
        originalPrice: 55000,
        discountedPrice: 35000,
        discountPercentage: 36,
        validUntil: '2026-12-31',
      ),
    ];
  }
}
