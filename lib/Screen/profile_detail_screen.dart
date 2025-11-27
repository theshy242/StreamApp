import 'dart:ui';
import 'package:flutter/material.dart';
import '../Model/model.dart';
import 'live_stream_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled5/Model/user.dart';

class ProfileDetailScreen extends StatefulWidget {
  final StreamItem streamItem; // ĐỔI TỪ streamId SANG streamItem
  const ProfileDetailScreen({super.key, required this.streamItem});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  bool isLoading = false;
  List<StreamItem> userStreams = [];

  @override
  void initState() {
    super.initState();
    // Không cần fetch từ Firebase nữa vì đã có đầy đủ data
    // Chỉ cần lấy các stream khác của user này nếu cần
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
        // Cover Image
        Container(
          height: size.height * 0.3,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: NetworkImage(widget.streamItem.coverImage),
            ),
          ),
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
              )
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
              backgroundImage: NetworkImage(widget.streamItem.image),
            ),
          ),
        ),

        // Name and Username
        Positioned(
          bottom: -45,
          left: 140,
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
              ),
              const SizedBox(height: 4),
              Text(
                "@${widget.streamItem.name.toLowerCase().replaceAll(' ', '')}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Follow Button
        Positioned(
          bottom: -40,
          right: 20,
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
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        widget.streamItem.description,
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
          value,
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
  Map<String, User> usersMap = {};

  void fetchUsers() async {
    DatabaseReference usersRef = FirebaseDatabase.instance.ref("users");
    final snapshot = await usersRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        usersMap[key] = User.fromJson(Map<String, dynamic>.from(value));
      });
    }
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LiveStreamScreen(
                    streamItem: widget.streamItem,
                    user: usersMap[widget.streamItem.userId]!, // ✅ lấy user theo userId
                  ),
                ),
              );

            },
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(widget.streamItem.image),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  if (widget.streamItem.isLiveNow)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.remove_red_eye, color: Colors.white, size: 14),
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