import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/navigation/main_navigation.dart';
import '../../home/models/cafe.dart';
import '../../home/repositories/cafe_repository.dart';
import '../../saved_cafes/models/saved_cafe.dart';

class CafeDetailsScreen extends StatefulWidget {
  final String? cafeId;
  final String cafeName;
  final String cafeLocation;
  final Cafe? cafe;

  const CafeDetailsScreen({
    super.key,
    this.cafeId,
    this.cafeName = 'Cafe Name',
    this.cafeLocation = 'Cafe Address, City',
    this.cafe,
  });

  @override
  State<CafeDetailsScreen> createState() => _CafeDetailsScreenState();
}

class _CafeDetailsScreenState extends State<CafeDetailsScreen> {
  // ── 3D Papercut Palette ───────────────────────────────────────────────────
  static const Color _bgCream = Color(0xFFFAF7F0);         // Unified ivory background
  static const Color _cardCream = Color(0xFFF7F2E9);       // Warm cream paper
  static const Color _whitePaper = Color(0xFFFFFFFF);      // Clean white paper
  static const Color _chocolateDark = Color(0xFF382317);   // Dark chocolate text
  static const Color _chocolateMid = Color(0xFF6B4C38);    // Medium chocolate
  static const Color _chocolateShadow = Color(0xFFD4C1B0); // Paper shelf shadow
  static const Color _outlinePaper = Color(0xFFE2D4C5);    // Paper cut edge outline
  static const Color _greenPrimary = Color(0xFF526B0C);    // Deep olive green
  static const Color _greenDarkShadow = Color(0xFF364807); // Bottom drop shelf for green
  static const Color _greenPaperTint = Color(0xFFF0F6E4);  // Soft paper tint

  late String _cafeName;
  late String _cafeLocation;
  late String _cafeId;
  Cafe? _cafeData;

  @override
  void initState() {
    super.initState();
    _cafeName = widget.cafe?.name ?? widget.cafeName;
    _cafeLocation = widget.cafe?.address ?? widget.cafeLocation;
    _cafeId = widget.cafe?.id ?? widget.cafeId ?? 'cafe-1';
    _cafeData = widget.cafe;
    _loadData();
  }

  bool get isSaved => SavedCafeStore.instance.isSaved(_cafeName);

