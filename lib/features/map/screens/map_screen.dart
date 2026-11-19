import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../cafe_details/screens/cafe_details_screen.dart';
import '../../home/models/cafe.dart';
import '../../home/repositories/cafe_repository.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // ── 3D Papercut Palette: Requested #A5C943 Background & Olive/Chocolate Accents ──
  static const Color _bgWall = Color(0xFFFAF7F0);          // Unified #FAF7F0 cream background
  static const Color _bgWallShadow = Color(0xFFD4C1B0);    // Warm paper shelf shadow
  static const Color _cardCream = Color(0xFFF7F2E9);       // Warm cream paper
  static const Color _whitePaper = Color(0xFFFFFFFF);      // Clean white paper
  static const Color _chocolateDark = Color(0xFF382317);   // Dark chocolate text
  static const Color _chocolateMid = Color(0xFF6B4C38);    // Medium chocolate
  static const Color _greenPrimary = Color(0xFF526B0C);    // Deep olive
  static const Color _greenDarkShadow = Color(0xFF364807); // Bottom drop shelf for green

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<Cafe> _cafes = [];
  List<Cafe> _searchResults = [];
  bool _isLoading = true;
  bool _showSuggestions = false;
  final LatLng _defaultCenter = const LatLng(-6.2305, 106.8115); // Senopati

  @override
  void initState() {
    super.initState();
    _loadCafes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // ── Data Loading ──────────────────────────────────────────────────────
  Future<void> _loadCafes() async {
    setState(() => _isLoading = true);
    try {
      final list = await CafeRepository.instance.getCafes();
      if (mounted) {
        setState(() {
          _cafes = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Search Logic ──────────────────────────────────────────────────────
  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
      });
      return;
    }

    final results = _cafes.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.address.toLowerCase().contains(query) ||
          c.area.toLowerCase().contains(query);
    }).toList();

    setState(() {
      _searchResults = results;
      _showSuggestions = true;
    });
  }

  void _selectCafe(Cafe cafe) {
    _searchController.text = cafe.name;
    setState(() => _showSuggestions = false);
    FocusScope.of(context).unfocus();

    if (cafe.latitude != null && cafe.longitude != null) {
      _mapController.move(LatLng(cafe.latitude!, cafe.longitude!), 17.0);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _showCafePreview(cafe);
      });
    }
  }

  void _onSearchSubmitted(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return;

    setState(() => _showSuggestions = false);
    FocusScope.of(context).unfocus();

    final match = _cafes.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.address.toLowerCase().contains(query);
    }).toList();

    if (match.isNotEmpty) {
      final cafe = match.first;
      _searchController.text = cafe.name;
      if (cafe.latitude != null && cafe.longitude != null) {
        _mapController.move(LatLng(cafe.latitude!, cafe.longitude!), 17.0);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _showCafePreview(cafe);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No cafe found for "$value"'),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _showSuggestions = false;
    });
    FocusScope.of(context).unfocus();
  }

  // ── Open Google Maps for Route ────────────────────────────────────────
  Future<void> _openGoogleMapsRoute(Cafe cafe) async {
    if (cafe.latitude == null || cafe.longitude == null) return;
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${cafe.latitude},${cafe.longitude}'
      '&destination_place_id='
      '&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }

  // ── Geolocation ───────────────────────────────────────────────────────
  Future<void> _moveToUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location service (GPS) is disabled.'),
            backgroundColor: Color(0xFFD32F2F),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied.'),
              backgroundColor: Color(0xFFD32F2F),
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied. Enable it in settings.'),
            backgroundColor: Color(0xFFD32F2F),
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final userLatLng = LatLng(pos.latitude, pos.longitude);
      _mapController.move(userLatLng, 15.5);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  // ── 3D Papercut Cafe Preview Bottom Sheet ─────────────────────────────
  void _showCafePreview(Cafe cafe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bottom paper shadow shelf
              Positioned(
                left: 4,
                top: 6,
                right: -4,
                bottom: -6,
                child: Container(
                  decoration: BoxDecoration(
                    color: _chocolateDark.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
              // Front paper sheet
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _whitePaper,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE2D4C5), width: 1.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(0, -1),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8C7B5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // Cafe 3D icon
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: _cardCream,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _bgWall, width: 1.8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.local_cafe_rounded,
                              color: _greenPrimary,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cafe.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: _chocolateDark,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: _greenPrimary, size: 14),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      cafe.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: _chocolateMid),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 3D Rating badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                              const SizedBox(width: 3),
                              Text(
                                cafe.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: _chocolateDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (cafe.priceRange != null || cafe.openingHours != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          if (cafe.priceRange != null) ...[
                            const Icon(Icons.payments_outlined, color: _greenPrimary, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              cafe.priceRange!,
                              style: const TextStyle(fontSize: 12, color: _chocolateMid, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (cafe.openingHours != null) ...[
                            const Icon(Icons.access_time_rounded, color: _greenPrimary, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              cafe.openingHours!,
                              style: const TextStyle(fontSize: 12, color: _chocolateMid, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    // Action Buttons — 3D Papercut View Details + Directions
                    Row(
                      children: [
                        // View Details 3D button
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CafeDetailsScreen(
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
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: -3,
                                  child: Container(
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: _greenDarkShadow,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: _greenPrimary,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: _bgWall, width: 1.5),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 17, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text(
                                        'View Details',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Directions 3D button
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _openGoogleMapsRoute(cafe);
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: -3,
                                  child: Container(
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A5BB8),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4285F4),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.directions_rounded, size: 17, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text(
                                        'Directions',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final markers = _cafes
        .where((c) => c.latitude != null && c.longitude != null)
        .map((cafe) {
      return Marker(
        point: LatLng(cafe.latitude!, cafe.longitude!),
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () => _showCafePreview(cafe),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: -2,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: _greenDarkShadow,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _greenPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.coffee_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Scaffold(
      backgroundColor: _bgWall,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 3D Papercut Header & Search ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Explore Map 🗺️',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _chocolateDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Find your next cozy coffee spot across Jakarta',
                        style: TextStyle(
                          fontSize: 12,
                          color: _chocolateDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3D Papercut Search Field
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: -3,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: _bgWallShadow,
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: _whitePaper,
                              borderRadius: BorderRadius.circular(18),
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
                              onSubmitted: _onSearchSubmitted,
                              style: const TextStyle(
                                fontSize: 14,
                                color: _chocolateDark,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search coffee shop name...',
                                hintStyle: TextStyle(
                                  color: _chocolateMid.withOpacity(0.6),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: const Icon(Icons.search_rounded, color: _greenPrimary, size: 21),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, color: _chocolateMid, size: 18),
                                        onPressed: _clearSearch,
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── 3D Framed Map Viewport ──────────────────────────────────────
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Map 3D bottom shelf
                        Positioned(
                          left: 4,
                          top: 5,
                          right: -4,
                          bottom: -5,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _bgWallShadow,
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                        ),
                        // Framed map paper cutout
                        Container(
                          decoration: BoxDecoration(
                            color: _whitePaper,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: const Color(0xFFE2D4C5), width: 2.2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _defaultCenter,
                              initialZoom: 14.0,
                              minZoom: 10.0,
                              maxZoom: 18.0,
                              onTap: (_, __) {
                                setState(() => _showSuggestions = false);
                                FocusScope.of(context).unfocus();
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.kopifinder.app',
                                maxZoom: 19,
                              ),
                              MarkerLayer(markers: markers),
                              RichAttributionWidget(
                                alignment: AttributionAlignment.bottomLeft,
                                attributions: [
                                  TextSourceAttribution(
                                    '© OpenStreetMap contributors',
                                    onTap: () {},
                                  ),
                                  TextSourceAttribution(
                                    '© CARTO',
                                    onTap: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Search Suggestions Dropdown ────────────────────────────
            if (_showSuggestions && _searchResults.isNotEmpty)
              Positioned(
                top: 135,
                left: 18,
                right: 18,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    color: _whitePaper,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2D4C5), width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: _chocolateDark.withOpacity(0.18),
                        offset: const Offset(0, 6),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 56,
                      color: Color(0xFFF0EBE3),
                    ),
                    itemBuilder: (context, index) {
                      final cafe = _searchResults[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _cardCream,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _bgWall, width: 1),
                          ),
                          child: const Icon(Icons.local_cafe_rounded, color: _greenPrimary, size: 20),
                        ),
                        title: Text(
                          cafe.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _chocolateDark,
                          ),
                        ),
                        subtitle: Text(
                          cafe.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: _chocolateMid),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 14),
                            const SizedBox(width: 2),
                            Text(
                              cafe.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _chocolateDark,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _selectCafe(cafe),
                      );
                    },
                  ),
                ),
              ),

            // ── 3D Papercut Location FAB ────────────────────────────────────────────
            Positioned(
              right: 26,
              bottom: 26,
              child: GestureDetector(
                onTap: _moveToUserLocation,
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
                        decoration: const BoxDecoration(
                          color: _bgWallShadow,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _whitePaper,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2D4C5), width: 1.8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.white,
                            offset: Offset(0, -1),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.my_location_rounded,
                          color: _greenPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Loading Overlay ─────────────────────────────────────────
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: _bgWall.withOpacity(0.4),
                  child: const Center(
                    child: CircularProgressIndicator(color: _greenPrimary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
