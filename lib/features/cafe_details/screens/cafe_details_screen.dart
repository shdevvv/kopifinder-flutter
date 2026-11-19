import 'package:flutter/material.dart';
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
  static const cream = Color(0xFFFAF7F0);
  static const lightGreen = Color(0xFFE8EDDF);
  static const sage = Color(0xFF9AAA83);
  static const darkGreen = Color(0xFF52634A);
  static const brown = Color(0xFF795548);
  static const darkBrown = Color(0xFF4E342E);

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
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cafe Photo Header
              Stack(
                children: [
                  // SHOW REAL PHOTO if available, else green placeholder
                  if (photos.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      child: Image.network(
                        photos[0],
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _photoPlaceholder(),
                      ),
                    )
                  else
                    _photoPlaceholder(),
                  Positioned(
                    top: 15,
                    left: 15,
                    child: _circleButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: _circleButton(
                      icon: isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      onPressed: _toggleBookmark,
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cafeName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: darkBrown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: sage, size: 19),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _cafeLocation,
                            style: const TextStyle(color: brown, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // RATING + OPENING HOURS side by side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Rating'),
                              const SizedBox(height: 8),
                              _compactInfoCard(
                                icon: Icons.star_rounded,
                                title: '${rating.toStringAsFixed(1)} / 5.0',
                                subtitle: 'Ulasan pengunjung',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Jam Buka'),
                              const SizedBox(height: 8),
                              _compactInfoCard(
                                icon: Icons.access_time_rounded,
                                title: 'Operasional',
                                subtitle: hours,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // PRICE RANGE + FACILITIES side by side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Harga'),
                              const SizedBox(height: 8),
                              _compactInfoCard(
                                icon: Icons.payments_outlined,
                                title: 'Kisaran',
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
                              _sectionTitle('Fasilitas'),
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

                    const SizedBox(height: 25),

                    // LOCATION: NO GREEN BOX, just address + View on Map button
                    _sectionTitle('Lokasi'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: sage, size: 17),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _cafeLocation,
                            style: const TextStyle(color: brown, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('View on Map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
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
      decoration: const BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/new_app_icon.png', width: 70, height: 70, fit: BoxFit.contain),
            const SizedBox(height: 10),
            const Text('Cafe Photos', style: TextStyle(color: darkBrown, fontWeight: FontWeight.w600)),
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
              ? '$_cafeName ditambahkan ke Saved Cafes'
              : '$_cafeName dihapus dari Saved Cafes',
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: darkBrown.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: darkBrown),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBrown),
    );
  }

  Widget _compactInfoCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEDE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: darkGreen, size: 20),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: darkBrown, fontSize: 12)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: brown), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE4D3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: darkGreen, size: 13),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: darkBrown, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
