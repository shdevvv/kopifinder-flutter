import 'package:flutter/material.dart';
import '../../cafe_details/screens/cafe_details_screen.dart';
import '../models/saved_cafe.dart';

class SavedCafesScreen extends StatefulWidget {
  const SavedCafesScreen({super.key});

  @override
  State<SavedCafesScreen> createState() => _SavedCafesScreenState();
}

class _SavedCafesScreenState extends State<SavedCafesScreen> {
  static const cream = Color(0xFFFAF7F0);
  static const lightGreen = Color(0xFFE8EDDF);
  static const sage = Color(0xFF9AAA83);
  static const darkGreen = Color(0xFF52634A);
  static const brown = Color(0xFF795548);
  static const darkBrown = Color(0xFF4E342E);

  @override
  void initState() {
    super.initState();
    SavedCafeStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    SavedCafeStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedCafes = SavedCafeStore.instance.savedCafes;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: darkBrown,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saved Cafes',
          style: TextStyle(
            color: darkBrown,
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
      ),
      body: savedCafes.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: savedCafes.length,
              itemBuilder: (context, index) {
                final cafe = savedCafes[index];
                return _buildCafeCard(cafe);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                size: 65,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No Saved Cafes Yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: darkBrown,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Your favorite cafes will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: brown,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Find your cozy coffee spot ☕',
              style: TextStyle(
                color: sage,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCafeCard(SavedCafe cafe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFEAEDE4),
          ),
          boxShadow: [
            BoxShadow(
              color: darkBrown.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // CAFE IMAGE PLACEHOLDER
            Container(
              width: 90,
              height: 100,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.local_cafe_rounded,
                size: 37,
                color: darkGreen,
              ),
            ),

            const SizedBox(width: 13),

            // CAFE INFORMATION
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CafeDetailsScreen(
                        cafeName: cafe.name,
                        cafeLocation: cafe.location,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cafe.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: darkBrown,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: sage,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            cafe.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: brown,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'View cafe details',
                      style: TextStyle(
                        fontSize: 12,
                        color: darkGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // REMOVE BOOKMARK
            IconButton(
              onPressed: () {
                SavedCafeStore.instance.removeCafe(cafe.name);
              },
              icon: const Icon(
                Icons.bookmark_rounded,
                color: darkGreen,
                size: 25,
              ),
              tooltip: 'Remove from Saved Cafes',
            ),
          ],
        ),
      ),
    );
  }
}
