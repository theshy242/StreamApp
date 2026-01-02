import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled5/Model/user.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:untitled5/Model/ChatService.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class LivePrepareScreen extends StatefulWidget {
  final User currentUser;
  const LivePrepareScreen({super.key, required this.currentUser});

  @override
  State<LivePrepareScreen> createState() => _LivePrepareScreenState();
}

class _LivePrepareScreenState extends State<LivePrepareScreen>
    with WidgetsBindingObserver {
  // ===================== KIẾN TRÚC ĐÚNG =====================
  bool _isLiveSessionActive = false; // LIVE thật sự (server state)
  bool _isStreamerMode = false; // UI mode (chỉ để hiển thị)

  // Thêm biến kiểm tra OBS disconnect
  bool _isOBSConnected = false;
  Timer? _obsCheckTimer;

  // ===================== BIẾN TRẠNG THÁI =====================
  String? selectedCategory;
  final titleController = TextEditingController();

  // Biến kiểm tra video đã sẵn sàng chưa
  bool _isVideoReady = false;
  bool _isCheckingVideo = false;
  String _videoStatus = '';

  // Biến cho video player
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // Chat
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  int _liveViewerCount = 0;
  Timer? _videoCheckTimer;

  // UI
  bool _showChat = true;
  double _chatPanelHeight = 300;

  final List<String> categories = [
    "Gaming", "Music", "Sports",
    "Education", "Entertainment", "Just Chatting"
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAutoCheckVideo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAllTimers();
    _videoController?.dispose();
    _chewieController?.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _stopAllTimers() {
    _videoCheckTimer?.cancel();
    _obsCheckTimer?.cancel();
  }

  // ===================== APP LIFECYCLE =====================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isLiveSessionActive) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      // KHÔNG end live, chỉ pause video preview
        _videoController?.pause();
        break;
      case AppLifecycleState.resumed:
      // Resume video preview
        _videoController?.play();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  // ===================== KIỂM TRA OBS =====================
  Future<void> _checkOBSVideo() async {
    if (_isCheckingVideo) return;

    setState(() {
      _isCheckingVideo = true;
      _videoStatus = '🔍 Đang kiểm tra OBS...';
    });

    try {
      final testController = VideoPlayerController.network(
        widget.currentUser.serverUrl,
      );

      await testController.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException('Không nhận được tín hiệu');
        },
      );

      testController.dispose();

      setState(() {
        _isVideoReady = true;
        _isOBSConnected = true;
        _videoStatus = '✅ Kết nối OBS thành công!';
      });

      _showSuccessSnackBar('Đã nhận tín hiệu video từ OBS');
    } catch (e) {
      setState(() {
        _isVideoReady = false;
        _isOBSConnected = false;
        _videoStatus = '❌ Chưa kết nối được OBS';
      });

      if (e is TimeoutException) {
        _showErrorSnackBar('Hãy kiểm tra OBS đã bật stream chưa?');
      }
    } finally {
      setState(() {
        _isCheckingVideo = false;
      });
    }
  }

  void _startAutoCheckVideo() {
    _videoCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isVideoReady && !_isCheckingVideo && !_isStreamerMode) {
        _checkOBSVideo();
      }
    });
  }

  // ===================== KIỂM TRA OBS DISCONNECT =====================
  void _startObsConnectionMonitor() {
    _obsCheckTimer?.cancel();
    _obsCheckTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (!_isLiveSessionActive || !_isStreamerMode) {
        timer.cancel();
        return;
      }

      try {
        // Kiểm tra video controller còn chạy không
        if (_videoController != null &&
            _videoController!.value.isInitialized &&
            !_videoController!.value.isPlaying) {

          // Thử resume
          await _videoController!.play();

          // Nếu vẫn không chạy sau 5s
          await Future.delayed(const Duration(seconds: 5));

          if (!_videoController!.value.isPlaying) {
            // OBS đã disconnect
            print('⚠️ OBS disconnected, auto-ending live');
            await _endLiveStream(force: true);
          }
        }
      } catch (e) {
        print('❌ OBS monitor error: $e');
        await _endLiveStream(force: true);
      }
    });
  }

  // ===================== QUẢN LÝ LIVE STATE =====================
  Future<void> _createOrUpdateStreamItem({bool isLive = true}) async {
    final ref = FirebaseDatabase.instance
        .ref('streamItems/stream_${widget.currentUser.userId}');

    final streamItem = {
      "userId": widget.currentUser.userId,
      "name": widget.currentUser.name,
      "category": selectedCategory ?? "Just Chatting",
      "url": widget.currentUser.serverUrl,
      "isLiveNow": isLive,
      "colorHex": "#FF3366",
      "image": widget.currentUser.avatar,
      "streamTitle": titleController.text,
      "viewer": "0",
      "followers": widget.currentUser.followers.toString(),
      "coverImage": widget.currentUser.avatar,
      "post": "0",
      "following": "0",
      "description": widget.currentUser.description ?? "",
      "startedAt": ServerValue.timestamp,
      if (!isLive) "endedAt": ServerValue.timestamp,
    };

    await ref.set(streamItem);
  }

  // ===================== BẮT ĐẦU LIVE =====================
  Future<void> _startLiveBroadcast() async {
    if (!_isVideoReady) {
      _showErrorSnackBar('Vui lòng kết nối OBS trước khi bắt đầu');
      return;
    }

    if (titleController.text.isEmpty) {
      _showErrorSnackBar('Hãy nhập tiêu đề cho buổi live');
      return;
    }

    if (selectedCategory == null) {
      _showErrorSnackBar('Hãy chọn danh mục');
      return;
    }

    // Set live state trên server
    setState(() {
      _isLiveSessionActive = true;
      _isStreamerMode = true;
    });

    await _createOrUpdateStreamItem(isLive: true);
    _videoCheckTimer?.cancel();
    _initializeStreamerVideo();
    _sendWelcomeMessage();
    _startObsConnectionMonitor();

    // Lock orientation portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _showSuccessSnackBar('🎬 LIVE ĐÃ BẮT ĐẦU!');
  }

  void _initializeStreamerVideo() {
    try {
      _videoController = VideoPlayerController.network(
        widget.currentUser.serverUrl,
      );

      _videoController!.initialize().then((_) {
        if (!mounted) return;

        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: true,
          showControls: true,
          allowFullScreen: false,
          aspectRatio: _videoController!.value.aspectRatio,
          showControlsOnInitialize: true,
          placeholder: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Đang kết nối với OBS...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          autoInitialize: true,
          allowedScreenSleep: false,
        );

        setState(() {});
      }).catchError((error) {
        print('Error loading stream: $error');
        _showErrorSnackBar('Lỗi khi tải video stream');
      });
    } catch (e) {
      _showErrorSnackBar('Lỗi khởi tạo video: $e');
    }
  }

  // ===================== KẾT THÚC LIVE =====================
  Future<void> _endLiveStream({bool force = false}) async {
    if (!_isLiveSessionActive && !force) return;

    print('🛑 Ending live stream (force: $force)');

    // Update server state
    await _createOrUpdateStreamItem(isLive: false);

    // Send end message
    ChatService.sendSystemMessage(
      streamId: widget.currentUser.userId,
      message: "🔴 ${widget.currentUser.name} đã kết thúc live stream",
    );

    // Cleanup
    _stopAllTimers();
    _videoController?.dispose();
    _chewieController?.dispose();
    _videoController = null;
    _chewieController = null;

    // Reset orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Update UI state
    if (mounted) {
      setState(() {
        _isLiveSessionActive = false;
        _isStreamerMode = false;
        _isVideoReady = false;
        _isOBSConnected = false;
        _videoStatus = '';
        _liveViewerCount = 0;
      });
    }

    _startAutoCheckVideo();
    _showSuccessSnackBar('Đã kết thúc live stream');
  }

  // ===================== CHAT =====================
  void _sendWelcomeMessage() {
    ChatService.sendSystemMessage(
      streamId: widget.currentUser.userId,
      message: "🌟 ${widget.currentUser.name} đang live: ${titleController.text}",
    );
  }

  Future<void> _sendChatMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await ChatService.sendMessage(
      streamId: widget.currentUser.userId,
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

  // ===================== GIAO DIỆN STREAMER MODE =====================
  Widget _buildStreamerControlPanel() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Video
          Positioned.fill(
            child: _buildVideoPlayer(),
          ),

          // Top Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),

          // Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: _buildStreamHeader(),
          ),

          // Chat Panel
          if (_showChat)
            Positioned(
              right: 12,
              top: 120,
              bottom: 12,
              width: 320,
              child: _buildChatPanel(),
            ),

          // End Stream Button
          Positioned(
            bottom: 24,
            left: 24,
            child: GestureDetector(
              onTap: () => _showEndStreamDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.stop, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Kết thúc LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Toggle Chat Button
          Positioned(
            bottom: 24,
            right: _showChat ? 340 : 24,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showChat = !_showChat;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Icon(
                  _showChat ? Icons.chat : Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.currentUser.avatar,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Stream Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentUser.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  titleController.text,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Live Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF3366), Color(0xFFFF6B6B)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE • $_liveViewerCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    } else {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                _videoStatus.isNotEmpty ? _videoStatus : 'Đang chuẩn bị video...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildChatPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            // Chat Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Live Chat",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.people_alt_outlined,
                    color: Colors.white.withOpacity(0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_liveViewerCount',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: StreamBuilder(
                stream: ChatService.getStreamMessages(widget.currentUser.userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.white.withOpacity(0.5),
                        strokeWidth: 2,
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  return ListView.builder(
                    controller: _chatScrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildChatMessage(message);
                    },
                  );
                },
              ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: "Nhắn tin...",
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            onPressed: () {
                              _sendChatMessage();
                            },
                            icon: Icon(
                              Icons.send_rounded,
                              color: Colors.white.withOpacity(0.8),
                              size: 20,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _sendChatMessage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessage(message) {
    final isStreamer = message.isStreamer;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isStreamer ? const Color(0xFFFF3366) : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                message.userAvatar,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Message content
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isStreamer
                    ? const Color(0xFFFF3366).withOpacity(0.15)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isStreamer
                      ? const Color(0xFFFF3366).withOpacity(0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        message.userName,
                        style: TextStyle(
                          color: isStreamer
                              ? const Color(0xFFFF3366)
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isStreamer) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3366),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Host',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
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

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ===================== GIAO DIỆN CHUẨN BỊ =====================
  Widget _buildPreparationScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header với gradient
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF0A0A0F),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  // Avatar và info
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        widget.currentUser.avatar,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.currentUser.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.currentUser.followers} followers',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Server info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      Uri.parse(widget.currentUser.serverUrl).host,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Chuẩn bị LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Làm theo các bước dưới để bắt đầu stream',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // OBS Setup Steps
                    _buildSetupSteps(),

                    const SizedBox(height: 32),

                    // Video Check Status
                    _buildVideoStatusCard(),

                    const SizedBox(height: 32),

                    // Live Info Form
                    _buildLiveInfoForm(),

                    const SizedBox(height: 40),

                    // Start Live Button
                    _buildStartLiveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cài đặt OBS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 16),

        // Step 1
        _buildStepCard(
          number: 1,
          icon: Icons.settings_outlined,
          title: 'Cấu hình OBS Studio',
          description: 'Settings → Stream → Server URL\n'
              'Điền: ${widget.currentUser.serverUrl}',
          color: const Color(0xFF4361EE),
        ),

        const SizedBox(height: 12),

        // Step 2
        _buildStepCard(
          number: 2,
          icon: Icons.play_arrow_rounded,
          title: 'Bật Stream',
          description: 'Nhấn "Start Streaming" trong OBS\n'
              'Chờ đến khi hiện green light',
          color: const Color(0xFF3A0CA3),
        ),

        const SizedBox(height: 12),

        // Step 3
        _buildStepCard(
          number: 3,
          icon: Icons.videocam_rounded,
          title: 'Kiểm tra kết nối',
          description: 'Nhấn nút "Kiểm tra OBS" bên dưới\n'
              'Đợi đến khi hiện ✅ thành công',
          color: const Color(0xFF7209B7),
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required int number,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Number Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, color: color, size: 20),
            ),
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
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

  Widget _buildVideoStatusCard() {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info_outline;

    if (_isCheckingVideo) {
      statusColor = Colors.blue;
      statusIcon = Icons.refresh;
    } else if (_isVideoReady) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _videoStatus.isEmpty
                      ? (_isCheckingVideo ? 'Đang kiểm tra...' : 'Chưa kiểm tra OBS')
                      : _videoStatus,
                  style: TextStyle(
                    color: _isVideoReady ? Colors.green : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isCheckingVideo ? null : _checkOBSVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isVideoReady
                    ? Colors.green.withOpacity(0.2)
                    : const Color(0xFF4361EE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: Icon(
                _isCheckingVideo
                    ? Icons.refresh
                    : (_isVideoReady ? Icons.check : Icons.videocam),
                size: 20,
              ),
              label: Text(
                _isCheckingVideo
                    ? 'Đang kiểm tra...'
                    : (_isVideoReady ? '✅ OBS ĐÃ KẾT NỐI' : 'Kiểm tra OBS'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveInfoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin LIVE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 20),

        // Title Input
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: titleController,
            style: const TextStyle(color: Colors.white),
            maxLength: 80,
            decoration: InputDecoration(
              hintText: "Tiêu đề live stream...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Icon(
                Icons.title,
                color: Colors.white.withOpacity(0.6),
              ),
              counterStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Category Dropdown
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            dropdownColor: const Color(0xFF1A1A2E),
            value: selectedCategory,
            icon: Icon(
              Icons.arrow_drop_down,
              color: Colors.white.withOpacity(0.6),
            ),
            decoration: InputDecoration(
              hintText: "Chọn danh mục",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Icon(
                Icons.category,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            items: categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCategory = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStartLiveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isVideoReady ? _startLiveBroadcast : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isVideoReady
              ? const Color(0xFFFF3366)
              : Colors.grey.withOpacity(0.3),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: _isVideoReady
              ? const Color(0xFFFF3366).withOpacity(0.5)
              : Colors.transparent,
        ),
        icon: const Icon(Icons.live_tv, size: 24),
        label: Text(
          _isVideoReady ? 'BẮT ĐẦU LIVE' : 'VUI LÒNG KẾT NỐI OBS',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ===================== DIALOGS =====================
  Future<void> _showEndStreamDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Kết thúc Live Stream?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Bạn có chắc chắn muốn kết thúc buổi live stream này không?\n\n'
                'Tất cả khán giả sẽ không thể xem tiếp.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Hủy',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _endLiveStream();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kết thúc LIVE'),
            ),
          ],
        );
      },
    );
  }

  // ===================== TIỆN ÍCH =====================
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isStreamerMode
        ? _buildStreamerControlPanel()
        : _buildPreparationScreen();
  }
}