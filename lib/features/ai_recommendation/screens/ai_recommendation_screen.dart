import 'package:flutter/material.dart';
import '../../../core/widgets/state_widgets.dart';
import '../models/ai_recommendation_models.dart';
import '../repositories/ai_repository.dart';

// ── 3D Papercut Palette: Warm Cardboard (#CFAC97), Olive/Lime Greens, Cream, Pure White ──
const Color _bgWall = Color(0xFFFAF7F0);         // Unified cream background
const Color _cardCream = Color(0xFFF7F2E9);      // Warm cream inner paper
const Color _whitePaper = Color(0xFFFFFFFF);     // Pure clean white paper
const Color _chocolateDark = Color(0xFF382317);  // Dark milk chocolate text
const Color _chocolateMid = Color(0xFF6B4C38);   // Milk chocolate medium
const Color _chocolateLatte = Color(0xFF9E7C66); // Latte chocolate tone
const Color _chocolateShadow = Color(0xFFAD8C78);// 3D paper shadow layer

// Requested Greens
const Color _greenPrimary = Color(0xFF526B0C);   // #526B0C deep rich olive
const Color _greenVibrant = Color(0xFF8DBA20);   // #8DBA20 vibrant olive lime
const Color _greenLight = Color(0xFFA5C943);     // #A5C943 light lime olive
const Color _greenDarkShadow = Color(0xFF364807);// Bottom drop shelf for green
const Color _greenPaperTint = Color(0xFFF0F6E4); // Soft paper tint for tags
const Color _mutedText = Color(0xFF7A6557);      // Soft readable caption text

class AiRecommendationScreen extends StatefulWidget {
  final VoidCallback onOpenMap;

  const AiRecommendationScreen({
    super.key,
    required this.onOpenMap,
  });

  @override
  State<AiRecommendationScreen> createState() => _AiRecommendationScreenState();
}

