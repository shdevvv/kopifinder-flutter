import 'package:flutter/material.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/screens/sign_in_screen.dart';
import '../models/user_profile.dart';
import '../repositories/user_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const cream = Color(0xFFFAF7F0);
  static const lightGreen = Color(0xFFE8EDDF);
  static const sage = Color(0xFF9AAA83);
  static const darkGreen = Color(0xFF52634A);
  static const brown = Color(0xFF795548);
  static const darkBrown = Color(0xFF4E342E);

  String userName = 'Coffee Lover';
  String username = '@coffeelover';
  String location = 'Jakarta, Indonesia';
  UserStats _stats = const UserStats();
  // ignore: unused_field
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final results = await Future.wait([
        UserRepository.instance.getProfile(),
        UserRepository.instance.getStats(),
      ]);

      final profile = results[0] as UserProfile;
      final stats = results[1] as UserStats;

      if (mounted) {
        setState(() {
          userName = profile.fullName;
          username = profile.username.startsWith('@') ? profile.username : '@${profile.username}';
          location = profile.location;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void editProfile() {
    final nameController = TextEditingController(text: userName);
    final usernameController = TextEditingController(
      text: username.startsWith('@') ? username.substring(1) : username,
    );
    final locationController = TextEditingController(text: location);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: const Text(
            'Edit Profile ✨',
            style: TextStyle(
              color: darkBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditField(
                  controller: nameController,
                  label: 'Nama pengguna',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 15),
                _buildEditField(
                  controller: usernameController,
                  label: 'Username',
                  icon: Icons.alternate_email_rounded,
                ),
                const SizedBox(height: 15),
                _buildEditField(
                  controller: locationController,
                  label: 'Lokasi',
                  icon: Icons.location_on_outlined,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            18,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: brown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final newName = nameController.text.trim();
                final newUsername = usernameController.text.trim();
                final newLocation = locationController.text.trim();

                Navigator.pop(dialogContext);

                setState(() {
                  userName = newName;
                  username = '@$newUsername';
                  location = newLocation;
                });

                try {
                  await UserRepository.instance.updateProfile(
                    fullName: newName,
                    username: newUsername,
                    location: newLocation,
                  );
                } catch (_) {}
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    ).then((_) {
      nameController.dispose();
      usernameController.dispose();
      locationController.dispose();
    });
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: brown),
        prefixIcon: Icon(
          icon,
          color: darkGreen,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE4E8DC),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: sage,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  void logout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: const Text(
            'Log Out?',
            style: TextStyle(
              color: darkBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun KopiFinder?',
            style: TextStyle(
              color: brown,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: brown),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await AuthRepository.instance.signOut();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                  (route) => false,
                );
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: darkBrown,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // PROFILE PHOTO
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lightGreen,
                  border: Border.all(
                    color: sage,
                    width: 2,
                  ),
                ),
                child: const CircleAvatar(
                  radius: 57,
                  backgroundColor: Color(0xFFDCE4D3),
                  child: Icon(
                    Icons.person_rounded,
                    size: 65,
                    color: darkGreen,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // USER NAME
              Text(
                userName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: darkBrown,
                ),
              ),

              const SizedBox(height: 6),

              // USERNAME
              Text(
                username,
                style: const TextStyle(
                  fontSize: 14,
                  color: brown,
                ),
              ),

              const SizedBox(height: 10),

              // LOCATION
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 17,
                      color: darkGreen,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 13,
                        color: darkGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // STATS ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Ulasan', _stats.reviewsCount),
                  Container(width: 1, height: 35, color: const Color(0xFFDCE4D3)),
                  _buildStatItem('Disimpan', _stats.bookmarksCount),
                  Container(width: 1, height: 35, color: const Color(0xFFDCE4D3)),
                  _buildStatItem('Postingan', _stats.postsCount),
                ],
              ),

              const SizedBox(height: 30),

              // EDIT PROFILE
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: editProfile,
                  icon: const Icon(
                    Icons.edit_rounded,
                    size: 19,
                  ),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: darkGreen.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // LOG OUT
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: logout,
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 19,
                  ),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brown,
                    side: const BorderSide(
                      color: sage,
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Made with love & coffee ♡',
                style: TextStyle(
                  color: sage,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkBrown,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: brown,
          ),
        ),
      ],
    );
  }
}
