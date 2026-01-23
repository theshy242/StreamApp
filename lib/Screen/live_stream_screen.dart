import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:flutter/material.dart';
import '../Model/model.dart';
import 'profile_detail_screen.dart';
import 'package:untitled5/Model/user.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:untitled5/Model/ChatService.dart';
import 'package:firebase_database/firebase_database.dart';

// Định nghĩa Quality Level ngay bên ngoài class
enum VideoQuality {
  auto('Auto', Icons.auto_awesome, 'Tự động', Colors.green),
  high('High', Icons.hd, '1080p', Colors.blue),
  medium('Medium', Icons.video_settings, '720p', Colors.purple),
  low('Low', Icons.sd, '480p', Colors.orange);

  final String name;
  final IconData icon;
  final String label;
  final Color color;

  const VideoQuality(this.name, this.icon, this.label, this.color);
}

class LiveStreamScreen extends StatefulWidget {
  final StreamItem streamItem;
  final User currentUser;

  LiveStreamScreen({super.key, required this.streamItem, required this.currentUser});

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

  // Biến quản lý chat (giữ nguyên)
  bool _showChat = true;
  bool _isChatExpanded = false;
  double _chatPanelHeight = 220;
  int _liveViewerCount = 0;
  bool _isFollowing = false;

  // === THÊM BIẾN MỚI CHO CHẤT LƯỢNG VIDEO ===
  VideoQuality _currentQuality = VideoQuality.auto;
  bool _isBuffering = false;
  bool _showQualityMenu = false;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
    _initializeVideoPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendWelcomeMessage();
      _setupLiveViewerCounter();
    });
  }

  void _checkIfFollowing() async {
    final currentUserId = widget.currentUser.userId;
    final streamerId = widget.streamItem.userId;

    final snapshot = await FirebaseDatabase.instance
        .ref("users/$streamerId/followers/$currentUserId")
        .get();

    if (mounted) {
      setState(() {
        _isFollowing = snapshot.exists;
      });
    }
  }


  void _initializeVideoPlayer() {
    String videoUrl = _getVideoUrlBasedOnQuality();

    _videoController = VideoPlayerController.network(videoUrl);

    // Sử dụng Future.then() thay vì async/await trong initialize
    _videoController.initialize().then((_) {
      final videoAspectRatio = _videoController.value.aspectRatio;

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: true,
        showControls: true,
        allowFullScreen: true,
        aspectRatio: videoAspectRatio,
        showControlsOnInitialize: true,
        placeholder: Container(
          color: Colors.grey[900],
          child: const Center(
            child: CircularProgressIndicator(color: Colors.purpleAccent),
          ),
        ),
        autoInitialize: true,
        allowedScreenSleep: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.purpleAccent,
          handleColor: Colors.purpleAccent,
          backgroundColor: Colors.grey[700]!,
          bufferedColor: Colors.grey[500]!,
        ),
      );

      // Thêm listener để phát hiện buffering
      _videoController.addListener(() {
        if (_videoController.value.isBuffering && mounted) {
          setState(() {
            _isBuffering = true;
          });
        } else if (mounted) {
          setState(() {
            _isBuffering = false;
          });
        }
      });

      setState(() {
        _isBuffering = false;
      });
    }).catchError((error) {
      print('Error loading stream: $error');
      // Nếu không tải được chất lượng đã chọn, thử chất lượng thấp hơn
      _fallbackToLowerQuality();
    });
  }

  String _getVideoUrlBasedOnQuality() {
    final userId = widget.streamItem.userId;
    final basePath = "http://172.16.12.118/live/$userId";

    switch (_currentQuality) {
      case VideoQuality.high:
        return "$basePath/index_0.m3u8";
      case VideoQuality.medium:
        return "$basePath/index_1.m3u8";
      case VideoQuality.low:
        return "$basePath/index_2.m3u8";
      default:
        return "$basePath/index_1.m3u8";
    }
  }

  void _fallbackToLowerQuality() {
    if (_currentQuality == VideoQuality.high) {
      _changeVideoQuality(VideoQuality.medium);
    } else if (_currentQuality == VideoQuality.medium) {
      _changeVideoQuality(VideoQuality.low);
    } else if (_currentQuality == VideoQuality.low) {
      _changeVideoQuality(VideoQuality.auto);
    }
  }

  void _changeVideoQuality(VideoQuality newQuality) async {
    if (_currentQuality == newQuality) return;

    print('🔄 Changing quality to: ${newQuality.name}');

    try {
      // Dispose controllers cũ (KHÔNG DÙNG AWAIT VỚI dispose())
      if (_chewieController != null) {
        _chewieController!.dispose(); // ← SỬA: bỏ await
      }
      _videoController.dispose(); // ← SỬA: bỏ await

      // Cập nhật state
      setState(() {
        _currentQuality = newQuality;
        _isBuffering = true;
      });

      // Khởi tạo lại với URL mới
      _initializeVideoPlayer();

      // Hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(newQuality.icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text('Đã chuyển sang ${newQuality.label}'),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: newQuality.color,
        ),
      );
    } catch (e) {
      print('❌ Error changing quality: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể thay đổi chất lượng'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showQualitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.video_settings, color: Colors.purpleAccent,
                      size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Chọn chất lượng video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Danh sách chất lượng
              ...VideoQuality.values.map((quality) {
                final isSelected = _currentQuality == quality;

                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? quality.color : Colors.grey[800],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      quality.icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    quality.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight
                          .normal,
                    ),
                  ),
                  subtitle: Text(
                    quality.label,
                    style: TextStyle(
                      color: isSelected ? quality.color : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.purpleAccent)
                      : null,
                  onTap: () {
                    _changeVideoQuality(quality);
                    Navigator.pop(context);
                  },
                );
              }).toList(),

              const SizedBox(height: 20),

              // Thông tin hiện tại
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                        Icons.info_outline, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chất lượng tốt nhất phụ thuộc vào tốc độ mạng của bạn',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // === PHẦN XỬ LÝ CHAT (GIỮ NGUYÊN) ===
  void _sendWelcomeMessage() {
    ChatService.sendSystemMessage(
      streamId: widget.streamItem.name,
      message: "🌟 ${widget.currentUser.name} đã bắt đầu live stream!",
    );
  }

  void _setupLiveViewerCounter() {
    final DatabaseReference viewerRef = FirebaseDatabase.instance
        .ref('streams/${widget.streamItem.name}/viewers');

    // Tạo child cho từng user
    final userRef = viewerRef.child(widget.currentUser.userId);
    userRef.set(true); // user online
    userRef.onDisconnect().remove(); // khi disconnect Firebase tự remove

    // Lắng nghe số lượng viewers thực tế
    viewerRef.onValue.listen((event) {
      if (mounted) {
        setState(() {
          _liveViewerCount = event.snapshot.children.length;
        });
      }
    });
  }

  Future<void> _sendChatMessage() async {
    if (_messageController.text
        .trim()
        .isEmpty) return;

    await ChatService.sendMessage(
      streamId: widget.streamItem.name,
      userId: widget.currentUser.userId,
      userName: widget.currentUser.name,
      userAvatar: widget.currentUser.avatar,
      message: _messageController.text.trim(),
      isStreamer: true,
    );

    _messageController.clear();

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
          ? MediaQuery
          .of(context)
          .size
          .height * 0.5
          : 220;
    });
  }

  void _toggleFollow() async {
    final currentUserId = widget.currentUser.userId; // user14
    final streamerId = widget.streamItem.userId; // user15

    print("FOLLOW CLICK");
    print("currentUserId = $currentUserId");
    print("streamerId = $streamerId");

    // ❌ Không cho follow chính mình
    if (currentUserId == streamerId) {
      print("FOLLOW SELF - BLOCKED");
      return;
    }

    final followerRef = FirebaseDatabase.instance
        .ref("users/$streamerId/followers/$currentUserId");

    try {
      if (_isFollowing) {
        await followerRef.remove();
        print("➖ UNFOLLOW");
      } else {
        await followerRef.set(true);
        print("➕ FOLLOW");
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFollowing
                ? "Đã theo dõi ${widget.streamItem.name}"
                : "Đã bỏ theo dõi",
          ),
        ),
      );
    } catch (e) {
      print("Follow error: $e");
    }
  }


  // === CHỈ SỬA HÀM NÀY ===
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

        // TỐI ƯU: Thêm cacheExtent và key cho ListView.builder
        return ListView.builder(
          controller: _chatScrollController,
          physics: const BouncingScrollPhysics(),
          // Mượt hơn
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 10),
          itemCount: messages.length,
          cacheExtent: 400,
          // Pre-render 400px trước/sau viewport
          addAutomaticKeepAlives: true,
          // Giữ trạng thái các item đã load
          addRepaintBoundaries: true,
          // Tách biệt repaint giữa các item
          itemBuilder: (context, index) {
            final message = messages[index];

            // TỐI ƯU: Sử dụng ValueKey để Flutter tái sử dụng widget
            return _buildSingleChatMessage(
              message,
              key: ValueKey('msg_${message.timestamp}_${index}'), // Key unique
            );
          },
        );
      },
    );
  }

