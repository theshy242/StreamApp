import 'dart:ui';
import 'package:flutter/material.dart';
import '../Model/model.dart';
import 'live_stream_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled5/Model/user.dart';

class ProfileDetailScreen extends StatefulWidget {
  final StreamItem streamItem;
  const ProfileDetailScreen({super.key, required this.streamItem});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  bool isLoading = false;
  Map<String, User> usersMap = {};
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    print("🔍 Bắt đầu fetch user data cho: ${widget.streamItem.userId}");

    try {
      // Tạo database reference
      final DatabaseReference usersDbRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: "https://livestream-app-32b54-default-rtdb.firebaseio.com/",
      ).ref().child('users');

      // Lấy dữ liệu user từ Firebase
      final snapshot = await usersDbRef.child(widget.streamItem.userId).get();

      if (snapshot.exists) {
        print("✅ Tìm thấy user trong Firebase");
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          currentUser = User.fromJson(userData);
          usersMap[widget.streamItem.userId] = currentUser!;
        });
      } else {
        print("⚠️ Không tìm thấy user trong Firebase, tạo user tạm");
        _createFallbackUser();
      }
    } catch (e) {
      print("❌ Lỗi khi fetch user data: $e");
      _createFallbackUser();
    }
  }

  void _createFallbackUser() {
    setState(() {
      // KIỂM TRA CÁC FIELD CỦA MODEL USER CỦA BẠN
      currentUser = User(
        userId: widget.streamItem.userId,
        name: widget.streamItem.name,
        email: "${widget.streamItem.name.toLowerCase().replaceAll(' ', '')}@example.com",
        avatar: widget.streamItem.image,
        followers: _parseNumber(widget.streamItem.followers),
        // CHỈ THÊM 'following' NẾU MODEL CÓ
        // following: _parseNumber(widget.streamItem.following), // BỎ NẾU KHÔNG CÓ
        serverUrl: widget.streamItem.url,
        description: widget.streamItem.description,
      );

      usersMap[widget.streamItem.userId] = currentUser!;
    });
  }

  int _parseNumber(String value) {
    try {
      if (value.toLowerCase().contains('k')) {
        return (double.parse(value.replaceAll('k', '')) * 1000).toInt();
      }
      return int.tryParse(value) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  void _handleStreamTap() {
    if (currentUser == null) {
      print("❌ Chưa có user data, tạo user tạm");
      _createFallbackUser();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamScreen(
          streamItem: widget.streamItem,
          user: currentUser!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeaderSection(size),
                const SizedBox(height: 80),
                _buildDescriptionSection(),
                const SizedBox(height: 30),
                _buildStatsSection(size),
                const SizedBox(height: 30),
                _buildTabSection(),
                const SizedBox(height: 15),
                _buildUserInfoSection(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeaderSection(Size size) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover Image với error handling đơn giản
        Container(
          height: size.height * 0.3,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            image: widget.streamItem.coverImage.isNotEmpty
                ? DecorationImage(
              fit: BoxFit.cover,
              image: NetworkImage(widget.streamItem.coverImage),
            )
                : null,
          ),
          child: widget.streamItem.coverImage.isEmpty
              ? const Center(
            child: Icon(
              Icons.image_not_supported,
              color: Colors.white54,
              size: 50,
            ),
          )
              : null,
        ),

        // Back Button and Menu
        Positioned(
          top: 40,
          left: 15,
          right: 15,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.more_vert, color: Colors.white, size: 24),
              ),
            ],
          ),
        ),

        // Avatar
        Positioned(
          bottom: -50,
          left: 20,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 4),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey[800],
              backgroundImage: widget.streamItem.image.isNotEmpty
                  ? NetworkImage(widget.streamItem.image)
                  : null,
              child: widget.streamItem.image.isEmpty
                  ? const Icon(
                Icons.person,
                color: Colors.white,
                size: 40,
              )
                  : null,
            ),
          ),
        ),

        // Name and Username
        Positioned(
          bottom: -45,
          left: 140,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.streamItem.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "@${widget.streamItem.name.toLowerCase().replaceAll(' ', '')}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Follow Button
        Positioned(
          bottom: -40,
          right: 20,
          child: GestureDetector(
            onTap: () {
              print("📌 Đã follow ${widget.streamItem.name}");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Đã follow ${widget.streamItem.name}"),
                  backgroundColor: Colors.purpleAccent,
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Colors.purpleAccent, Colors.blueAccent],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: const Text(
                "Follow",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        widget.streamItem.description.isNotEmpty
            ? widget.streamItem.description
            : "Chưa có mô tả",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatsSection(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(widget.streamItem.post, "Posts"),
          _buildVerticalDivider(size),
          _buildStatItem(widget.streamItem.following, "Following"),
          _buildVerticalDivider(size),
          _buildStatItem(widget.streamItem.followers, "Followers"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value.isNotEmpty ? value : "0",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(Size size) {
    return Container(
      height: size.height * 0.04,
      width: 1,
      color: Colors.grey[600],
    );
  }

  Widget _buildTabSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem("Live Stream", true),
          _buildTabItem("Last Live", false),
          _buildTabItem("Star", false),
          _buildTabItem("Post", false),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, bool isActive) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (isActive)
          Container(
            width: 60,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.purpleAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  Widget _buildUserInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Current Stream",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: _handleStreamTap,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[900],
                image: widget.streamItem.image.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(widget.streamItem.image),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: widget.streamItem.image.isEmpty
                  ? const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 40,
                ),
              )
                  : Stack(
                children: [
                  if (widget.streamItem.isLiveNow)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "LIVE NOW",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.remove_red_eye,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            widget.streamItem.viewer,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            widget.streamItem.streamTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            widget.streamItem.category,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}