class _AiRecommendationScreenState extends State<AiRecommendationScreen>
    with SingleTickerProviderStateMixin {
  String? selectedPurpose;
  String? selectedPrice;
  final TextEditingController _detailsController = TextEditingController();

  bool showResults = false;
  bool _isLoading = false;
  String? _errorMessage;

  List<AiCafeRecommendation> recommendations = [];

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Fetch AI Recommendations ──────────────────────────────────────────────
  Future<void> _fetchRecommendations() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      showResults = true;
      recommendations = [];
    });

    try {
      final recs = await AiRepository.instance.getRecommendations(
        purpose: selectedPurpose ?? 'Work',
        budget: selectedPrice ?? '30k-60k',
        details: _detailsController.text.trim(),
      );

      if (mounted) {
        setState(() {
          recommendations = recs;
          _isLoading = false;
        });
        _animCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  // ── Filter Options ────────────────────────────────────────────────────────
  static const _purposes = ['Work', 'Study', 'Aesthetic', 'Pet Friendly'];
  static const _purposeIcons = {
    'Work': Icons.laptop_mac_rounded,
    'Study': Icons.menu_book_rounded,
    'Aesthetic': Icons.auto_awesome_rounded,
    'Pet Friendly': Icons.pets_rounded,
  };

  static const _prices = [
    '15k-30k',
    '30k-60k',
    '60k-80k',
    'More than 80k',
  ];
  static const _priceLabels = {
    '15k-30k': 'Rp15–30K',
    '30k-60k': 'Rp30–60K',
    '60k-80k': 'Rp60–80K',
    'More than 80k': '>Rp80K',
  };

  // ── 3D Papercut Card Wrapper (Multi-layered Paper) ────────────────────────
  Widget _build3DPaperCard({
    required Widget child,
    Color paperColor = _whitePaper,
    Color shadowLayerColor = _chocolateShadow,
    Color borderColor = const Color(0xFFE2D4C5),
    double elevation = 5.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Bottom paper shadow layer (gives true 3D cutout depth against #CFAC97)
        Positioned(
          left: 4,
          top: elevation,
          right: -4,
          bottom: -elevation,
          child: Container(
            decoration: BoxDecoration(
              color: shadowLayerColor,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        // Top physical paper sheet
        Container(
          width: double.infinity,
          padding: padding,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: paperColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 1.8),
            boxShadow: [
              // Sharp paper cut edge top highlight
              const BoxShadow(
                color: Colors.white,
                offset: Offset(0, -1),
                blurRadius: 0,
              ),
              // Soft ambient drop
              BoxShadow(
                color: _chocolateDark.withOpacity(0.08),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  // ── 3D Papercut Chip ──────────────────────────────────────────────────────
  Widget _build3DChip({
    required String label,
    required bool isSelected,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(right: 10, bottom: 4, top: 2),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Drop paper shadow shelf
            Positioned(
              left: 0,
              right: 0,
              bottom: -3.5,
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected ? _greenDarkShadow : _chocolateShadow,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            // Front paper tile
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _greenPrimary : _whitePaper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? _greenLight : const Color(0xFFE2D6C6),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(isSelected ? 0.25 : 0.9),
                    offset: const Offset(0, -1),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 15,
                      color: isSelected ? _whitePaper : _greenPrimary,
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? _whitePaper : _chocolateDark,
                      letterSpacing: 0.1,
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

  // ── Single Row Horizontal Chip Row ────────────────────────────────────────
  Widget _buildSingleRowChips({
    required List<String> options,
    required String? selectedValue,
    Map<String, String>? labelMap,
    Map<String, IconData>? iconMap,
    required ValueChanged<String> onSelected,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: Row(
        children: options.map((opt) {
          final isSelected = selectedValue == opt;
          final displayLabel = labelMap?[opt] ?? opt;
          final icon = iconMap?[opt];

          return _build3DChip(
            label: displayLabel,
            isSelected: isSelected,
            icon: icon,
            onTap: () {
              onSelected(isSelected ? '' : opt);
              setState(() {});
            },
          );
        }).toList(),
      ),
    );
  }

  // ── 3D Papercraft Hero Banner ─────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 3D paper backing layer in warm milk chocolate
        Positioned(
          left: 5,
          top: 6,
          right: -5,
          bottom: -6,
          child: Container(
            decoration: BoxDecoration(
              color: _chocolateShadow,
              borderRadius: BorderRadius.circular(26),
            ),
          ),
        ),
        // Main hero card in pure white paper
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          decoration: BoxDecoration(
            color: _whitePaper,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFE2D4C5), width: 2),
            boxShadow: [
              BoxShadow(
                color: _chocolateDark.withOpacity(0.08),
                offset: const Offset(0, 8),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Text Content (Expanded left side)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Title
                    const Text(
                      'Discover Your\nPerfect Cafe ☕',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: _chocolateDark,
                        height: 1.2,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Decorative milk-chocolate paper divider line
                    Container(
                      width: 48,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: _greenLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Hero Subtitle
                    const Text(
                      'Tell us your vibe and our AI will hand-pick the finest coffee spots across Jakarta for you.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _mutedText,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Full Round 3D Papercut Medal (Top Right - NOT CLIPPED, 100% round)
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _cardCream,
                  border: Border.all(color: _chocolateShadow, width: 1.8),
                  boxShadow: [
                    // 3D paper bottom shelf
                    BoxShadow(
                      color: _chocolateDark.withOpacity(0.18),
                      offset: const Offset(0, 4),
                      blurRadius: 0,
                    ),
                    // Ambient blur
                    BoxShadow(
                      color: _chocolateDark.withOpacity(0.08),
                      offset: const Offset(0, 6),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _whitePaper,
                      border: Border.all(color: _greenLight, width: 1.8),
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
                        padding: const EdgeInsets.all(5),
                        child: Image.asset(
                          'assets/icon/no_text_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _greenPaperTint,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _greenLight, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: _greenPrimary.withOpacity(0.15),
                offset: const Offset(0, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: _greenPrimary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: _chocolateDark,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 1.5),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                color: _mutedText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 3D Papercraft Result Ticket Card ──────────────────────────────────────
  Widget _buildResultCard(AiCafeRecommendation cafe, int index) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 3D paper ticket drop backing
            Positioned(
              left: 4,
              top: 5,
              right: -4,
              bottom: -5,
              child: Container(
                decoration: BoxDecoration(
                  color: _chocolateShadow,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            // Top White Paper Ticket
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: _whitePaper,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2D4C5), width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: _chocolateDark.withOpacity(0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Rank badge, Cafe name, Area, and Match stamp
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3D paper numbered wax seal / badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _greenPrimary,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _greenVibrant, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: _greenDarkShadow,
                              offset: Offset(0, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: _whitePaper,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cafe.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _chocolateDark,
                              ),
                            ),
                            if (cafe.area != null && cafe.area!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 13,
                                    color: _greenPrimary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    cafe.area!,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: _mutedText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // 3D Match Score Paper Stamp
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _greenPaperTint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _greenPrimary, width: 1.4),
                          boxShadow: [
                            BoxShadow(
                              color: _greenPrimary.withOpacity(0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 11,
                              color: _greenPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${cafe.matchScore}% Match',
                              style: const TextStyle(
                                color: _greenPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // AI Reason Quote box (paper cutout)
                  if (cafe.reason != null && cafe.reason!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                      decoration: BoxDecoration(
                        color: _cardCream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2D4C5), width: 1.2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.format_quote_rounded,
                            size: 16,
                            color: _chocolateMid,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cafe.reason!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _chocolateDark,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Highlights tags
                  if (cafe.highlights.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: cafe.highlights.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: _greenPaperTint,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _greenLight.withOpacity(0.5)),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: _greenPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // 3D "View on Map" Button
                  GestureDetector(
                    onTap: widget.onOpenMap,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Shadow shelf
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: -3,
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: _greenDarkShadow,
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                        // Front face
                        Container(
                          width: double.infinity,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _greenPrimary,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: _greenLight, width: 1.4),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_rounded, size: 16, color: _whitePaper),
                              SizedBox(width: 7),
                              Text(
                                'View on Map',
                                style: TextStyle(
                                  color: _whitePaper,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
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
            ),
          ],
        ),
      ),
    );
  }

  // ── Build Method ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWall,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Hero Banner ────────────────────────────────────────────
              _buildHeroBanner(),

              const SizedBox(height: 20),

              // ── 2. Purpose Card (Single Row Chips) ────────────────────────
              _build3DPaperCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      title: 'What are you up to?',
                      subtitle: 'Select your main cafe purpose',
                      icon: Icons.coffee_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildSingleRowChips(
                      options: _purposes,
                      selectedValue: selectedPurpose,
                      iconMap: _purposeIcons,
                      onSelected: (v) => selectedPurpose = v.isEmpty ? null : v,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 3. Price per cup (Single Row Chips) ───────────────────────
              _build3DPaperCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      title: 'Budget per cup',
                      subtitle: 'Choose your average coffee spend',
                      icon: Icons.payments_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildSingleRowChips(
                      options: _prices,
                      selectedValue: selectedPrice,
                      labelMap: _priceLabels,
                      onSelected: (v) => selectedPrice = v.isEmpty ? null : v,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 4. Extra Preferences ──────────────────────────────────────
              _build3DPaperCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      title: 'Extra Preferences',
                      subtitle: 'Optional — describe your ideal ambience',
                      icon: Icons.edit_note_rounded,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _detailsController,
                      maxLines: 3,
                      style: const TextStyle(
                        color: _chocolateDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'e.g. quiet corner, lush greenery, indoor AC, spacious parking...',
                        hintStyle: TextStyle(
                          color: _mutedText.withOpacity(0.7),
                          fontSize: 12,
                          height: 1.5,
                        ),
                        filled: true,
                        fillColor: _cardCream,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2D6C6), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2D6C6), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _greenPrimary, width: 1.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── 5. Big 3D Papercraft Submit Button ("Find My Cafe! ✦") ─────
              GestureDetector(
                onTap: _isLoading ? null : _fetchRecommendations,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Deep 3D bottom shadow shelf
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -4.5,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: _greenDarkShadow,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    // Front raised 3D emerald-olive block
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: _greenPrimary,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _greenVibrant, width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.25),
                            offset: const Offset(0, -1),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: _whitePaper,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: _whitePaper,
                                    size: 19,
                                  ),
                                  SizedBox(width: 9),
                                  Text(
                                    'Find My Cafe! ✦',
                                    style: TextStyle(
                                      color: _whitePaper,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: _whitePaper,
                                    size: 18,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 6. Results Section ────────────────────────────────────────
              if (showResults) ...[
                const SizedBox(height: 24),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 34),
                    child: AppLoadingWidget(
                      message: 'Crafting your personalized cafe recommendations...',
                    ),
                  )
                else if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: AppErrorWidget(
                      message: _errorMessage!,
                      onRetry: _fetchRecommendations,
                    ),
                  )
                else if (recommendations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: _build3DPaperCard(
                      child: const Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 44,
                            color: _chocolateLatte,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No matching cafes found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _chocolateDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Try adjusting your purpose or budget to find more options.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _mutedText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...recommendations
                      .asMap()
                      .entries
                      .map((e) => _buildResultCard(e.value, e.key)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
