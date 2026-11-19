import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/supabase_service.dart';

// ==========================================
// SAVED CAFE MODEL
// ==========================================

class SavedCafe {
  final String? id;
  final String? cafeId;
  final String name;
  final String location;
  final double rating;
  final String? photoUrl;

  const SavedCafe({
    this.id,
    this.cafeId,
    required this.name,
    required this.location,
    this.rating = 4.5,
    this.photoUrl,
  });

  factory SavedCafe.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 4.5;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 4.5;
    }

    String name = 'Saved Cafe';
    String location = 'Jakarta';
    if (json['cafe'] is Map) {
      name = json['cafe']['name']?.toString() ?? name;
      location = json['cafe']['address']?.toString() ?? json['cafe']['location']?.toString() ?? location;
    } else if (json['cafes'] is Map) {
      name = json['cafes']['name']?.toString() ?? name;
      location = json['cafes']['address']?.toString() ?? json['cafes']['location']?.toString() ?? location;
    } else if (json['name'] != null) {
      name = json['name'].toString();
      location = json['location']?.toString() ?? json['address']?.toString() ?? location;
    }

    return SavedCafe(
      id: json['id']?.toString(),
      cafeId: json['cafe_id']?.toString() ?? json['id']?.toString(),
      name: name,
      location: location,
      rating: parseDouble(json['rating'] ?? (json['cafe'] is Map ? json['cafe']['rating'] : null)),
      photoUrl: json['photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cafe_id': cafeId,
        'name': name,
        'location': location,
        'rating': rating,
        'photo_url': photoUrl,
      };
}

// ==========================================
// SAVED CAFE STORE & REPOSITORY
// ==========================================

class SavedCafeStore extends ChangeNotifier {
  SavedCafeStore._();

  static final SavedCafeStore instance = SavedCafeStore._();

  final List<SavedCafe> _savedCafes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SavedCafe> get savedCafes => List.unmodifiable(_savedCafes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isSaved(String cafeName) {
    return _savedCafes.any(
      (cafe) => cafe.name.trim().toLowerCase() == cafeName.trim().toLowerCase(),
    );
  }

  /// Call this on logout to clear in-memory cache.
  void clearOnLogout() {
    _savedCafes.clear();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchSavedCafes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final sb = SupabaseService.instance;
    final currentUser = sb.currentUser;

    if (sb.isInitialized && currentUser != null && sb.client != null) {
      try {
        final data = await sb.client!
            .from('saved_cafes')
            .select('id,cafe_id,saved_at,cafes(id,name,address,photos)')
            .eq('user_id', currentUser.id);
        if (data.isNotEmpty) {
          _savedCafes.clear();
          for (final item in data) {
            _savedCafes.add(SavedCafe.fromJson(item));
          }
          _isLoading = false;
          notifyListeners();
          return;
        }
      } catch (_) {}
    }

    try {
      final response = await ApiClient.instance.get('/saved-cafes');
      if (response is List) {
        _savedCafes.clear();
        for (final item in response) {
          if (item is Map<String, dynamic>) {
            _savedCafes.add(SavedCafe.fromJson(item));
          }
        }
      }
    } catch (e) {
      // Keep existing memory items on error
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleSaved(SavedCafe cafe) async {
    final alreadySaved = isSaved(cafe.name);
    final sb = SupabaseService.instance;
    final currentUser = sb.currentUser;

    if (alreadySaved) {
      _savedCafes.removeWhere(
        (item) => item.name.trim().toLowerCase() == cafe.name.trim().toLowerCase(),
      );
      notifyListeners();

      if (sb.isInitialized && currentUser != null && cafe.cafeId != null && cafe.cafeId!.isNotEmpty) {
        try {
          await sb.client!.from('saved_cafes').delete().eq('user_id', currentUser.id).eq('cafe_id', cafe.cafeId!);
        } catch (_) {}
      }

      try {
        if (cafe.cafeId != null && cafe.cafeId!.isNotEmpty) {
          await ApiClient.instance.delete('/saved-cafes/${cafe.cafeId}');
        }
      } catch (_) {}
    } else {
      _savedCafes.add(cafe);
      notifyListeners();

      if (sb.isInitialized && currentUser != null && cafe.cafeId != null && cafe.cafeId!.isNotEmpty) {
        try {
          await sb.client!.from('saved_cafes').upsert({
            'user_id': currentUser.id,
            'cafe_id': cafe.cafeId!,
          }, onConflict: 'user_id,cafe_id');
        } catch (_) {}
      }

      try {
        if (cafe.cafeId != null && cafe.cafeId!.isNotEmpty) {
          await ApiClient.instance.post('/saved-cafes', body: {'cafe_id': cafe.cafeId});
        }
      } catch (_) {}
    }
  }

  Future<void> removeCafe(String cafeName) async {
    final target = _savedCafes.firstWhere(
      (c) => c.name.trim().toLowerCase() == cafeName.trim().toLowerCase(),
      orElse: () => SavedCafe(name: cafeName, location: ''),
    );

    _savedCafes.removeWhere(
      (cafe) => cafe.name.trim().toLowerCase() == cafeName.trim().toLowerCase(),
    );
    notifyListeners();

    final sb = SupabaseService.instance;
    final currentUser = sb.currentUser;
    if (sb.isInitialized && currentUser != null && target.cafeId != null && target.cafeId!.isNotEmpty) {
      try {
        await sb.client!.from('saved_cafes').delete().eq('user_id', currentUser.id).eq('cafe_id', target.cafeId!);
      } catch (_) {}
    }

    if (target.cafeId != null && target.cafeId!.isNotEmpty) {
      try {
        await ApiClient.instance.delete('/saved-cafes/${target.cafeId}');
      } catch (_) {}
    }
  }
}
