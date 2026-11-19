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
                    // KopiFinder logo
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: lightGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDCE4D3)),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icons/new_app_icon.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
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

                    // Saved cafes button
                    Container(
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedCafesScreen()));
                        },
                        icon: const Icon(Icons.bookmark_border_rounded, color: darkGreen, size: 25),
                        tooltip: 'Saved Cafes',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // ── SEARCH BAR ────────────────────────────────────────────
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _doSearch(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari nama kafe...',
                    hintStyle: TextStyle(color: brown.withOpacity(0.55), fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: darkGreen),
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
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFE4E8DC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: sage, width: 1.5),
                    ),
                  ),
                ),

                // ── SEARCH RESULTS (shown directly below search bar) ──────
                if (_isSearchActive) ...[
                  const SizedBox(height: 10),
                  if (_isSearchLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: AppLoadingWidget(message: 'Mencari kafe...'),
                    )
                  else if (!_hasSearched)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ElevatedButton.icon(
                        onPressed: _doSearch,
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Cari'),
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
                        title: 'Tidak Ditemukan',
                        description: 'Tidak ada kafe yang cocok dengan pencarian Anda.',
                      ),
                    )
                  else ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_searchResults.length} hasil untuk "${_searchController.text.trim()}"',
                      style: const TextStyle(fontSize: 13, color: sage, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    ..._searchResults.map((cafe) => _buildCafeCard(cafe)),
                  ],
                ],

                const SizedBox(height: 20),

                // ── FILTER BUTTONS ────────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((filter) {
                      final isSelected = selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 9),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (selected) {
                            setState(() => selectedFilter = selected ? filter : null);
                            _onFilterChanged();
                          },
                          selectedColor: darkGreen,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : darkBrown,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: isSelected ? darkGreen : const Color(0xFFDCE4D3)),
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
                              ? 'Kafe "$selectedFilter" di $_locationLabel'
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
                      child: AppLoadingWidget(message: 'Memuat daftar kafe...'),
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
                        title: 'Belum Ada Kafe',
                        description: 'Belum ada kafe yang terdaftar di area ini.',
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

  // ── Cafe Card ──────────────────────────────────────────────────────────
  Widget _buildCafeCard(Cafe cafe) {
    final photoUrl = cafe.photos.isNotEmpty ? cafe.photos[0] : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEAEDE4)),
            boxShadow: [
              BoxShadow(color: darkBrown.withOpacity(0.04), blurRadius: 9, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              // Cafe photo
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _cafePhotoPlaceholder(),
                      )
                    : _cafePhotoPlaceholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cafe.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: darkBrown),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cafe.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: brown),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                        const SizedBox(width: 3),
                        Text(
                          cafe.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkBrown),
                        ),
                        if (cafe.priceRange != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            cafe.priceRange!,
                            style: const TextStyle(fontSize: 11, color: sage, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: sage, size: 25),
            ],
          ),
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
