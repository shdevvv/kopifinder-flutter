import 'package:flutter/material.dart';
import '../../../core/widgets/state_widgets.dart';
import '../models/ai_recommendation_models.dart';
import '../repositories/ai_repository.dart';

// ── Papercut colour palette ──────────────────────────────────────────────────
const Color _bg = Color(0xFFF5F0E8);
const Color _paper = Color(0xFFFFFDF7);
const Color _ink = Color(0xFF2C2416);
const Color _espresso = Color(0xFF3D2B1F);
const Color _sage = Color(0xFF6B7F5E);
const Color _darkSage = Color(0xFF4A5C3E);
const Color _muted = Color(0xFF8C7E72);
const Color _caramel = Color(0xFFBF8C4C);
const Color _cream = Color(0xFFEDE5D0);
const Color _latte = Color(0xFFD4B896);
const Color _chipBg = Color(0xFFE8E0D0);
const Color _chipBorder = Color(0xFFCFC4B0);
const Color _selectedChipBg = Color(0xFF4A5C3E);
const Color _white = Colors.white;

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

  late final AnimationController _resultAnimCtrl;
  late final Animation<double> _resultFade;

  @override
  void initState() {
    super.initState();
    _resultAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _resultFade = CurvedAnimation(
      parent: _resultAnimCtrl,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _resultAnimCtrl.dispose();
    super.dispose();
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────
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
        _resultAnimCtrl.forward(from: 0);
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

  // ── Purpose chips ─────────────────────────────────────────────────────────
  static const _purposes = ['Work', 'Study', 'Aesthetic', 'Pet Friendly'];
  static const _purposeIcons = {
    'Work': Icons.laptop_rounded,
    'Study': Icons.menu_book_rounded,
    'Aesthetic': Icons.auto_awesome_rounded,
    'Pet Friendly': Icons.pets_rounded,
  };

  // ── Price chips ───────────────────────────────────────────────────────────
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

  // ── UI Helpers ─────────────────────────────────────────────────────────────

  Widget _paperChip({
    required String label,
    required bool selected,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _selectedChipBg : _chipBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _darkSage : _chipBorder,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _darkSage.withOpacity(0.3),
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                  ),
                ]
              : [
                  BoxShadow(
                    color: _ink.withOpacity(0.08),
                    offset: const Offset(0, 2),
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
                size: 13,
                color: selected ? _white : _muted,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? _white : _espresso,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Single-row scrollable chip row
  Widget _chipRow({
    required List<String> options,
    required String? selected,
    Map<String, String>? labelMap,
    Map<String, IconData>? iconMap,
    required ValueChanged<String> onSelect,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: options.asMap().entries.map((entry) {
          final i = entry.key;
          final opt = entry.value;
          final label = labelMap?[opt] ?? opt;
          final icon = iconMap?[opt];
          final isSelected = selected == opt;
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 2 : 0, right: 8, bottom: 4, top: 4),
            child: _paperChip(
              label: label,
              selected: isSelected,
              icon: icon,
              onTap: () => setState(() => onSelect(isSelected ? '' : opt)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Hero banner ─────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Stack(
      children: [
        // back layer — torn-paper shadow
        Positioned(
          left: 6,
          top: 6,
          right: -6,
          bottom: -6,
          child: Container(
            decoration: BoxDecoration(
              color: _latte.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        // front layer — main card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _latte, width: 2),
          ),
          child: Stack(
            children: [
              // decorative torn-texture dots
              Positioned(
                right: 10,
                top: 10,
                child: _dotGrid(),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _cream,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _latte),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 11, color: _caramel),
                        SizedBox(width: 5),
                        Text(
                          'AI CAFE FINDER',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _caramel,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Temukan Kafe\nPerfektmu ☕',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _espresso,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 50,
                    height: 3,
                    decoration: BoxDecoration(
                      color: _caramel,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Kasih tahu preferensimu & AI kami akan\npilihkan kafe paling cocok di Jakarta.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _muted,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dotGrid() {
    return SizedBox(
      width: 60,
      height: 60,
      child: GridView.count(
        crossAxisCount: 5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        children: List.generate(
          25,
          (_) => Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: _latte.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _sectionLabel(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _espresso,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: const TextStyle(fontSize: 11, color: _muted),
        ),
      ],
    );
  }

  // ── Section card wrapper ───────────────────────────────────────────────────
  Widget _sectionCard({required Widget child}) {
    return Stack(
      children: [
        Positioned(
          left: 4,
          top: 4,
          right: -4,
          bottom: -4,
          child: Container(
            decoration: BoxDecoration(
              color: _latte.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cream, width: 1.5),
          ),
          child: child,
        ),
      ],
    );
  }

  // ── Result card ────────────────────────────────────────────────────────────
  Widget _buildResultCard(AiCafeRecommendation cafe, int index) {
    final colors = [
      const Color(0xFFE8F0E0),
      const Color(0xFFFFF3E0),
      const Color(0xFFE3EDF8),
      const Color(0xFFF3E8F5),
      const Color(0xFFE8F5E9),
    ];
    final accentColors = [
      _darkSage,
      const Color(0xFFB06A00),
      const Color(0xFF2563AB),
      const Color(0xFF7B3FA0),
      const Color(0xFF2E7D32),
    ];
    final bgColor = colors[index % colors.length];
    final accent = accentColors[index % accentColors.length];

    return FadeTransition(
      opacity: _resultFade,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Stack(
          children: [
            Positioned(
              left: 5,
              top: 5,
              right: -5,
              bottom: -5,
              child: Container(
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // rank circle
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: _white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: _white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
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
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: accent,
                              ),
                            ),
                            if (cafe.area != null && cafe.area!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded,
                                        size: 11, color: _muted),
                                    const SizedBox(width: 3),
                                    Text(
                                      cafe.area!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // match score badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${cafe.matchScore}%',
                          style: const TextStyle(
                            color: _white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (cafe.reason != null && cafe.reason!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accent.withOpacity(0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.format_quote_rounded, size: 14, color: accent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              cafe.reason!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _espresso,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: widget.onOpenMap,
                      icon: const Icon(Icons.map_rounded, size: 15),
                      label: const Text(
                        'Lihat di Peta',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: _white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero
              _buildHero(),
              const SizedBox(height: 24),

              // ── Purpose
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Mau ngapain?', 'Pilih tujuan utama ke kafe'),
                    const SizedBox(height: 12),
                    _chipRow(
                      options: _purposes,
                      selected: selectedPurpose,
                      iconMap: _purposeIcons,
                      onSelect: (v) => selectedPurpose = v.isEmpty ? null : v,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Price
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Budget per orang', 'Harga kopi per gelas'),
                    const SizedBox(height: 12),
                    _chipRow(
                      options: _prices,
                      selected: selectedPrice,
                      labelMap: _priceLabels,
                      onSelect: (v) => selectedPrice = v.isEmpty ? null : v,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Details
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Preferensi tambahan', 'Opsional — ceritain suasana yang kamu mau'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _detailsController,
                      maxLines: 3,
                      style: const TextStyle(
                        color: _espresso,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Contoh: tempat yang tenang, banyak tanaman, indoor, parkir luas...',
                        hintStyle: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                        filled: true,
                        fillColor: _bg,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _chipBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _chipBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _darkSage, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── CTA Button
              GestureDetector(
                onTap: _isLoading ? null : _fetchRecommendations,
                child: Stack(
                  children: [
                    // shadow layer
                    Positioned(
                      left: 5,
                      top: 5,
                      right: -5,
                      bottom: -5,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: _darkSage.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: _darkSage,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _sage, width: 1.5),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: _white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: _white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Cariin Kafe!',
                                    style: TextStyle(
                                      color: _white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: _white,
                                    size: 17,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Results
              if (showResults) ...[
                const SizedBox(height: 32),
                // results header
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _caramel,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Rekomendasi Untukmu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _espresso,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.only(left: 14),
                  child: Text(
                    'Dipilih AI berdasarkan preferensimu',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                ),
                const SizedBox(height: 18),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: AppLoadingWidget(
                      message: 'AI sedang meracik rekomendasi terbaikmu...',
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
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: _sectionCard(
                      child: const Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 40, color: _muted),
                          SizedBox(height: 10),
                          Text(
                            'Belum ada kafe yang cocok',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _espresso,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Coba ubah pilihan tujuan atau budget.',
                            style: TextStyle(fontSize: 12, color: _muted),
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
