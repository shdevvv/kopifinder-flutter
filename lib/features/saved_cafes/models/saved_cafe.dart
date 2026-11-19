import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    String? photoUrl;

    if (json['cafe'] is Map) {
      final cafeMap = json['cafe'] as Map;
      name = cafeMap['name']?.toString() ?? name;
      location = cafeMap['address']?.toString() ?? cafeMap['location']?.toString() ?? location;
      if (cafeMap['photos'] is List && (cafeMap['photos'] as List).isNotEmpty) {
        photoUrl = (cafeMap['photos'] as List).first.toString();
      }
    } else if (json['cafes'] is Map) {
      final cafesMap = json['cafes'] as Map;
      name = cafesMap['name']?.toString() ?? name;
      location = cafesMap['address']?.toString() ?? cafesMap['location']?.toString() ?? location;
      if (cafesMap['photos'] is List && (cafesMap['photos'] as List).isNotEmpty) {
        photoUrl = (cafesMap['photos'] as List).first.toString();
      }
    } else if (json['name'] != null) {
      name = json['name'].toString();
      location = json['location']?.toString() ?? json['address']?.toString() ?? location;
    }

    if (photoUrl == null || photoUrl.isEmpty) {
      if (json['photo_url'] != null) {
        photoUrl = json['photo_url'].toString();
      } else if (json['photos'] is List && (json['photos'] as List).isNotEmpty) {
        photoUrl = (json['photos'] as List).first.toString();
      }
    }

    return SavedCafe(
      id: json['id']?.toString(),
      cafeId: json['cafe_id']?.toString() ?? json['id']?.toString(),
      name: name,
      location: location,
      rating: parseDouble(json['rating'] ?? (json['cafe'] is Map ? json['cafe']['rating'] : null)),
      photoUrl: photoUrl,
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
// SAVED CAFE STORE & REPOSITORY (WITH LOCAL SP PERSISTENCE)
// ==========================================

class SavedCafeStore extends ChangeNotifier {
  static const String _spKey = 'kopifinder_saved_cafes_v1';

  SavedCafeStore._() {
    _loadFromSharedPreferences();
  }

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

  /// Load local persistent bookmarks from SharedPreferences
  Future<void> _loadFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_spKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = jsonDecode(jsonString);
        if (decoded is List) {
          _savedCafes.clear();
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              _savedCafes.add(SavedCafe.fromJson(item));
            }
          }
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// Save current bookmarks to local SharedPreferences
  Future<void> _saveToSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _savedCafes.map((c) => c.toJson()).toList();
      await prefs.setString(_spKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// Call this on logout to clear in-memory and local cache.
  void clearOnLogout() {
    _savedCafes.clear();
    _isLoading = false;
    _errorMessage = null;
    _saveToSharedPreferences();
    notifyListeners();
  }

  Future<void> fetchSavedCafes() async {
    // Load local SP items first so bookmarks are available instantly across sessions
    await _loadFromSharedPreferences();

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
          for (final item in data) {
            final remoteCafe = SavedCafe.fromJson(item);
            if (!isSaved(remoteCafe.name)) {
              _savedCafes.add(remoteCafe);
            }
          }
          _saveToSharedPreferences();
          _isLoading = false;
          notifyListeners();
          return;
        }
      } catch (_) {}
    }

    try {
      final response = await ApiClient.instance.get('/saved-cafes');
      if (response is List) {
        for (final item in response) {
          if (item is Map<String, dynamic>) {
            final remoteCafe = SavedCafe.fromJson(item);
            if (!isSaved(remoteCafe.name)) {
              _savedCafes.add(remoteCafe);
            }
          }
        }
        _saveToSharedPreferences();
      }
    } catch (e) {
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
      _saveToSharedPreferences();
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
      _saveToSharedPreferences();
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
    _saveToSharedPreferences();
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
