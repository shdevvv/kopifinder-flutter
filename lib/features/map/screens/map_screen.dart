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
  // ── Theme Colors ──────────────────────────────────────────────────────
  static const cream = Color(0xFFFAF7F0);
  static const lightGreen = Color(0xFFE8EDDF);
  static const sage = Color(0xFF9AAA83);
  static const darkGreen = Color(0xFF52634A);
  static const brown = Color(0xFF795548);
  static const darkBrown = Color(0xFF4E342E);

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
      // Show preview after a short delay so animation finishes
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

    // Find exact or best match
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
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          backgroundColor: Colors.redAccent,
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
            content: Text(
                'Location permission permanently denied. Enable it in settings.'),
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

  // ── Cafe Preview Bottom Sheet ─────────────────────────────────────────
  void _showCafePreview(Cafe cafe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEAEDE4)),
            boxShadow: [
              BoxShadow(
                color: darkBrown.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
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
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  // Cafe icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [darkGreen, sage],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: darkGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_cafe_rounded,
                      color: Colors.white,
                      size: 28,
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
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: darkBrown,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: sage, size: 14),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                cafe.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: brown),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Rating badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFB300), size: 16),
                        const SizedBox(width: 3),
                        Text(
                          cafe.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: darkBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Extra info row
              if (cafe.priceRange != null || cafe.openingHours != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (cafe.priceRange != null) ...[
                      const Icon(Icons.payments_outlined,
                          color: sage, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        cafe.priceRange!,
                        style: const TextStyle(fontSize: 11, color: brown),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (cafe.openingHours != null) ...[
                      const Icon(Icons.access_time_rounded,
                          color: sage, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        cafe.openingHours!,
                        style: const TextStyle(fontSize: 11, color: brown),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 18),
              // Action Buttons — View Details + Route to Google Maps
              Row(
                children: [
                  // View Details button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.info_outline_rounded, size: 18),
                        label: const Text('Detail',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: () {
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Route (Google Maps) button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4285F4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.directions_rounded, size: 18),
                        label: const Text('Rute',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: () {
                          Navigator.pop(context);
                          _openGoogleMapsRoute(cafe);
                        },
                      ),
                    ),
                  ),
                ],
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
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [darkGreen, Color(0xFF6B8F5E)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: darkBrown.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.coffee_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      );
    }).toList();

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header & Search ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Explore Map',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: darkBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Find your next cozy coffee spot ☕',
                        style: TextStyle(fontSize: 13, color: brown),
                      ),
                      const SizedBox(height: 14),
                      // Search Field
                      TextField(
                        controller: _searchController,
                        onSubmitted: _onSearchSubmitted,
                        decoration: InputDecoration(
                          hintText: 'Search coffee shop name...',
                          hintStyle: TextStyle(
                            color: brown.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: darkGreen),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      color: sage, size: 20),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 18),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                const BorderSide(color: Color(0xFFE4E8DC)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                const BorderSide(color: sage, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Map ──────────────────────────────────────────────
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFFDCE4D3)),
                      boxShadow: [
                        BoxShadow(
                          color: darkBrown.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                        // ── Clean, crisp map tiles (CartoDB Voyager) ──
                        TileLayer(
                          urlTemplate:
                              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.example.kopifinder',
                          maxZoom: 20,
                          // High-DPI @2x tiles for sharp rendering
                          retinaMode: true,
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
                ),
              ],
            ),

            // ── Search Suggestions Dropdown ────────────────────────────
            if (_showSuggestions && _searchResults.isNotEmpty)
              Positioned(
                top: 140,
                left: 20,
                right: 20,
                child: Material(
                  elevation: 6,
                  shadowColor: darkBrown.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4E8DC)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 56,
                          color: Color(0xFFF0F2EC)),
                      itemBuilder: (context, index) {
                        final cafe = _searchResults[index];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 2),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: lightGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.local_cafe_rounded,
                                color: darkGreen, size: 20),
                          ),
                          title: Text(
                            cafe.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: darkBrown,
                            ),
                          ),
                          subtitle: Text(
                            cafe.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: brown),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFB300), size: 14),
                              const SizedBox(width: 2),
                              Text(
                                cafe.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: darkBrown),
                              ),
                            ],
                          ),
                          onTap: () => _selectCafe(cafe),
                        );
                      },
                    ),
                  ),
                ),
              ),

            // ── Location FAB ────────────────────────────────────────────
            Positioned(
              right: 28,
              bottom: 28,
              child: FloatingActionButton.small(
                backgroundColor: Colors.white,
                foregroundColor: darkGreen,
                elevation: 4,
                onPressed: _moveToUserLocation,
                tooltip: 'My Location',
                child: const Icon(Icons.my_location_rounded),
              ),
            ),

            // ── Loading Overlay ─────────────────────────────────────────
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: cream.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(color: darkGreen),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