// === CHỈ SỬA HÀM NÀY ===
  Widget _buildSingleChatMessage(message, {Key? key}) {
    return Container(
      key: key,
      // Thêm key vào đây
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
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute
        .toString()
        .padLeft(2, '0')}';
  }

  @override
  void dispose() {
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

  // === WIDGET VIDEO PLAYER (THÊM BUFFERING INDICATOR) ===
  Widget _buildCorrectedVideoPlayer() {
    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      final videoAspectRatio = _videoController.value.aspectRatio;

      return Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: videoAspectRatio,
              child: Chewie(
                controller: _chewieController!,
              ),
            ),
          ),

          // Buffering Indicator
          if (_isBuffering)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: _currentQuality.color,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Đang tải video...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chất lượng: ${_currentQuality.label}',
                        style: TextStyle(
                          color: _currentQuality.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      return Image.network(
        widget.streamItem.image,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
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
      );
    }
  }

  // === WIDGET CHỌN CHẤT LƯỢNG (NÚT TRÊN GIAO DIỆN) ===
  Widget _buildQualityButton() {
    return Positioned(
      top: 50,
      right: 15, // Điều chỉnh vị trí
      child: GestureDetector(
        onTap: _showQualitySelector,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
            border: Border.all(
              color: _currentQuality.color,
              width: 2,
            ),
          ),
          child: Icon(
            _currentQuality.icon,
            color: _currentQuality.color,
            size: 22,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // VIDEO PLAYER - Chiếm toàn bộ màn hình
          Positioned.fill(
            child: _buildCorrectedVideoPlayer(),
          ),

          // GRADIENT OVERLAY - Chỉ ở phần trên và dưới, không che video
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // HEADER BAR - Gọn gàng hơn
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  children: [
                    // Nút Back
                    GestureDetector(
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
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Avatar và thông tin streamer
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
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(widget.streamItem.image),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.streamItem.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${_liveViewerCount} viewers",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Nút Follow
                    GestureDetector(
                      onTap: _toggleFollow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isFollowing ? Colors.grey[700] : Colors.purpleAccent,
                          borderRadius: BorderRadius.circular(15),
                        ),
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

                    if (widget.streamItem.isLiveNow)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "LIVE",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),



          // PANEL CHAT - Chỉ hiển thị phần tin nhắn, KHÔNG có input
          if (_showChat)
            Positioned(
              left: 10,
              right: 10,
              bottom: 140, // Để chừa chỗ cho input chat và nút chất lượng
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
                    // Header chat panel
                    GestureDetector(
                      onTap: _toggleChatExpand,
                      onVerticalDragUpdate: (details) {
                        setState(() {
                          final newHeight = _chatPanelHeight - details.delta.dy;
                          _chatPanelHeight = newHeight.clamp(
                              150, MediaQuery.of(context).size.height * 0.5);
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

                    // Danh sách chat
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: _buildChatListView(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // NÚT CHẤT LƯỢNG VIDEO - Nằm trên thanh input chat
          Positioned(
            bottom: 90, // Ngay trên input chat
            right: 15,
            child: GestureDetector(
              onTap: _showQualitySelector,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _currentQuality.color,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _currentQuality.icon,
                  color: _currentQuality.color,
                  size: 22,
                ),
              ),
            ),
          ),

          // THANH INPUT CHAT - Nằm dưới cùng
          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Nút ẩn/hiện chat
                  GestureDetector(
                    onTap: _toggleChatVisibility,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _showChat ? Icons.chat : Icons.chat_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Input text
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
                          hintStyle: const TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.emoji_emotions_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                            onPressed: () {},
                          ),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        onSubmitted: (_) => _sendChatMessage(),
                        maxLines: 1,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Nút gửi
                  GestureDetector(
                    onTap: _sendChatMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.purpleAccent, Colors.blueAccent],
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
          ),
        ],
      ),
    );
  }
}