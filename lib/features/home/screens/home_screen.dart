import 'package:flutter/material.dart';
import '../../cafe_details/screens/cafe_details_screen.dart';
import '../../saved_cafes/screens/saved_cafes_screen.dart';

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

  final List<String> filters = [
    'Work',
    'Study',
    'Aesthetic',
    'Pet Friendly',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
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
                          const Text(
                            'Product name',
                            style: TextStyle(
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
                            child: const Text(
                              'XX% OFF',
                              style: TextStyle(
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
                                  'RpXX.XXX',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: brown.withOpacity(0.7),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text(
                                  'RpXX.XXX',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: darkBrown,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Cafe name',
                            style: TextStyle(
                              fontSize: 13,
                              color: darkGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // EMPTY PRODUCT IMAGE
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

              _buildCafe('First Coffee'),
              _buildCafe('Daily Brew'),
              _buildCafe('The Coffee Room'),
            ],
          ),
        ),
      ),
    );
  }

  // CAFE LIST ITEM
  Widget _buildCafe(String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CafeDetailsScreen(
                cafeName: name,
                cafeLocation: 'Senopati, Jakarta',
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(11),
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
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: darkBrown,
                  ),
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
