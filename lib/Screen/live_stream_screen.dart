import 'dart:ui';
import 'package:flutter/material.dart';
import '../Model/model.dart';
import 'profile_detail_screen.dart';
import 'package:untitled5/Model/user.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class LiveStreamScreen extends StatefulWidget{
  final StreamItem streamItem;
  final User user;// ✅ thêm user
  const LiveStreamScreen({super.key, required this.streamItem, required this.user});
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
   return _LiveStreamScreenState();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }


}

class _LiveStreamScreenState extends State<LiveStreamScreen>{
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _videoController = VideoPlayerController.network(widget.user.serverUrl)
      ..initialize().then((_) {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: false,
        );
        setState(() {});
      });
  }
  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background stream image/video
          Hero(
            tag: widget.streamItem.image,
            child: _chewieController != null &&
                _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(
              controller: _chewieController!,
            )
                : Image.network(
              widget.streamItem.image,
              fit: BoxFit.cover,
              height: size.height,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.white54,
                      size: 50,
                    ),
                  ),
                );
              },
            ),
          ),
          Text(
            widget.user.serverUrl,
            style: const TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Back button
          Positioned(
            top: 50,
            left: 15,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // Top info row - SỬA PHẦN NÀY QUAN TRỌNG
          Positioned(
            top: 50,
            left: 70,
            right: 15,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // TRUYỀN ĐÚNG streamItem SANG ProfileDetailScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileDetailScreen(streamItem: widget.streamItem),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(widget.streamItem.image),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.streamItem.name,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${widget.streamItem.followers} Followers",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      colors: [Colors.purpleAccent, Colors.blueAccent],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: const Text(
                    "Follow",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (widget.streamItem.isLiveNow)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "LIVE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
              ],
            ),
          ),

          // Stream title
          Positioned(
            top: 100,
            left: 15,
            right: 15,
            child: Text(
              widget.streamItem.streamTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.black,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),

          // Viewer count
          Positioned(
            top: 130,
            left: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.remove_red_eye, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "${widget.streamItem.viewer} viewers",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom action buttons
          Positioned(
            bottom: 120,
            right: 15,
            child: Column(
              children: [
                widget._buildActionButton(
                  icon: Icons.favorite_border,
                  label: widget.streamItem.followers,
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                widget._buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: "Chat",
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                widget._buildActionButton(
                  icon: Icons.share_outlined,
                  label: "Share",
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                widget._buildActionButton(
                  icon: Icons.more_vert,
                  label: "More",
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Bottom comment/input row
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Send a message...",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.purpleAccent, Colors.blueAccent],
                      ),
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


}