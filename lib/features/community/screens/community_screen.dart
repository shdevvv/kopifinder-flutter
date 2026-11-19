import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/state_widgets.dart';
import '../models/community_models.dart';
import '../repositories/community_repository.dart';

// ==========================================
// COMMUNITY SCREEN — 3D PAPERCUT REDESIGN
// ==========================================

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => CommunityScreenState();
}

class CommunityScreenState extends State<CommunityScreen> {
  // ── 3D Papercut Palette ───────────────────────────────────────────────────
  static const Color _bgWall = Color(0xFFA5C943);          // Requested #A5C943 background
  static const Color _bgWallShadow = Color(0xFF526B0C);    // Deep olive shelf shadow
  static const Color _cardCream = Color(0xFFF7F2E9);       // Warm cream paper
  static const Color _whitePaper = Color(0xFFFFFFFF);      // Clean white paper
  static const Color _chocolateDark = Color(0xFF382317);   // Dark chocolate text
  static const Color _chocolateMid = Color(0xFF6B4C38);    // Medium chocolate
  static const Color _outlineCard = Color(0xFFCFAC97);     // Requested #CFAC97 medium outline
  static const Color _greenPrimary = Color(0xFF526B0C);    // Deep olive
  static const Color _greenVibrant = Color(0xFF8DBA20);    // Vibrant lime olive
  static const Color _greenDarkShadow = Color(0xFF364807); // Bottom drop shelf for green

  List<CommunityPost> posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void reload() => _loadPosts();

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await CommunityRepository.instance.getPosts();
      if (mounted) {
        setState(() {
          posts = list;
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

  void togglePostLike(CommunityPost post) async {
    final prevLiked = post.liked;
    setState(() {
      post.liked = !post.liked;
      post.likes += post.liked ? 1 : -1;
    });

    if (post.id != null) {
      final newStatus = await CommunityRepository.instance.toggleLike(post.id!, prevLiked);
      if (mounted && post.liked != newStatus) {
        setState(() {
          post.liked = newStatus;
        });
      }
    }
  }

  void toggleCommentLike(CommunityComment comment) {
    setState(() {
      comment.liked = !comment.liked;
      comment.likes += comment.liked ? 1 : -1;
    });
  }

  Future<void> openCreatePost() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const CreatePostSheet();
      },
    );

    if (!mounted || result == null) return;

    final caption = result['caption'] as String? ?? '';
    final imageFile = result['imageFile'] as File?;

    if (caption.isEmpty && imageFile == null) return;

    try {
      final createdPost = await CommunityRepository.instance.createPost(
        caption: caption,
        imageFile: imageFile,
      );
      if (mounted) {
        setState(() {
          posts.insert(0, createdPost);
        });
        await _loadPosts();
      }
    } catch (_) {
      if (mounted) {
        await _loadPosts();
      }
    }
  }

  Future<void> openComments(CommunityPost post) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CommentsSheet(
          post: post,
          onLikeComment: toggleCommentLike,
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _showPostOptions(CommunityPost post) {
    final currentUserId = SupabaseService.instance.currentUser?.id;
    final isOwner = post.userId != null && post.userId == currentUserId;
    if (!isOwner) return;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _whitePaper,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _outlineCard, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: _chocolateDark.withOpacity(0.2),
                offset: const Offset(0, 6),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: _greenPrimary),
                title: const Text('Edit Post', style: TextStyle(fontWeight: FontWeight.w700, color: _chocolateDark)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _editPost(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Delete Post', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _deletePost(post);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editPost(CommunityPost post) async {
    final captionController = TextEditingController(text: post.caption);
    final result = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: _whitePaper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: _outlineCard, width: 1.8),
          ),
          title: const Text('Edit Post', style: TextStyle(color: _chocolateDark, fontWeight: FontWeight.w900)),
          content: TextField(
            controller: captionController,
            maxLines: 4,
            style: const TextStyle(color: _chocolateDark),
            decoration: InputDecoration(
              hintText: 'Write a caption...',
              filled: true,
              fillColor: _cardCream,
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _outlineCard)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _greenPrimary, width: 1.5)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel', style: TextStyle(color: _chocolateMid, fontWeight: FontWeight.w700))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _greenPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(dialogCtx, captionController.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    captionController.dispose();

    if (result != null && result.isNotEmpty && post.id != null && mounted) {
      try {
        await CommunityRepository.instance.updatePost(post.id!, result);
        await _loadPosts();
      } catch (_) {}
    }
  }

