import 'package:flutter/material.dart';
import '../../saved_cafes/models/saved_cafe.dart';

class CafeDetailsScreen extends StatefulWidget {
  final String cafeName;
  final String cafeLocation;

  const CafeDetailsScreen({
    super.key,
    this.cafeName = 'Cafe Name',
    this.cafeLocation = 'Cafe Address, City',
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

  bool get isSaved => SavedCafeStore.instance.isSaved(widget.cafeName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cafe Photo
              Stack(
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_cafe_rounded,
                          size: 65,
                          color: darkGreen,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Cafe Photos',
                          style: TextStyle(
                            color: darkBrown,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      widget.cafeName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: darkBrown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: sage,
                          size: 19,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            widget.cafeLocation,
                            style: const TextStyle(
                              color: brown,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    _sectionTitle('Google Rating'),
                    const SizedBox(height: 10),
                    _infoCard(
                      icon: Icons.star_rounded,
                      title: 'Google Rating',
                      subtitle: 'Google rating will appear here',
                    ),
                    const SizedBox(height: 25),
                    _sectionTitle('Opening Hours'),
                    const SizedBox(height: 10),
                    _infoCard(
                      icon: Icons.access_time_rounded,
                      title: 'Opening Hours',
                      subtitle: 'Operating hours will appear here',
                    ),
                    const SizedBox(height: 25),
                    _sectionTitle('Price Range'),
                    const SizedBox(height: 10),
                    _infoCard(
                      icon: Icons.payments_outlined,
                      title: 'Average Price',
                      subtitle: 'Price range will appear here',
                    ),
                    const SizedBox(height: 25),
                    _sectionTitle('Facilities'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _facilityChip(
                          Icons.wifi_rounded,
                          'Free Wi-Fi',
                        ),
                        _facilityChip(
                          Icons.ac_unit_rounded,
                          'Air Conditioning',
                        ),
                        _facilityChip(
                          Icons.local_parking_rounded,
                          'Parking',
                        ),
                        _facilityChip(
                          Icons.event_seat_rounded,
                          'Indoor Seating',
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    _sectionTitle('Menu & Prices'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: _sectionDecoration(),
                      child: const Text(
                        'Cafe menu and prices will appear here.',
                        style: TextStyle(
                          color: brown,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    _sectionTitle('Location'),
                    const SizedBox(height: 10),
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: darkGreen,
                            size: 45,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Cafe Location',
                            style: TextStyle(
                              color: darkBrown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.cafeLocation,
                      style: const TextStyle(
                        color: brown,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'View on Map belum dihubungkan.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.map_outlined,
                        ),
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

  void _toggleBookmark() {
    SavedCafeStore.instance.toggleSaved(
      SavedCafe(
        name: widget.cafeName,
        location: widget.cafeLocation,
      ),
    );

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved
              ? '${widget.cafeName} added to Saved Cafes'
              : '${widget.cafeName} removed from Saved Cafes',
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: darkBrown.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: darkBrown,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: darkBrown,
      ),
    );
  }

  BoxDecoration _sectionDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: const Color(0xFFEAEDE4),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: _sectionDecoration(),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: darkGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkBrown,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: brown,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _facilityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDCE4D3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: darkGreen,
            size: 18,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: darkBrown,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
