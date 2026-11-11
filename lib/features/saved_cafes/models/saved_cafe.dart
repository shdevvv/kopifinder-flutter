import 'package:flutter/foundation.dart';

// ==========================================
// SAVED CAFE MODEL
// ==========================================

class SavedCafe {
  final String name;
  final String location;

  const SavedCafe({
    required this.name,
    required this.location,
  });
}

// ==========================================
// SAVED CAFE STORE
// ==========================================

class SavedCafeStore extends ChangeNotifier {
  SavedCafeStore._();

  static final SavedCafeStore instance = SavedCafeStore._();

  final List<SavedCafe> _savedCafes = [];

  // GET SAVED CAFES
  List<SavedCafe> get savedCafes => List.unmodifiable(_savedCafes);

  // CHECK IF CAFE IS SAVED
  bool isSaved(String cafeName) {
    return _savedCafes.any(
      (cafe) => cafe.name == cafeName,
    );
  }

  // ADD OR REMOVE SAVED CAFE
  void toggleSaved(SavedCafe cafe) {
    if (isSaved(cafe.name)) {
      _savedCafes.removeWhere(
        (item) => item.name == cafe.name,
      );
    } else {
      _savedCafes.add(cafe);
    }

    notifyListeners();
  }

  // REMOVE CAFE
  void removeCafe(String cafeName) {
    _savedCafes.removeWhere(
      (cafe) => cafe.name == cafeName,
    );

    notifyListeners();
  }
}
