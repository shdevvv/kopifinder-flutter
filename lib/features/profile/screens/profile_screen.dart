import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/screens/sign_in_screen.dart';
import '../models/user_profile.dart';
import '../repositories/user_repository.dart';

// ── 3D Papercut Palette matching user specifications ────────────────────────
const Color _bgWall = Color(0xFFFAF7F0);         // Unified cream background
const Color _cardCream = Color(0xFFF7F2E9);      // Inner cream paper
const Color _whitePaper = Color(0xFFFFFFFF);     // Pure clean white paper
const Color _chocolateDark = Color(0xFF382317);  // Dark milk chocolate text
const Color _chocolateMid = Color(0xFF6B4C38);   // Milk chocolate medium
const Color _chocolateShadow = Color(0xFFAD8C78);// 3D paper drop shadow layer

// Requested Greens
const Color _greenPrimary = Color(0xFF526B0C);   // #526B0C deep rich olive
const Color _greenVibrant = Color(0xFF8DBA20);   // #8DBA20 vibrant olive lime
const Color _greenLight = Color(0xFFA5C943);     // #A5C943 light lime olive
const Color _greenDarkShadow = Color(0xFF364807);// Bottom drop shelf for green
const Color _greenPaperTint = Color(0xFFF0F6E4); // Soft paper tint for tags

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  String userName = '';
  String username = '';
  String userEmail = '';
  String? avatarUrl;
  String location = 'Jakarta, Indonesia';
  UserStats _stats = const UserStats();
  // ignore: unused_field
  bool _isLoading = true;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    userEmail = SupabaseService.instance.currentUser?.email ?? '';
    final meta = SupabaseService.instance.currentUser?.userMetadata;
    if (meta != null) {
      userName = (meta['full_name'] ?? meta['name'] ?? '').toString();
      final u = meta['username']?.toString() ?? '';
      username = u.isNotEmpty ? (u.startsWith('@') ? u : '@$u') : '';
    }
    _loadProfile();
  }

  void reload() => _loadProfile();

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
          userEmail = profile.email.isNotEmpty ? profile.email : (SupabaseService.instance.currentUser?.email ?? '');
          avatarUrl = profile.avatarUrl;
          location = 'Jakarta, Indonesia';
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

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploadingAvatar) return;
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final file = File(image.path);
      final newUrl = await UserRepository.instance.uploadAvatar(file);
      if (newUrl != null && mounted) {
        setState(() {
          avatarUrl = newUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully ✓')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload photo. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> editProfile() async {
    final nameController = TextEditingController(text: userName);
    final usernameController = TextEditingController(
      text: username.startsWith('@') ? username.substring(1) : username,
    );

    final result = await showDialog<Map<String, String>>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE2D4C5), width: 2),
          ),
          title: const Text(
            'Edit Profile ✨',
            style: TextStyle(
              color: _chocolateDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditField(
                  controller: nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 15),
                _buildEditField(
                  controller: usernameController,
                  label: 'Username',
                  icon: Icons.alternate_email_rounded,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: _chocolateMid,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _greenPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                final newName = nameController.text.trim();
                final newUsername = usernameController.text.trim();
                Navigator.of(dialogContext).pop({
                  'name': newName,
                  'username': newUsername,
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    usernameController.dispose();

    if (result != null && mounted) {
      final newName = result['name'] ?? '';
      final newUsername = result['username'] ?? '';
      if (newName.isNotEmpty) {
        setState(() {
          userName = newName;
          if (newUsername.isNotEmpty) {
            username = '@$newUsername';
          }
        });

        try {
          await UserRepository.instance.updateProfile(
            fullName: newName,
            username: newUsername.isNotEmpty ? newUsername : username.replaceAll('@', ''),
          );
          if (mounted) {
            await _loadProfile();
          }
        } catch (_) {}
      }
    }
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
        labelStyle: const TextStyle(color: _chocolateMid),
        prefixIcon: Icon(icon, color: _greenPrimary),
        filled: true,
        fillColor: _whitePaper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2D6C6), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _greenPrimary, width: 1.8),
        ),
      ),
    );
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE2D4C5), width: 2),
          ),
          title: const Text(
            'Log Out?',
            style: TextStyle(
              color: _chocolateDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of KopiFinder?',
            style: TextStyle(
              color: _chocolateMid,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: _chocolateMid, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
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

    if (confirmed == true && mounted) {
      await AuthRepository.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
          (route) => false,
        );
      }
    }
  }

  // ── 3D Papercut Stats Item ────────────────────────────────────────────────
  Widget _build3DStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: _chocolateDark,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _chocolateMid,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWall,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: _chocolateDark,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: _bgWall,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        color: _greenPrimary,
        backgroundColor: _cardCream,
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
          child: Column(
            children: [
              // ── 1. Main Profile Card (3D Papercut Multi-layer) ──────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Drop paper shadow shelf
                  Positioned(
                    left: 5,
                    top: 6,
                    right: -5,
                    bottom: -6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _chocolateShadow,
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),

                  // Front Pure White Paper Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                    decoration: BoxDecoration(
                      color: _whitePaper,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE2D4C5), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _chocolateDark.withOpacity(0.08),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // ── 3D Papercut Avatar ───────────────────────────────
                        GestureDetector(
                          onTap: _pickAndUploadAvatar,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              // 3D paper bottom drop shelf
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: -5,
                                child: Container(
                                  width: 122,
                                  height: 122,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _chocolateShadow,
                                  ),
                                ),
                              ),

                              // Outer cream ring
                              Container(
                                width: 122,
                                height: 122,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _cardCream,
                                  border: Border.all(color: _greenLight, width: 2.5),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.white,
                                      offset: Offset(0, -1),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: CircleAvatar(
                                    radius: 53,
                                    backgroundColor: _greenPaperTint,
                                    backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                                        ? NetworkImage(avatarUrl!)
                                        : null,
                                    child: (avatarUrl == null || avatarUrl!.isEmpty)
                                        ? const Icon(
                                            Icons.person_rounded,
                                            size: 60,
                                            color: _greenPrimary,
                                          )
                                        : null,
                                  ),
                                ),
                              ),

                              if (_isUploadingAvatar)
                                Positioned.fill(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black45,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    ),
                                  ),
                                )
                              else
                                // 3D Camera button badge
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: -2.5,
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _greenDarkShadow,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _greenPrimary,
                                          border: Border.all(color: _greenVibrant, width: 1.5),
                                        ),
                                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // USER NAME
                        Text(
                          userName.isNotEmpty ? userName : 'Coffee Explorer',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _chocolateDark,
                            letterSpacing: -0.2,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // USERNAME
                        if (username.isNotEmpty)
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: _chocolateMid,
                            ),
                          ),

                        if (userEmail.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: _greenPrimary,
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // ── 3D Papercut Location Tag ("Jakarta, Indonesia") ─
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Drop shadow shelf
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: -2.5,
                              child: Container(
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _chocolateShadow,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                            // Front pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: _greenPaperTint,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _greenLight, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.white,
                                    offset: Offset(0, -1),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 15,
                                    color: _greenPrimary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    location,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: _greenPrimary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── 3D Papercut Stats Row (Saved & Posts) ─────────────
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Shadow backing
                            Positioned(
                              left: 3,
                              top: 4,
                              right: -3,
                              bottom: -4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _chocolateShadow,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                            // Front Stats card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                              decoration: BoxDecoration(
                                color: _cardCream,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE2D4C5), width: 1.6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _build3DStatItem('Saved', _stats.bookmarksCount),
                                  Container(
                                    width: 1.8,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD8C7B7),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                  _build3DStatItem('Posts', _stats.postsCount),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── 2. 3D Papercut Edit Profile Button ─────────────────────────
              GestureDetector(
                onTap: editProfile,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Bottom dark shelf
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
                    // Front raised 3D green block
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
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_rounded, color: Colors.white, size: 19),
                          SizedBox(width: 9),
                          Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── 3. 3D Papercut Log Out Button ──────────────────────────────
              GestureDetector(
                onTap: logout,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Bottom dark shelf
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -4,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: _chocolateShadow,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    // Front white paper block
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _whitePaper,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2D4C5), width: 1.8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.white,
                            offset: Offset(0, -1),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: _chocolateMid, size: 19),
                          SizedBox(width: 8),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              color: _chocolateDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Footer
              const Text(
                'Made with love & coffee ♡',
                style: TextStyle(
                  color: _chocolateMid,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
