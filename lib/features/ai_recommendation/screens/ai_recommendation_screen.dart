import 'package:flutter/material.dart';

const Color cream = Color(0xFFFAF7F0);
const Color espresso = Color(0xFF49372D);
const Color sage = Color(0xFF87977A);
const Color olive = Color(0xFF52664C);
const Color lightSage = Color(0xFFE7E9DF);
const Color mutedText = Color(0xFF85776B);
const Color caramel = Color(0xFFC18B5A);
const Color lightCaramel = Color(0xFFE8CBA8);
const Color latte = Color(0xFFF1DEC5);
const Color darkCaramel = Color(0xFF986B43);

class AiRecommendationScreen extends StatefulWidget {
  final VoidCallback onOpenMap;

  const AiRecommendationScreen({
    super.key,
    required this.onOpenMap,
  });

  @override
  State<AiRecommendationScreen> createState() => _AiRecommendationScreenState();
}

class _AiRecommendationScreenState extends State<AiRecommendationScreen> {
  String? selectedPurpose;
  String? selectedPrice;

  final TextEditingController _detailsController = TextEditingController();

  bool showResults = false;

  final List<Map<String, dynamic>> recommendations = [
    {'name': 'First Coffee', 'match': 98},
    {'name': 'Daily Brew', 'match': 94},
    {'name': 'The Coffee Room', 'match': 89},
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  BoxDecoration get softCardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFEAE5D9),
        ),
        boxShadow: [
          BoxShadow(
            color: espresso.withOpacity(0.08),
            blurRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: espresso.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      );

  Widget _buildSectionTitle(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: lightSage,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: olive.withOpacity(0.15),
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: olive,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: espresso,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilter({
    required List<String> options,
    required String? selectedValue,
    required Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 9,
      runSpacing: 11,
      children: options.map((option) {
        final isSelected = selectedValue == option;

        return GestureDetector(
          onTap: () {
            setState(() {
              onSelected(isSelected ? '' : option);
              showResults = false;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: isSelected ? olive : cream,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? olive : const Color(0xFFE3DED3),
              ),
              boxShadow: [
                BoxShadow(
                  color: espresso.withOpacity(0.07),
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : espresso,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendationCard(
    Map<String, dynamic> cafe,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 17),
      padding: const EdgeInsets.all(15),
      decoration: softCardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: lightSage,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: olive.withOpacity(0.18),
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_cafe_rounded,
                  color: olive,
                  size: 42,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: latte,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: darkCaramel,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${cafe['match']}% Match',
                            style: const TextStyle(
                              color: darkCaramel,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cafe['name'],
                      style: const TextStyle(
                        color: espresso,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'A cozy coffee spot for you',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: widget.onOpenMap,
              icon: const Icon(
                Icons.map_rounded,
                size: 18,
              ),
              label: const Text(
                'View on Map',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: olive,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE8CBA8),
            Color(0xFFD7B58D),
            Color(0xFFC6B994),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE5D0B3),
        ),
        boxShadow: [
          BoxShadow(
            color: darkCaramel.withOpacity(0.25),
            offset: const Offset(0, 7),
            blurRadius: 0,
          ),
          BoxShadow(
            color: espresso.withOpacity(0.07),
            offset: const Offset(0, 12),
            blurRadius: 18,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -12,
            child: Icon(
              Icons.coffee_rounded,
              size: 125,
              color: Colors.white.withOpacity(0.24),
            ),
          ),
          Positioned(
            right: 25,
            bottom: -15,
            child: Icon(
              Icons.eco_rounded,
              size: 65,
              color: olive.withOpacity(0.16),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '✦ YOUR PERSONAL CAFE GUIDE',
                  style: TextStyle(
                    color: olive,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              const Text(
                'Find Your\nCoffee Happy Place!',
                style: TextStyle(
                  color: espresso,
                  fontSize: 25,
                  height: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Let us find a cafe that feels just right for you.',
                style: TextStyle(
                  color: Color(0xFF655344),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: darkCaramel,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Made for your coffee moments',
                    style: TextStyle(
                      color: espresso,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(),
              const SizedBox(height: 30),
              const Text(
                'Let’s get to know your taste!',
                style: TextStyle(
                  color: espresso,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tell us what kind of cafe you are looking for.',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 23),
              _buildSectionTitle(
                'Purpose',
                'What will you do at the cafe?',
                Icons.favorite_rounded,
              ),
              const SizedBox(height: 15),
              _buildFilter(
                options: [
                  'Work',
                  'Study',
                  'Aesthetic',
                  'Pet Friendly',
                ],
                selectedValue: selectedPurpose,
                onSelected: (value) {
                  selectedPurpose = value.isEmpty ? null : value;
                },
              ),
              const SizedBox(height: 28),
              _buildSectionTitle(
                'Price per cup',
                'Choose your coffee budget.',
                Icons.payments_rounded,
              ),
              const SizedBox(height: 15),
              _buildFilter(
                options: [
                  'Rp30–60K',
                  'Rp60–80K',
                  'More than Rp80K',
                ],
                selectedValue: selectedPrice,
                onSelected: (value) {
                  selectedPrice = value.isEmpty ? null : value;
                },
              ),
              const SizedBox(height: 28),
              _buildSectionTitle(
                'Anything specific?',
                'Tell us a little more about your ideal cafe.',
                Icons.chat_bubble_rounded,
              ),
              const SizedBox(height: 15),
              Container(
                decoration: softCardDecoration,
                child: TextField(
                  controller: _detailsController,
                  maxLines: 3,
                  style: const TextStyle(
                    color: espresso,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'A quiet place, lots of greenery, cozy interior...',
                    hintStyle: const TextStyle(
                      color: Color(0xFFB0A69B),
                      fontSize: 12,
                      height: 1.5,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(17),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(23),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(23),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(23),
                      borderSide: const BorderSide(
                        color: sage,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 57,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showResults = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: olive,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Find My Cafe',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              if (showResults) ...[
                const SizedBox(height: 35),
                const Text(
                  'Your Cafe Matches ✨',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: espresso,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Here are cafes that match your preferences.',
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedText,
                  ),
                ),
                const SizedBox(height: 19),
                ...recommendations.map(
                  (cafe) => _buildRecommendationCard(cafe),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
