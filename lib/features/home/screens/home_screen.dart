import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../cafe_details/screens/cafe_details_screen.dart';
import '../../saved_cafes/screens/saved_cafes_screen.dart';
import '../models/cafe.dart';
import '../repositories/cafe_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const cream = Color(0xFFFAF7F0);
  static const lightGreen = Color(0xFFE8EDDF);
  static const sage = Color(0xFF9AAA83);
  static const darkGreen = Color(0xFF52634A);
  static const brown = Color(0xFF795548);
  static const darkBrown = Color(0xFF4E342E);

  String? selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;

  final List<String> filters = ['Work', 'Study', 'Aesthetic', 'Pet Friendly'];

  // Popular cafes (default, by area)
  List<Cafe> _cafes = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Search results (separate)
  List<Cafe> _searchResults = [];
  bool _isSearchLoading = false;
  bool _hasSearched = false;

  // Location
  String _locationLabel = 'Jakarta';
  String? _currentArea; // Jaksel, Jakpus, Jakbar, Jakut, Jaktim
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _fetchLocation();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final text = _searchController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _isSearchActive = false;
        _hasSearched = false;
        _searchResults = [];
      });
    } else {
      setState(() {
        _isSearchActive = true;
      });
    }
  }

  // ── GPS & Location ──────────────────────────────────────────────────

  Future<void> _fetchLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() { _locationLabel = 'Jakarta'; _isLocating = false; });
        _loadCafes();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) setState(() { _locationLabel = 'Jakarta'; _isLocating = false; });
        _loadCafes();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final area = _getJakartaDistrict(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _currentArea = area;
          _locationLabel = area;
          _isLocating = false;
        });
      }
      _loadCafes();
    } catch (_) {
      if (mounted) {
        setState(() { _locationLabel = 'Jakarta'; _isLocating = false; });
        _loadCafes();
      }
    }
  }

  /// Map GPS coordinates to Jakarta administrative district.
  String _getJakartaDistrict(double lat, double lng) {
    // Jakarta Utara: north of -6.14
    if (lat > -6.14) return 'Jakarta Utara';
    // Jakarta Barat: west of lng 106.78 and not too south
    if (lng < 106.78 && lat > -6.23) return 'Jakarta Barat';
    // Jakarta Timur: east of lng 106.87
    if (lng > 106.87) return 'Jakarta Timur';
    // Jakarta Selatan: south of -6.22
    if (lat < -6.22) return 'Jakarta Selatan';
    // Jakarta Pusat: center
    return 'Jakarta Pusat';
  }

  /// Convert display district name to backend area code.
  String? _districtToAreaCode(String? district) {
    if (district == null) return null;
    const map = {
      'Jakarta Selatan': 'Jaksel',
      'Jakarta Pusat': 'Jakpus',
      'Jakarta Barat': 'Jakbar',
      'Jakarta Utara': 'Jakut',
      'Jakarta Timur': 'Jaktim',
    };
    return map[district];
  }

  // ── Data Loading ─────────────────────────────────────────────────────

  Future<void> _loadCafes() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final areaCode = _districtToAreaCode(_currentArea);
      final cafes = await CafeRepository.instance.getCafes(
        tag: selectedFilter,
        area: areaCode,
      );
      if (mounted) setState(() { _cafes = cafes; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _doSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() { _isSearchLoading = true; _hasSearched = false; });
    try {
      final results = await CafeRepository.instance.getCafes(search: query);
      if (mounted) setState(() { _searchResults = results; _isSearchLoading = false; _hasSearched = true; });
    } catch (_) {
      if (mounted) setState(() { _searchResults = []; _isSearchLoading = false; _hasSearched = true; });
    }
  }

  Future<void> _onFilterChanged() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final areaCode = _districtToAreaCode(_currentArea);
      final cafes = await CafeRepository.instance.getCafes(
        tag: selectedFilter,
        area: areaCode,
      );
      if (mounted) setState(() { _cafes = cafes; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: RefreshIndicator(
          color: darkGreen,
          backgroundColor: cream,
          onRefresh: () async {
            await _fetchLocation();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER: Logo + Location + Bookmark ──────────────────
                Row(
                  children: [
                    // 3D Papercut Medallion Logo (exact match with brand medal)
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEBDDCB),
                        border: Border.all(color: const Color(0xFFD5C4B1), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF382317).withOpacity(0.18),
                            offset: const Offset(0, 3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF3F7F2),
                            border: Border.all(color: const Color(0xFF8DBA20), width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.white,
                                offset: Offset(0, -1),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Image.asset(
                                'assets/icon/no_text_logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOUR LOCATION',
                            style: TextStyle(
                              fontSize: 11,
                              color: sage,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              if (_isLocating)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: darkGreen),
                                )
                              else
                                const Icon(Icons.location_on_rounded, color: darkGreen, size: 18),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _locationLabel,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: darkBrown,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 3D Papercut Saved cafes button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedCafesScreen()));
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: -3,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4C1B0),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2D4C5), width: 1.6),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.white,
                                  offset: Offset(0, -1),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.bookmark_border_rounded, color: Color(0xFF526B0C), size: 24),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // ── 3D PAPERCUT SEARCH BAR ────────────────────────────────
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -3.5,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4C1B0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2D4C5), width: 1.8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.white,
                            offset: Offset(0, -1),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _doSearch(),
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF382317), fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Search cafes...',
                          hintStyle: TextStyle(color: brown.withOpacity(0.55), fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF526B0C)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: sage, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _isSearchActive = false;
                                      _hasSearched = false;
                                      _searchResults = [];
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── SEARCH RESULTS (shown directly below search bar) ──────
                if (_isSearchActive) ...[
                  const SizedBox(height: 10),
                  if (_isSearchLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: AppLoadingWidget(message: 'Searching cafes...'),
                    )
                  else if (!_hasSearched)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ElevatedButton.icon(
                        onPressed: _doSearch,
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Search'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    )
                  else if (_searchResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: AppEmptyWidget(
                        icon: Icons.search_off_rounded,
                        title: 'No Cafes Found',
                        description: 'No cafes match your search.',
                      ),
                    )
                  else ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_searchResults.length} results for "${_searchController.text.trim()}"',
                      style: const TextStyle(fontSize: 13, color: sage, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    ..._searchResults.map((cafe) => _buildCafeCard(cafe)),
                  ],
                ],

                const SizedBox(height: 20),

                // ── 3D PAPERCUT FILTER BUTTONS ────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: filters.map((filter) {
                      final isSelected = selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10, bottom: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => selectedFilter = isSelected ? null : filter);
                            _onFilterChanged();
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: -3,
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF364807) : const Color(0xFFD4C1B0),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF526B0C) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFA5C943) : const Color(0xFFE2D4C5),
                                    width: 1.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.white,
                                      offset: Offset(0, -1),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    filter,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFF382317),
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // ── POPULAR / FILTERED CAFES (hidden when searching) ───────
                if (!_isSearchActive) ...[
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: brown, size: 21),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedFilter != null
                              ? '"$selectedFilter" Cafes in $_locationLabel'
                              : 'Popular Near You · $_locationLabel',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: AppLoadingWidget(message: 'Loading cafes...'),
                    )
                  else if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: AppErrorWidget(message: _errorMessage!, onRetry: _loadCafes),
                    )
                  else if (_cafes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: AppEmptyWidget(
                        icon: Icons.search_off_rounded,
                        title: 'No Cafes Found',
                        description: 'No cafes found in this area yet.',
                      ),
                    )
                  else
                    ..._cafes.map((cafe) => _buildCafeCard(cafe)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 3D Papercut Cafe Card ──────────────────────────────────────────────
  Widget _buildCafeCard(Cafe cafe) {
    final photoUrl = cafe.photos.isNotEmpty ? cafe.photos[0] : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CafeDetailsScreen(
                cafeId: cafe.id,
                cafeName: cafe.name,
                cafeLocation: cafe.address,
                cafe: cafe,
              ),
            ),
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Bottom paper shadow shelf
            Positioned(
              left: 3,
              top: 4,
              right: -3,
              bottom: -4,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFD4C1B0),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            // Front white paper card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2D4C5), width: 1.8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(0, -1),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Cafe photo with 3D papercut border
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFE2D4C5), width: 1.4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: photoUrl != null
                          ? Image.network(
                              photoUrl,
                              width: 74,
                              height: 74,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _cafePhotoPlaceholder(),
                            )
                          : _cafePhotoPlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cafe.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Color(0xFF382317),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cafe.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B4C38)),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // 3D Rating pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9E6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFFD54F), width: 1),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    cafe.rating.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF382317)),
                                  ),
                                ],
                              ),
                            ),
                            if (cafe.priceRange != null) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  cafe.priceRange!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF526B0C), fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F2E9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2D4C5), width: 1.2),
                    ),
                    child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF526B0C), size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cafePhotoPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.local_cafe_rounded, color: darkGreen, size: 28),
    );
  }
}