  Future<void> _deletePost(CommunityPost post) async {
    if (post.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: _whitePaper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: _outlineCard, width: 1.8),
          ),
          title: const Text('Delete Post', style: TextStyle(color: _chocolateDark, fontWeight: FontWeight.w900)),
          content: const Text('Are you sure you want to delete this post?', style: TextStyle(color: _chocolateMid)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel', style: TextStyle(color: _chocolateMid, fontWeight: FontWeight.w700))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        await CommunityRepository.instance.deletePost(post.id!);
        setState(() {
          posts.removeWhere((p) => p.id == post.id);
        });
      } catch (_) {
        await _loadPosts();
      }
    }
  }

  // ── Redesigned Compact & Flatter 3D Papercut Post Card ─────────────────────
  // Shorter/flatter height, creative #CFAC97 outline, 3D bottom shadow shelf
  Widget buildPostCard(CommunityPost post) {
    final currentUserId = SupabaseService.instance.currentUser?.id;
    final isOwner = post.userId != null && post.userId == currentUserId;
    final hasImage = (post.imageUrl != null && post.imageUrl!.isNotEmpty) || post.image != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 3D paper bottom shelf on top of #A5C943
          Positioned(
            left: 3,
            top: 4,
            right: -3,
            bottom: -4,
            child: Container(
              decoration: BoxDecoration(
                color: _bgWallShadow,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Front white paper card with thin-medium #CFAC97 outline
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _whitePaper,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _outlineCard, width: 1.6),
              boxShadow: const [
                BoxShadow(
                  color: Colors.white,
                  offset: Offset(0, -1),
                  blurRadius: 0,
                ),
              ],
            ),
            child: hasImage
                ? _buildCompactHorizontalLayout(post, isOwner)
                : _buildCompactTextLayout(post, isOwner),
          ),
        ],
      ),
    );
  }

  // Compact horizontal layout for posts with photo (flatter height, 92x92 thumbnail)
  Widget _buildCompactHorizontalLayout(CommunityPost post, bool isOwner) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact 3D photo thumbnail
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _outlineCard, width: 1.2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                ? Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderThumb(),
                  )
                : (post.image != null)
                    ? Image.file(
                        post.image!,
                        fit: BoxFit.cover,
                      )
                    : _placeholderThumb(),
          ),
        ),

        const SizedBox(width: 12),

        // Right side info & compact caption
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Author row + options
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: _cardCream,
                    backgroundImage: (post.avatarUrl != null && post.avatarUrl!.isNotEmpty)
                        ? NetworkImage(post.avatarUrl!)
                        : null,
                    child: (post.avatarUrl == null || post.avatarUrl!.isEmpty)
                        ? Text(
                            post.name.isNotEmpty ? post.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 10, color: _greenPrimary, fontWeight: FontWeight.w900),
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      post.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: _chocolateDark,
                      ),
                    ),
                  ),
                  if (isOwner)
                    GestureDetector(
                      onTap: () => _showPostOptions(post),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.more_horiz_rounded, size: 18, color: _chocolateMid),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 5),

              // Caption (compact, max 2 lines to keep height short & flat)
              Text(
                post.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: _chocolateDark,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              // Bottom 3D action pills (Like & Comment)
              Row(
                children: [
                  // 3D Like Pill
                  GestureDetector(
                    onTap: () => togglePostLike(post),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: post.liked ? const Color(0xFFFFECEC) : _cardCream,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: post.liked ? const Color(0xFFFF8A80) : _outlineCard,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            post.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 13,
                            color: post.liked ? Colors.redAccent : _chocolateMid,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likes}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: post.liked ? Colors.redAccent : _chocolateDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 3D Comment Pill
                  GestureDetector(
                    onTap: () => openComments(post),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _cardCream,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _outlineCard, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: _greenPrimary),
                          const SizedBox(width: 4),
                          Text(
                            '${post.comments.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _chocolateDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  if (post.location.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 11, color: _greenPrimary),
                        const SizedBox(width: 2),
                        Text(
                          post.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: _chocolateMid, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Compact layout for text-only posts (flat, sleek card)
  Widget _buildCompactTextLayout(CommunityPost post, bool isOwner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Author row + options
        Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: _cardCream,
              backgroundImage: (post.avatarUrl != null && post.avatarUrl!.isNotEmpty)
                  ? NetworkImage(post.avatarUrl!)
                  : null,
              child: (post.avatarUrl == null || post.avatarUrl!.isEmpty)
                  ? Text(
                      post.name.isNotEmpty ? post.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 11, color: _greenPrimary, fontWeight: FontWeight.w900),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: _chocolateDark,
                    ),
                  ),
                  if (post.location.isNotEmpty)
                    Text(
                      post.location,
                      style: const TextStyle(fontSize: 10, color: _chocolateMid, fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),
            if (isOwner)
              GestureDetector(
                onTap: () => _showPostOptions(post),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.more_horiz_rounded, size: 18, color: _chocolateMid),
                ),
              ),
          ],
        ),

        const SizedBox(height: 7),

        // Caption
        Text(
          post.caption,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: _chocolateDark,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 10),

        // Bottom 3D action pills
        Row(
          children: [
            // 3D Like Pill
            GestureDetector(
              onTap: () => togglePostLike(post),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: post.liked ? const Color(0xFFFFECEC) : _cardCream,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: post.liked ? const Color(0xFFFF8A80) : _outlineCard,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      post.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 14,
                      color: post.liked ? Colors.redAccent : _chocolateMid,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${post.likes}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: post.liked ? Colors.redAccent : _chocolateDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // 3D Comment Pill
            GestureDetector(
              onTap: () => openComments(post),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _cardCream,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _outlineCard, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: _greenPrimary),
                    const SizedBox(width: 5),
                    Text(
                      '${post.comments.length} comments',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _chocolateDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _placeholderThumb() {
    return Container(
      color: _cardCream,
      child: const Center(
        child: Icon(Icons.local_cafe_rounded, color: _greenPrimary, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWall,
      body: SafeArea(
        child: RefreshIndicator(
          color: _greenPrimary,
          backgroundColor: _whitePaper,
          onRefresh: _loadPosts,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              // ── 3D Papercut Hero Banner ───────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Bottom shelf on #A5C943
                  Positioned(
                    left: 3,
                    top: 5,
                    right: -3,
                    bottom: -5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _bgWallShadow,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  // Front white paper card with #CFAC97 outline
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _whitePaper,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _outlineCard, width: 1.8),
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
                        // 3D Papercut Medallion Logo (matching brand standard)
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEBDDCB),
                            border: Border.all(color: const Color(0xFFD5C4B1), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: _chocolateDark.withOpacity(0.18),
                                offset: const Offset(0, 3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF3F7F2),
                                border: Border.all(color: _greenVibrant, width: 1.5),
                              ),
                              child: ClipOval(
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Image.asset(
                                    'assets/icon/no_text_logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Coffee Community ☕',
                                style: TextStyle(
                                  color: _chocolateDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Share your cozy coffee stories & discover fellow coffee lovers in Jakarta!',
                                style: TextStyle(
                                  color: _chocolateMid,
                                  fontSize: 11.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
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

              const SizedBox(height: 18),

              // ── Feed Header ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Community Feed',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: _chocolateDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: openCreatePost,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _whitePaper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _outlineCard, width: 1.4),
                        boxShadow: const [
                          BoxShadow(
                            color: _bgWallShadow,
                            offset: Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_rounded, color: _greenPrimary, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Post Moment',
                            style: TextStyle(
                              color: _greenPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: AppLoadingWidget(message: 'Loading community posts...'),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: AppErrorWidget(
                    message: _errorMessage!,
                    onRetry: _loadPosts,
                  ),
                )
              else if (posts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 3,
                        top: 4,
                        right: -3,
                        bottom: -4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _bgWallShadow,
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                        decoration: BoxDecoration(
                          color: _whitePaper,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: _outlineCard, width: 1.8),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.forum_outlined, size: 48, color: _greenPrimary),
                              SizedBox(height: 12),
                              Text('No Posts Yet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _chocolateDark)),
                              SizedBox(height: 6),
                              Text('Be the first to share your coffee moments!', style: TextStyle(color: _chocolateMid, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...posts.map(buildPostCard),
            ],
          ),
        ),
      ),
      // 3D Papercut FAB
      floatingActionButton: GestureDetector(
        onTap: openCreatePost,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: -4,
              child: Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: _greenDarkShadow,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: _greenPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: _whitePaper, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(0, -1),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// CREATE POST SHEET — 3D PAPERCUT
// ==========================================

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key});

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final TextEditingController captionController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  File? selectedImage;
  bool pickingImage = false;
  bool _isSubmitting = false;

  static const Color _whitePaper = Color(0xFFFFFFFF);
  static const Color _cardCream = Color(0xFFF7F2E9);
  static const Color _outlineCard = Color(0xFFCFAC97);
  static const Color _chocolateDark = Color(0xFF382317);
  static const Color _chocolateMid = Color(0xFF6B4C38);
  static const Color _greenPrimary = Color(0xFF526B0C);
  static const Color _greenDarkShadow = Color(0xFF364807);

  Future<void> pickPhoto() async {
    if (pickingImage) return;

    setState(() {
      pickingImage = true;
    });

    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (!mounted) return;

      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to select photo. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          pickingImage = false;
        });
      }
    }
  }

  Future<void> submitPost() async {
    if (_isSubmitting) return;
    final caption = captionController.text.trim();

    if (caption.isEmpty && selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add a caption or photo first.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    Navigator.pop(context, {'caption': caption, 'imageFile': selectedImage});
  }

  @override
  void dispose() {
    captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: _whitePaper,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                offset: Offset(0, -4),
                blurRadius: 16,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _outlineCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Share Coffee Moment ☕',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: _chocolateDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: captionController,
                  maxLines: 4,
                  style: const TextStyle(color: _chocolateDark, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Share your coffee experience, cafe recommendation, or favorite drink...',
                    hintStyle: TextStyle(
                      color: _chocolateMid.withOpacity(0.6),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: _cardCream,
                    contentPadding: const EdgeInsets.all(16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: _outlineCard),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: _greenPrimary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (selectedImage != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          selectedImage!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => selectedImage = null),
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: pickingImage ? null : pickPhoto,
                  icon: const Icon(
                    Icons.image_outlined,
                    color: _greenPrimary,
                  ),
                  label: Text(
                    pickingImage ? 'Selecting photo...' : 'Select Photo',
                    style: const TextStyle(
                      color: _greenPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _outlineCard, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 3D Submit Button
                GestureDetector(
                  onTap: _isSubmitting ? null : submitPost,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: -3,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _greenDarkShadow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _greenPrimary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFA5C943), width: 1.5),
                        ),
                        child: Center(
                          child: _isSubmitting
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text(
                                  'Share Post',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
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
        ),
      ),
    );
  }
}

// ==========================================
// COMMENTS SHEET — 3D PAPERCUT
// ==========================================

class CommentsSheet extends StatefulWidget {
  final CommunityPost post;
  final Function(CommunityComment) onLikeComment;

  const CommentsSheet({
    super.key,
    required this.post,
    required this.onLikeComment,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController commentController = TextEditingController();

  CommunityComment? replyingTo;

  static const Color _whitePaper = Color(0xFFFFFFFF);
  static const Color _cardCream = Color(0xFFF7F2E9);
  static const Color _outlineCard = Color(0xFFCFAC97);
  static const Color _chocolateDark = Color(0xFF382317);
  static const Color _chocolateMid = Color(0xFF6B4C38);
  static const Color _greenPrimary = Color(0xFF526B0C);

  void sendComment() {
    final text = commentController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      if (replyingTo == null) {
        widget.post.comments.add(
          CommunityComment(
            name: 'You',
            text: text,
          ),
        );
      } else {
        replyingTo!.replies.add(
          CommunityReply(
            name: 'You',
            text: text,
          ),
        );
      }

      replyingTo = null;
      commentController.clear();
    });

    if (widget.post.id != null) {
      CommunityRepository.instance.addComment(
        postId: widget.post.id!,
        text: text,
        parentCommentId: replyingTo?.id,
      );
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comments = widget.post.comments;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
          decoration: const BoxDecoration(
            color: _whitePaper,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                offset: Offset(0, -4),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _outlineCard,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Comments 💬',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _chocolateDark,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 40,
                              color: _greenPrimary,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No comments yet.',
                              style: TextStyle(
                                color: _chocolateMid,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start the conversation!',
                              style: TextStyle(
                                color: _chocolateMid.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _cardCream,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _outlineCard, width: 1.2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 11,
                                        backgroundColor: Colors.white,
                                        child: Text(
                                          comment.name.isNotEmpty ? comment.name[0].toUpperCase() : 'U',
                                          style: const TextStyle(fontSize: 10, color: _greenPrimary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        comment.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: _chocolateDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    comment.text,
                                    style: const TextStyle(fontSize: 13, color: _chocolateDark, height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Comment input
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _cardCream,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _outlineCard, width: 1.2),
                      ),
                      child: TextField(
                        controller: commentController,
                        style: const TextStyle(color: _chocolateDark, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: _chocolateMid.withOpacity(0.6), fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: sendComment,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _greenPrimary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFA5C943), width: 1.2),
                      ),
                      child: const Center(
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