  Future<void> _loadData() async {
    if (_cafeData == null && widget.cafeId != null) {
      try {
        final data = await CafeRepository.instance.getCafeById(_cafeId);
        if (mounted) {
          setState(() {
            _cafeData = data;
            _cafeName = data.name;
            _cafeLocation = data.address;
          });
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = _cafeData?.rating ?? 4.8;
    final hours = _cafeData?.openingHours ?? '08:00 - 22:00';
    final price = _cafeData?.priceRange ?? 'Rp25.000 - Rp60.000';
    final facilities = _cafeData?.facilities.isNotEmpty == true
        ? _cafeData!.facilities
        : ['Free Wi-Fi', 'Air Conditioning', 'Parking', 'Indoor Seating'];
    final photos = _cafeData?.photos ?? [];

    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 3D PAPERCUT CAFE PHOTO HEADER ────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Photo container with rounded bottom edges & subtle border
                  Container(
                    decoration: const BoxDecoration(
                      color: _cardCream,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1F382317),
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: photos.isNotEmpty
                        ? Image.network(
                            photos[0],
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _photoPlaceholder(),
                          )
                        : _photoPlaceholder(),
                  ),

                  // 3D Circular Back Button
                  Positioned(
                    top: 15,
                    left: 15,
                    child: _build3DCircleButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // 3D Circular Bookmark Button
                  Positioned(
                    top: 15,
                    right: 15,
                    child: _build3DCircleButton(
                      icon: isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      iconColor: isSaved ? _greenPrimary : _chocolateDark,
                      onPressed: _toggleBookmark,
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cafeName,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: _chocolateDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: _greenPrimary, size: 18),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _cafeLocation,
                            style: const TextStyle(color: _chocolateMid, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── RATING + OPENING HOURS (side by side in 3D paper cards) ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Rating'),
                              const SizedBox(height: 8),
                              _build3DInfoCard(
                                icon: Icons.star_rounded,
                                iconColor: const Color(0xFFFFB300),
                                title: '${rating.toStringAsFixed(1)} / 5.0',
                                subtitle: 'Visitor rating',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Opening Hours'),
                              const SizedBox(height: 8),
                              _build3DInfoCard(
                                icon: Icons.access_time_rounded,
                                iconColor: _greenPrimary,
                                title: 'Hours',
                                subtitle: hours,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── PRICE RANGE + FACILITIES (side by side in 3D paper cards) ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Price Range'),
                              const SizedBox(height: 8),
                              _build3DInfoCard(
                                icon: Icons.payments_outlined,
                                iconColor: _greenPrimary,
                                title: 'Average',
                                subtitle: price,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Facilities'),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: facilities.take(4).map((fac) {
                                  return _facilityChipSmall(_getFacilityIcon(fac), fac);
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── LOCATION & 3D ACTION BUTTONS ────────────────────────
                    _sectionTitle('Location'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: _greenPrimary, size: 16),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _cafeLocation,
                            style: const TextStyle(color: _chocolateMid, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // 3D "View on Map" button
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              Cafe targetCafe = _cafeData ?? widget.cafe ?? Cafe(
                                id: _cafeId,
                                name: _cafeName,
                                address: _cafeLocation,
                              );

                              if (targetCafe.latitude == null || targetCafe.longitude == null) {
                                try {
                                  final fetched = await CafeRepository.instance.getCafeById(_cafeId);
                                  targetCafe = fetched;
                                } catch (_) {}
                              }

                              if (!mounted) return;
                              MainNavigation.openMapForCafe(context, targetCafe);
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: -3.5,
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: _greenDarkShadow,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: _greenPrimary,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFA5C943), width: 1.5),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.map_outlined, color: Colors.white, size: 19),
                                      SizedBox(width: 8),
                                      Text(
                                        'View on Map',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
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
                        // 3D "Directions" button (English!)
                        Expanded(
                          child: GestureDetector(
                            onTap: _openGoogleMapsRoute,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: -3.5,
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A5BB8),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4285F4),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.directions_rounded, color: Colors.white, size: 19),
                                      SizedBox(width: 8),
                                      Text(
                                        'Directions',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
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
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      height: 250,
      width: double.infinity,
      color: _cardCream,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon/no_text_logo.png', width: 70, height: 70, fit: BoxFit.contain),
            const SizedBox(height: 10),
            const Text('Cafe Photos', style: TextStyle(color: _chocolateDark, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  void _toggleBookmark() {
    final photo = (_cafeData?.photos.isNotEmpty == true)
        ? _cafeData!.photos.first
        : (widget.cafe?.photos.isNotEmpty == true ? widget.cafe!.photos.first : null);

    SavedCafeStore.instance.toggleSaved(
      SavedCafe(
        cafeId: _cafeId,
        name: _cafeName,
        location: _cafeLocation,
        photoUrl: photo,
      ),
    );
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved
              ? 'Saved "${widget.cafeName}" to Saved Cafes!'
              : 'Removed "${widget.cafeName}" from Saved Cafes',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _openGoogleMapsRoute() async {
    final lat = _cafeData?.latitude;
    final lng = _cafeData?.longitude;
    if (lat == null || lng == null) {
      final encodedName = Uri.encodeComponent(_cafeName);
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedName',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return;
    }
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$lat,$lng'
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

  Widget _build3DCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = _chocolateDark,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: -3,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: _chocolateShadow,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _whitePaper,
              shape: BoxShape.circle,
              border: Border.all(color: _outlinePaper, width: 1.5),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _chocolateDark),
    );
  }

  Widget _build3DInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 2,
          top: 3,
          right: -2,
          bottom: -3,
          child: Container(
            decoration: BoxDecoration(
              color: _chocolateShadow,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _whitePaper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _outlinePaper, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.white,
                offset: Offset(0, -1),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor ?? _greenPrimary, size: 22),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: _chocolateDark, fontSize: 13)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: _chocolateMid, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getFacilityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wifi')) return Icons.wifi_rounded;
    if (lower.contains('ac') || lower.contains('air conditioning')) return Icons.ac_unit_rounded;
    if (lower.contains('park')) return Icons.local_parking_rounded;
    if (lower.contains('seat')) return Icons.event_seat_rounded;
    if (lower.contains('pet')) return Icons.pets_rounded;
    if (lower.contains('work')) return Icons.work_outline_rounded;
    if (lower.contains('study')) return Icons.school_outlined;
    if (lower.contains('outdoor')) return Icons.park_outlined;
    return Icons.check_circle_outline_rounded;
  }

  Widget _facilityChipSmall(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _greenPaperTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFA5C943), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _greenPrimary, size: 13),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: _chocolateDark, fontSize: 10.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
