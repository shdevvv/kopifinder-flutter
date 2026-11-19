import 'package:flutter/material.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../cafe_details/screens/cafe_details_screen.dart';
import '../models/saved_cafe.dart';

class SavedCafesScreen extends StatefulWidget {
  const SavedCafesScreen({super.key});

  @override
  State<SavedCafesScreen> createState() => _SavedCafesScreenState();
}

class _SavedCafesScreenState extends State<SavedCafesScreen> {
  // ── 3D Papercut Palette: Olive & Cream & Chocolate ──────────────────────────
  static const Color _bgWall = Color(0xFFFAF7F0);          // Unified #FAF7F0 cream background
  static const Color _bgWallShadow = Color(0xFFD4C1B0);    // Warm paper shelf shadow
  static const Color _cardCream = Color(0xFFF7F2E9);       // Warm cream paper
  static const Color _whitePaper = Color(0xFFFFFFFF);      // Clean white paper
  static const Color _chocolateDark = Color(0xFF382317);   // Dark chocolate text
  static const Color _chocolateMid = Color(0xFF6B4C38);    // Medium chocolate
  static const Color _chocolateShadow = Color(0xFFAD8C78); // Paper shelf shadow
  static const Color _greenVibrant = Color(0xFF8DBA20);    // Vibrant olive lime
  static const Color _greenLight = Color(0xFFA5C943);      // Light lime olive

  @override
  void initState() {
    super.initState();
    SavedCafeStore.instance.addListener(_refresh);
    SavedCafeStore.instance.fetchSavedCafes();
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
    final store = SavedCafeStore.instance;
    final savedCafes = store.savedCafes;

    return Scaffold(
      backgroundColor: _bgWall,
      appBar: AppBar(
        backgroundColor: _bgWall,
        elevation: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -3,
                    child: Container(
                      height: 40,
                      decoration: const BoxDecoration(
                        color: _bgWallShadow,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _whitePaper,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2D4C5), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: _chocolateDark,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        title: const Text(
          'Saved Cafes',
          style: TextStyle(
            color: _chocolateDark,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: _greenVibrant,
        backgroundColor: _whitePaper,
        onRefresh: () => store.fetchSavedCafes(),
        child: store.isLoading && savedCafes.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: AppLoadingWidget(message: 'Loading saved cafes...'),
                ),
              )
            : savedCafes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                    itemCount: savedCafes.length,
                    itemBuilder: (context, index) {
                      final cafe = savedCafes[index];
                      return _buildCafeCard(cafe);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(26),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Bottom shelf
            Positioned(
              left: 5,
              top: 6,
              right: -5,
              bottom: -6,
              child: Container(
                decoration: BoxDecoration(
                  color: _bgWallShadow,
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
            // Front paper sheet
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 3D Bookmark Circle
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: -4,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            color: _chocolateShadow,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: _cardCream,
                          shape: BoxShape.circle,
                          border: Border.all(color: _greenLight, width: 2),
                        ),
                        child: const Icon(
                          Icons.bookmark_border_rounded,
                          size: 46,
                          color: _bgWall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'No Saved Cafes Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _chocolateDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your favorite spots will be kept safe here. Tap the bookmark icon on any cafe to save it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _chocolateMid,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F6E4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _greenLight, width: 1.2),
                    ),
                    child: const Text(
                      'Find your cozy coffee spot ☕',
                      style: TextStyle(
                        color: _bgWall,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCafeCard(SavedCafe cafe) {
    final photoUrl = cafe.photoUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 3D paper bottom shelf
          Positioned(
            left: 4,
            top: 5,
            right: -4,
            bottom: -5,
            child: Container(
              decoration: BoxDecoration(
                color: _bgWallShadow,
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          // Front white paper card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _whitePaper,
              borderRadius: BorderRadius.circular(22),
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
                // CAFE PHOTO WITH 3D PAPERCUT BORDER
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2D4C5), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: (photoUrl != null && photoUrl.isNotEmpty)
                        ? Image.network(
                            photoUrl,
                            width: 86,
                            height: 86,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _placeholderImage(),
                          )
                        : _placeholderImage(),
                  ),
                ),

                const SizedBox(width: 13),

                // CAFE DETAILS
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CafeDetailsScreen(
                            cafeId: cafe.cafeId,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _chocolateDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: _greenVibrant,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                cafe.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _chocolateMid,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F6E4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _greenLight, width: 1),
                              ),
                              child: const Text(
                                'View details →',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _bgWall,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // 3D REMOVE BOOKMARK BUTTON
                GestureDetector(
                  onTap: () {
                    SavedCafeStore.instance.removeCafe(cafe.name);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: -2,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: _chocolateShadow,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _cardCream,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2D4C5), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.bookmark_rounded,
                          color: _bgWall,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 86,
      height: 86,
      color: _cardCream,
      child: const Center(
        child: Icon(
          Icons.local_cafe_rounded,
          size: 32,
          color: _bgWall,
        ),
      ),
    );
  }
}
