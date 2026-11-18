import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../cafe_details/screens/cafe_details_screen.dart';
import '../../home/models/cafe.dart';
import '../../home/repositories/cafe_repository.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const cream = Color(0xFFFAF7F0);
  static const lightGreen = Color(0xFFE8EDDF);
  static const sage = Color(0xFF9AAA83);
  static const darkGreen = Color(0xFF52634A);
  static const brown = Color(0xFF795548);
  static const darkBrown = Color(0xFF4E342E);

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<Cafe> _cafes = [];
  // ignore: unused_field
  bool _isLoading = true;
  // ignore: prefer_final_fields
  LatLng _currentCenter = const LatLng(-6.2305, 106.8115); // Senopati, Jakarta

  @override
  void initState() {
    super.initState();
    _loadCafes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCafes([String? search]) async {
    setState(() => _isLoading = true);
    try {
      final list = await CafeRepository.instance.getCafes(search: search);
      if (mounted) {
        setState(() {
          _cafes = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _moveToUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layanan lokasi (GPS) tidak aktif.'),
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
              content: Text('Izin akses lokasi ditolak.'),
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
            content: Text('Izin lokasi ditolak permanen. Buka pengaturan untuk mengaktifkan.'),
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
          content: Text('Gagal mendapatkan lokasi: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  void _showCafePreview(Cafe cafe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEAEDE4)),
            boxShadow: [
              BoxShadow(
                color: darkBrown.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.local_cafe_rounded,
                      color: darkGreen,
                      size: 26,
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkBrown,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          cafe.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: brown),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                        const SizedBox(width: 3),
                        Text(
                          cafe.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: darkBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
                  child: const Text('Lihat Detail Kafe'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = _cafes.where((c) => c.latitude != null && c.longitude != null).map((cafe) {
      return Marker(
        point: LatLng(cafe.latitude!, cafe.longitude!),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => _showCafePreview(cafe),
          child: Container(
            decoration: BoxDecoration(
              color: darkGreen,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: darkBrown.withOpacity(0.25),
                  blurRadius: 6,
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
                        style: TextStyle(
                          fontSize: 13,
                          color: brown,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _searchController,
                        onSubmitted: (val) {
                          _loadCafes(val.trim());
                        },
                        decoration: InputDecoration(
                          hintText: 'Search coffee shops or areas',
                          hintStyle: TextStyle(
                            color: brown.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: darkGreen,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: sage, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadCafes();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 18,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFFE4E8DC),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: sage,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: const Color(0xFFDCE4D3),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentCenter,
                        initialZoom: 14.0,
                        minZoom: 10.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.kopifinder',
                        ),
                        MarkerLayer(markers: markers),
                        const SimpleAttributionWidget(
                          source: Text('© OpenStreetMap contributors'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Location Floating Button
            Positioned(
              right: 28,
              bottom: 28,
              child: FloatingActionButton.small(
                backgroundColor: Colors.white,
                foregroundColor: darkGreen,
                elevation: 3,
                onPressed: _moveToUserLocation,
                tooltip: 'Lokasi Saya',
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
