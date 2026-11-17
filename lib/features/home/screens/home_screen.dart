import 'package:flutter/material.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../cafe_details/screens/cafe_details_screen.dart';
import '../../saved_cafes/screens/saved_cafes_screen.dart';
import '../models/cafe.dart';
import '../models/offer.dart';
import '../repositories/cafe_repository.dart';
import '../repositories/offer_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const cream = Color(0xFFFAF7F0);
  static const lightGreen = Color(0xFFE8EDDF);
  static const sage = Color(0xFF9AAA83);
  static const darkGreen = Color(0xFF52634A);
  static const brown = Color(0xFF795548);
  static const darkBrown = Color(0xFF4E342E);

  String? selectedFilter;
  final TextEditingController _searchController = TextEditingController();

  final List<String> filters = [
    'Work',
    'Study',
    'Aesthetic',
    'Pet Friendly',
  ];

  List<Cafe> _cafes = [];
  List<Offer> _offers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        CafeRepository.instance.getCafes(
          search: _searchController.text.trim(),
          tag: selectedFilter,
        ),
        OfferRepository.instance.getOffers(),
      ]);

      if (mounted) {
        setState(() {
          _cafes = results[0] as List<Cafe>;
          _offers = results[1] as List<Offer>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onSearchOrFilterChanged() async {
    setState(() => _isLoading = true);
    try {
      final cafes = await CafeRepository.instance.getCafes(
        search: _searchController.text.trim(),
        tag: selectedFilter,
      );
      if (mounted) {
        setState(() {
          _cafes = cafes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatRupiah(int price) {
    final s = price.toString();
    final buffer = StringBuffer('Rp');
    final start = s.length % 3;
    if (start > 0) buffer.write(s.substring(0, start));
    for (int i = start; i < s.length; i += 3) {
      if (i > 0) buffer.write('.');
      buffer.write(s.substring(i, i + 3));
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final activeOffer = _offers.isNotEmpty ? _offers.first : null;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: RefreshIndicator(
          color: darkGreen,
          backgroundColor: cream,
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LOCATION AND BOOKMARK
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: lightGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFDCE4D3),
                        ),
                      ),
                      child: const Icon(
                        Icons.coffee_rounded,
                        color: darkGreen,
                        size: 25,
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR LOCATION',
                            style: TextStyle(
                              fontSize: 11,
                              color: sage,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: darkGreen,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Senopati, Jakarta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: darkBrown,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // SAVED CAFES BUTTON
                    Container(
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SavedCafesScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.bookmark_border_rounded,
                          color: darkGreen,
                          size: 25,
                        ),
                        tooltip: 'Saved Cafes',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // SEARCH BAR
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _onSearchOrFilterChanged(),
                  decoration: InputDecoration(
                    hintText: 'Find a coffee shop',
                    hintStyle: TextStyle(
                      color: brown.withOpacity(0.55),
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
                              _onSearchOrFilterChanged();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
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

                const SizedBox(height: 20),

                // FILTER BUTTONS
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((filter) {
                      final isSelected = selectedFilter == filter;

                      return Padding(
                        padding: const EdgeInsets.only(right: 9),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (selected) {
                            setState(() {
                              selectedFilter = selected ? filter : null;
                            });
                            _onSearchOrFilterChanged();
                          },
                          selectedColor: darkGreen,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : darkBrown,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? darkGreen
                                  : const Color(0xFFDCE4D3),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 28),

                // SPECIAL OFFERS
                if (activeOffer != null) ...[
                  const Row(
                    children: [
                      Icon(
                        Icons.local_offer_rounded,
                        color: darkGreen,
                        size: 21,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Special Offers',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: darkBrown,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 13),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFDCE4D3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeOffer.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: darkBrown,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: darkGreen,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${activeOffer.discountPercentage}% OFF',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _formatRupiah(activeOffer.originalPrice),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: brown.withOpacity(0.7),
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _formatRupiah(activeOffer.discountedPrice),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: darkBrown,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                activeOffer.cafeName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: darkGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        Container(
                          width: 105,
                          height: 105,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCE4D3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.coffee_rounded,
                            color: sage,
                            size: 42,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                ],

                // POPULAR CAFES
                const Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: brown,
                      size: 21,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Popular Near You',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: darkBrown,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: AppLoadingWidget(message: 'Memuat daftar kafe...'),
                  )
                else if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: AppErrorWidget(
                      message: _errorMessage!,
                      onRetry: _loadData,
                    ),
                  )
                else if (_cafes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: AppEmptyWidget(
                      icon: Icons.search_off_rounded,
                      title: 'Tidak Ada Kafe',
                      description: 'Tidak ada kafe yang cocok dengan kata kunci atau filter Anda.',
                    ),
                  )
                else
                  ..._cafes.map((cafe) => _buildCafeCard(cafe)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // CAFE LIST ITEM
  Widget _buildCafeCard(Cafe cafe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
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
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEAEDE4),
            ),
            boxShadow: [
              BoxShadow(
                color: darkBrown.withOpacity(0.04),
                blurRadius: 9,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.local_cafe_rounded,
                  color: darkGreen,
                  size: 30,
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
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: darkBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cafe.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: brown,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                        const SizedBox(width: 3),
                        Text(
                          cafe.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: darkBrown,
                          ),
                        ),
                        if (cafe.priceRange != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            cafe.priceRange!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: sage,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: sage,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
