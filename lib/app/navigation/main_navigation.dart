import 'package:flutter/material.dart';

import '../../features/home/models/cafe.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/ai_recommendation/screens/ai_recommendation_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  static final GlobalKey<MainNavigationState> navKey = GlobalKey<MainNavigationState>();

  static MainNavigationState? of(BuildContext context) {
    return navKey.currentState ?? context.findAncestorStateOfType<MainNavigationState>();
  }

  static void openMapForCafe(BuildContext context, Cafe cafe) {
    final state = of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (state != null) {
      state.openMapWithCafe(cafe);
    }
  }

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();
  final GlobalKey<CommunityScreenState> _communityKey = GlobalKey<CommunityScreenState>();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();

  int get currentIndex => _currentIndex;

  void setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openMap() {
    setState(() {
      _currentIndex = 1;
    });
  }

  void openMapWithCafe(Cafe cafe) {
    setState(() {
      _currentIndex = 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapKey.currentState?.focusCafe(cafe);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      MapScreen(key: _mapKey),
      AiRecommendationScreen(onOpenMap: _openMap),
      CommunityScreen(key: _communityKey),
      ProfileScreen(key: _profileKey),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFFFAF7F0),
        selectedItemColor: const Color(0xFF795548),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 3) {
            _communityKey.currentState?.reload();
          } else if (index == 4) {
            _profileKey.currentState?.reload();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
