import 'dart:ui';
import 'package:flutter/material.dart';
import '../Model/model.dart';
import 'profile_detail_screen.dart';
import 'package:untitled5/Model/user.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:untitled5/Model/ChatService.dart';
import 'package:firebase_database/firebase_database.dart';

class LiveStreamScreen extends StatefulWidget {
  final StreamItem streamItem;
  final User user;

  LiveStreamScreen({super.key, required this.streamItem, required this.user});

  @override
  State<StatefulWidget> createState() {
    return _LiveStreamScreenState();
  }

  // Widget nút action (giữ nguyên giao diện)
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

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  // Biến quản lý chat
  bool _showChat = true;
  bool _isChatExpanded = false;
  double _chatPanelHeight = 220;
  int _liveViewerCount = 0;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendWelcomeMessage();
      _setupLiveViewerCounter();
    });
  }

  // === PHẦN XỬ LÝ VIDEO (Giữ nguyên) ===
  void _initializeVideoPlayer() {
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

  // === PHẦN XỬ LÝ CHAT (Tích hợp đầy đủ) ===
  void _sendWelcomeMessage() {
    ChatService.sendSystemMessage(
      streamId: widget.streamItem.name,
      message: "🌟 ${widget.user.name} đã bắt đầu live stream!",
    );
  }

  void _setupLiveViewerCounter() {
    final DatabaseReference viewerRef = FirebaseDatabase.instance
        .ref('streams/${widget.streamItem.name}/viewers');

    // Tăng số viewer
    viewerRef.runTransaction((currentData) {
      int current = (currentData as int? ?? 0) + 1;
      return Transaction.success(current);
    });

    // Lắng nghe thay đổi
    viewerRef.onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          _liveViewerCount = event.snapshot.value as int;
        });
      }
    });
  }

  Future<void> _sendChatMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await ChatService.sendMessage(
      streamId: widget.streamItem.name,
      userId: widget.user.userId,
      userName: widget.user.name,
      userAvatar: widget.user.avatar,
      message: _messageController.text.trim(),
      isStreamer: true,
    );

    _messageController.clear();

    // Cuộn xuống tin nhắn mới nhất
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleChatVisibility() {
    setState(() {
      _showChat = !_showChat;
    });
  }

  void _toggleChatExpand() {
    setState(() {
      _isChatExpanded = !_isChatExpanded;
      _chatPanelHeight = _isChatExpanded
          ? MediaQuery.of(context).size.height * 0.5
          : 220; // Chiều cao mặc định
    });
  }

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFollowing
            ? "✅ Đã theo dõi ${widget.streamItem.name}!"
            : "❌ Đã bỏ theo dõi"),
        backgroundColor: _isFollowing ? Colors.green : Colors.red,
      ),
    );
  }

  // Widget hiển thị danh sách tin nhắn
  Widget _buildChatListView() {
    return StreamBuilder(
      stream: ChatService.getStreamMessages(widget.streamItem.name),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.purpleAccent),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Lỗi: ${snapshot.error}',
                style: const TextStyle(color: Colors.white)),
          );
        }

        final messages = snapshot.data ?? [];

        return ListView.builder(
          controller: _chatScrollController,
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 10),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildSingleChatMessage(message);
          },
        );
      },
    );
  }

  // Widget hiển thị một tin nhắn
  Widget _buildSingleChatMessage(message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(message.isStreamer ? 0.5 : 0.3),
        borderRadius: BorderRadius.circular(12),
        border: message.isStreamer
            ? Border.all(color: Colors.purpleAccent, width: 1)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage(message.userAvatar),
            backgroundColor: Colors.grey[800],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.userName,
                      style: TextStyle(
                        color: message.isStreamer
                            ? Colors.purpleAccent
                            : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (message.isStreamer) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'S',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatTime(message.timestamp),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  message.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Giảm số viewer khi rời đi
    final viewerRef = FirebaseDatabase.instance
        .ref('streams/${widget.streamItem.name}/viewers');
    viewerRef.runTransaction((currentData) {
      int current = (currentData as int? ?? 1) - 1;
      if (current < 0) current = 0;
      return Transaction.success(current);
    });

    _videoController.dispose();
    _chewieController?.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // ========== VIDEO PLAYER (Giữ nguyên phần hiển thị) ==========
          Positioned.fill(
            child: _chewieController != null &&
                _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(
              controller: _chewieController!,
            )
                : Image.network(
              widget.streamItem.image,
              fit: BoxFit.cover,
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

          // Gradient overlay (Giữ nguyên)
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

          // Nút Back (Giữ nguyên)
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

          // ========== PHẦN TRÊN: Thông tin streamer (Cập nhật viewer count) ==========
          Positioned(
            top: 50,
            left: 70,
            right: 15,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfileDetailScreen(streamItem: widget.streamItem),
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
                        "${_liveViewerCount} viewers", // Dùng số viewer thực tế
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _toggleFollow,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: _isFollowing
                          ? const LinearGradient(
                          colors: [Colors.grey, Colors.grey])
                          : const LinearGradient(
                          colors: [Colors.purpleAccent, Colors.blueAccent]),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: Text(
                      _isFollowing ? "Following" : "Follow",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (widget.streamItem.isLiveNow)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
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

          // Tiêu đề stream (Giữ nguyên)
          Positioned(

            top: 100,
            left: 15,
            right: 15,
            child: Text(
              widget.user.serverUrl,
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

          // ========== PHẦN DƯỚI: PANEL CHAT TIKTOK STYLE ==========
          // Panel chat (chỉ hiện khi _showChat = true)
          if (_showChat)
            Positioned(
              left: 10,
              right: 10,
              bottom: 20,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _chatPanelHeight,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header của panel chat - Có thể kéo để thay đổi kích thước
                    GestureDetector(
                      onTap: _toggleChatExpand,
                      onVerticalDragUpdate: (details) {
                        setState(() {
                          final newHeight = _chatPanelHeight - details.delta.dy;
                          // Giới hạn chiều cao từ 150px đến 60% màn hình
                          _chatPanelHeight = newHeight.clamp(
                              150, MediaQuery.of(context).size.height * 0.6);
                          _isChatExpanded = _chatPanelHeight > 250;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.9),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline,
                                color: Colors.purpleAccent, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "Live Chat",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "$_liveViewerCount",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.people_outline,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 8),
                            Icon(
                              _isChatExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Danh sách tin nhắn - Scrollable
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: _buildChatListView(),
                      ),
                    ),

                    // Thanh nhập tin nhắn
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.9),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: "Nhắn tin...",
                                  hintStyle:
                                  const TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                  contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                        Icons.emoji_emotions_outlined,
                                        color: Colors.white70,
                                        size: 20),
                                    onPressed: () {
                                      // Có thể thêm emoji picker ở đây
                                    },
                                  ),
                                ),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                onSubmitted: (_) => _sendChatMessage(),
                                maxLines: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _sendChatMessage,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purpleAccent,
                                    Colors.blueAccent
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 18,
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

          // ========== CÁC NÚT ACTION BÊN PHẢI (Giữ nguyên vị trí) ==========
          Positioned(
            bottom: _showChat ? (_chatPanelHeight + 30) : 120,
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
                  icon: _showChat
                      ? Icons.chat_bubble
                      : Icons.chat_bubble_outline,
                  label: "Chat",
                  onTap: _toggleChatVisibility,
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
        ],
      ),
    );
  }
}