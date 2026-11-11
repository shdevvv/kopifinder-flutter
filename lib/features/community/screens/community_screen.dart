import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ==========================================
// MODEL DATA
// ==========================================

class CommunityReply {
  final String name;
  final String text;

  CommunityReply({
    required this.name,
    required this.text,
  });
}

class CommunityComment {
  final String name;
  final String text;
  int likes;
  bool liked;
  final List<CommunityReply> replies;

  CommunityComment({
    required this.name,
    required this.text,
    this.likes = 0,
    this.liked = false,
    List<CommunityReply>? replies,
  }) : replies = replies ?? [];
}

class CommunityPost {
  final String name;
  final String location;
  final String caption;
  final File? image;
  int likes;
  bool liked;
  final List<CommunityComment> comments;

  CommunityPost({
    required this.name,
    required this.location,
    required this.caption,
    this.image,
    this.likes = 0,
    this.liked = false,
    List<CommunityComment>? comments,
  }) : comments = comments ?? [];
}

// ==========================================
// COMMUNITY SCREEN
// ==========================================

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  static const cream = Color(0xFFFAF7F0);
  static const lightGreen = Color(0xFFE8EDDF);
  static const sage = Color(0xFF9AAA83);
  static const darkGreen = Color(0xFF52634A);
  static const brown = Color(0xFF795548);
  static const darkBrown = Color(0xFF4E342E);

  final List<CommunityPost> posts = [
    CommunityPost(
      name: 'Coffee Explorer',
      location: 'Jakarta',
      caption: 'Menemukan tempat ngopi yang nyaman untuk kerja hari ini!',
      likes: 24,
      comments: [
        CommunityComment(
          name: 'Coffee Lover',
          text: 'Tempatnya di mana?',
          likes: 2,
          replies: [
            CommunityReply(
              name: 'Coffee Explorer',
              text: 'Di daerah Jakarta Selatan!',
            ),
          ],
        ),
      ],
    ),
    CommunityPost(
      name: 'Daily Coffee',
      location: 'Bandung',
      caption: 'Weekend paling pas ditemani secangkir kopi ☕',
      likes: 18,
    ),
    CommunityPost(
      name: 'Cafe Hunter',
      location: 'Yogyakarta',
      caption: 'Suasana cafe yang bikin betah berlama-lama.',
      likes: 32,
      comments: [
        CommunityComment(
          name: 'Coffee Lover',
          text: 'Vibes-nya bagus banget!',
          likes: 1,
        ),
      ],
    ),
  ];

  void togglePostLike(CommunityPost post) {
    setState(() {
      post.liked = !post.liked;
      post.likes += post.liked ? 1 : -1;
    });
  }

  void toggleCommentLike(CommunityComment comment) {
    setState(() {
      comment.liked = !comment.liked;
      comment.likes += comment.liked ? 1 : -1;
    });
  }

  Future<void> openCreatePost() async {
    final result = await showModalBottomSheet<CommunityPost>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const CreatePostSheet();
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      posts.insert(0, result);
    });
  }

  Future<void> openComments(CommunityPost post) async {
    await showModalBottomSheet<void>(
      context: context,
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

  Widget buildPostCard(CommunityPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFEAEDE4),
        ),
        boxShadow: [
          BoxShadow(
            color: darkBrown.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: lightGreen,
                  child: const Icon(
                    Icons.person_rounded,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkBrown,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        post.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: sage,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.more_horiz_rounded,
                  color: darkBrown,
                ),
              ],
            ),
          ),
          if (post.image != null)
            Image.file(
              post.image!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 5),
            child: Text(
              post.caption,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: darkBrown,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => togglePostLike(post),
                  icon: Icon(
                    post.liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: post.liked ? Colors.red : brown,
                  ),
                ),
                Text(
                  '${post.likes}',
                  style: const TextStyle(
                    color: darkBrown,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 14),
                IconButton(
                  onPressed: () => openComments(post),
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: darkGreen,
                  ),
                ),
                Text(
                  '${post.comments.length} komentar',
                  style: const TextStyle(
                    color: darkBrown,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        title: const Text(
          'Community',
          style: TextStyle(
            color: darkBrown,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: openCreatePost,
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: darkGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.coffee_rounded,
                    color: darkGreen,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coffee Community ☕',
                        style: TextStyle(
                          color: darkBrown,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Bagikan cerita dan temukan teman ngopi!',
                        style: TextStyle(
                          color: darkGreen,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Postingan Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkBrown,
                ),
              ),
              TextButton(
                onPressed: openCreatePost,
                child: const Text(
                  'Buat Post',
                  style: TextStyle(
                    color: darkGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...posts.map(buildPostCard),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openCreatePost,
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ==========================================
// CREATE POST SHEET
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

  static const cream = Color(0xFFFAF7F0);
  static const lightGreen = Color(0xFFE8EDDF);
  static const sage = Color(0xFF9AAA83);
  static const darkGreen = Color(0xFF52634A);
  static const brown = Color(0xFF795548);
  static const darkBrown = Color(0xFF4E342E);

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
          content: Text('Gagal memilih foto. Coba lagi.'),
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

  void submitPost() {
    final caption = captionController.text.trim();

    if (caption.isEmpty && selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tambahkan tulisan atau foto terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    final post = CommunityPost(
      name: 'You',
      location: 'Lokasi saya',
      caption: caption,
      image: selectedImage,
    );

    Navigator.pop(context, post);
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
            color: cream,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: sage,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Buat Postingan ☕',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: darkBrown,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: captionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Ceritakan pengalaman ngopimu...',
                    hintStyle: TextStyle(
                      color: brown.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFFE4E8DC),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: darkGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(
                      selectedImage!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: pickingImage ? null : pickPhoto,
                  icon: const Icon(
                    Icons.image_outlined,
                    color: darkGreen,
                  ),
                  label: Text(
                    pickingImage ? 'Memilih foto...' : 'Pilih Foto',
                    style: const TextStyle(
                      color: darkGreen,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: sage),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Bagikan Postingan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
// COMMENTS SHEET
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

  static const cream = Color(0xFFFAF7F0);
  static const lightGreen = Color(0xFFE8EDDF);
  static const sage = Color(0xFF9AAA83);
  static const darkGreen = Color(0xFF52634A);
  static const brown = Color(0xFF795548);
  static const darkBrown = Color(0xFF4E342E);

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
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
          decoration: const BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: sage,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Komentar 💬',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: darkBrown,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: comments.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada komentar. Jadilah yang pertama!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: brown,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];

                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFEAEDE4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 17,
                                      backgroundColor: lightGreen,
                                      child: const Icon(
                                        Icons.person_rounded,
                                        color: darkGreen,
                                        size: 19,
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Text(
                                        comment.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: darkBrown,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 9),
                                Text(
                                  comment.text,
                                  style: const TextStyle(
                                    color: darkBrown,
                                  ),
                                ),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          replyingTo = comment;
                                        });
                                      },
                                      child: const Text(
                                        'Reply',
                                        style: TextStyle(
                                          color: darkGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        widget.onLikeComment(comment);
                                        setState(() {});
                                      },
                                      icon: Icon(
                                        comment.liked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color:
                                            comment.liked ? Colors.red : brown,
                                        size: 19,
                                      ),
                                    ),
                                    Text(
                                      '${comment.likes}',
                                      style: const TextStyle(
                                        color: darkBrown,
                                      ),
                                    ),
                                  ],
                                ),
                                if (comment.replies.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 24,
                                    ),
                                    child: Column(
                                      children: comment.replies.map((reply) {
                                        return Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          padding: const EdgeInsets.all(11),
                                          decoration: BoxDecoration(
                                            color: lightGreen,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                reply.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: darkGreen,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                reply.text,
                                                style: const TextStyle(
                                                  color: darkBrown,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (replyingTo != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Membalas ${replyingTo!.name}',
                        style: const TextStyle(
                          color: darkGreen,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          replyingTo = null;
                        });
                      },
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: brown),
                      ),
                    ),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: replyingTo == null
                            ? 'Tulis komentar...'
                            : 'Tulis balasan...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 13,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFFE4E8DC),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: sage,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => sendComment(),
                    ),
                  ),
                  const SizedBox(width: 5),
                  IconButton(
                    onPressed: sendComment,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: darkGreen,
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
