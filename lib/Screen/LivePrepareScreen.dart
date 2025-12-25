import 'dart:async';
import 'package:flutter/material.dart';
import 'package:untitled5/Model/user.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:untitled5/Model/ChatService.dart';
import 'package:firebase_database/firebase_database.dart';

class LivePrepareScreen extends StatefulWidget {
  final User currentUser;
  const LivePrepareScreen({super.key, required this.currentUser});

  @override
  State<LivePrepareScreen> createState() => _LivePrepareScreenState();
}

class _LivePrepareScreenState extends State<LivePrepareScreen> {
  // ===================== BIẾN TRẠNG THÁI =====================
  String? selectedCategory;
  final titleController = TextEditingController();

  // Biến kiểm tra video đã sẵn sàng chưa
  bool _isVideoReady = false;
  bool _isCheckingVideo = false;
  String _videoStatus = 'Chưa kiểm tra';

  // Biến cho màn hình điều khiển stream
  bool _isStreamerMode = false;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  int _liveViewerCount = 0;
  Timer? _videoCheckTimer;
  Timer? _viewerUpdateTimer;

  // Biến quản lý chat
  bool _showChat = true;
  bool _isChatExpanded = false;
  double _chatPanelHeight = 300;

  final List<String> categories = [
    "Popular", "Gaming", "Sports",
    "Music",
  ];

  @override
  void initState() {
    super.initState();
    _startAutoCheckVideo(); // Bắt đầu kiểm tra video tự động
  }

  @override
  void dispose() {
    _videoCheckTimer?.cancel();
    _viewerUpdateTimer?.cancel();
    _videoController?.dispose();
    _chewieController?.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  // ===================== KIỂM TRA VIDEO TỪ OBS =====================
  Future<void> _checkOBSVideo() async {
    if (_isCheckingVideo) return;

    setState(() {
      _isCheckingVideo = true;
      _videoStatus = 'Đang kiểm tra video từ OBS...';
    });

    try {
      // Sử dụng trực tiếp widget.currentUser.serverUrl như trong code của bạn
      final testController = VideoPlayerController.network(widget.currentUser.serverUrl);

      // Thử kết nối với timeout
      await testController.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Không nhận được tín hiệu video từ OBS');
        },
      );

      // Nếu thành công, đóng controller tạm
      testController.dispose();

      setState(() {
        _isVideoReady = true;
        _videoStatus = '✅ Đã nhận tín hiệu video từ OBS!';
      });

      _showSnackBar('Đã phát hiện video từ OBS. Có thể bắt đầu LIVE!');

    } catch (e) {
      setState(() {
        _isVideoReady = false;
        _videoStatus = '❌ Chưa có video từ OBS: ${e.toString()}';
      });

      _showSnackBar('Chưa nhận được video từ OBS. Hãy kiểm tra OBS đã bật stream chưa?');
    } finally {
      setState(() {
        _isCheckingVideo = false;
      });
    }
  }
  Future<void> _createOrUpdateStreamItem() async {
    final ref = FirebaseDatabase.instance
        .ref('streamItems/stream_${widget.currentUser.userId}');

    final streamItem = {
      "userId": widget.currentUser.userId,
      "name": widget.currentUser.name,
      "category": selectedCategory,
      "url": widget.currentUser.serverUrl,
      "isLiveNow": true,
      "colorHex": "#2196F3",
      "image": widget.currentUser.avatar,
      "streamTitle": titleController.text,
      "viewer": "0",
      "followers": widget.currentUser.followers.toString(),
      "coverImage": "",
      "post": "0",
      "following": "0",
      "description": widget.currentUser.description ?? "",
      "startedAt": ServerValue.timestamp,
    };

    await ref.set(streamItem);
  }


  void _startAutoCheckVideo() {
    // Tự động kiểm tra video mỗi 5 giây
    _videoCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isVideoReady && !_isCheckingVideo && !_isStreamerMode) {
        _checkOBSVideo();
      }
    });
  }

  // ===================== BẮT ĐẦU LIVE CHÍNH THỨC =====================
  Future<void> _startLiveBroadcast() async {
    if (!_isVideoReady) {
      _showSnackBar('Vui lòng đảm bảo OBS đã bật stream trước khi bắt đầu LIVE');
      return;
    }

    if (titleController.text.isEmpty) {
      _showSnackBar('Hãy nhập tiêu đề livestream');
      return;
    }

    if (selectedCategory == null) {
      _showSnackBar('Hãy chọn danh mục');
      return;
    }


    await _createOrUpdateStreamItem();

    _videoCheckTimer?.cancel();
    _initializeStreamerVideo();

    setState(() {
      _isStreamerMode = true;
    });

    _sendWelcomeMessage();
    _setupLiveViewerCounter();

    _showSnackBar('🎬 LIVE ĐÃ BẮT ĐẦU! Chào mừng khán giả!');
  }


  void _initializeStreamerVideo() {
    try {
      // Sử dụng widget.currentUser.serverUrl như trong code của bạn
      _videoController = VideoPlayerController.network(widget.currentUser.serverUrl)
        ..initialize().then((_) {
          if (!mounted) return;

          // ✅ FIXED: Sử dụng tỷ lệ THỰC của video, không ép theo màn hình
          final videoAspectRatio = _videoController!.value.aspectRatio;

          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: true,
            looping: true,
            showControls: true,
            allowFullScreen: true,
            // ✅ Sử dụng tỷ lệ khung hình thực của video
            aspectRatio: videoAspectRatio,
            showControlsOnInitialize: true,
            // ✅ Cấu hình placeholder
            placeholder: Container(
              color: Colors.grey[900],
              child: const Center(
                child: CircularProgressIndicator(color: Colors.purpleAccent),
              ),
            ),
            // ✅ Tự động điều chỉnh
            autoInitialize: true,
            allowedScreenSleep: false,
          );

          setState(() {});
        }).catchError((error) {
          print('Error loading stream: $error');
          _showSnackBar('Lỗi khi tải video: $error');
          setState(() {});
        });
    } catch (e) {
      _showSnackBar('Lỗi khi khởi tạo video: $e');
    }
  }

  // ===================== XỬ LÝ CHAT =====================
  void _sendWelcomeMessage() {
    ChatService.sendSystemMessage(
      streamId: widget.currentUser.userId, // Sử dụng userId làm streamId
      message: "🌟 ${widget.currentUser.name} đã bắt đầu live stream: ${titleController.text}",
    );
  }

  void _setupLiveViewerCounter() {
    final viewerRef = FirebaseDatabase.instance.ref('streams/${widget.currentUser.userId}/viewers');

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

    // Cập nhật số viewer định kỳ (mô phỏng)
    _viewerUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _isStreamerMode) {
        viewerRef.runTransaction((currentData) {
          int current = (currentData as int? ?? 1);
          // Ngẫu nhiên thay đổi số viewer
          final randomChange = (current * 0.1).toInt();
          current += randomChange;
          if (current < 1) current = 1;
          return Transaction.success(current);
        });
      }
    });
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
          // VIDEO PLAYER
          Positioned.fill(
            child: _buildCorrectedVideoPlayer(),
          ),

          // GRADIENT OVERLAY
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

          // TOP BAR: Thông tin stream
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(widget.currentUser.avatar),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          titleController.text,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // NÚT ĐÓNG STREAM (góc trái trên)
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: _endLiveStream,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stop, color: Colors.white, size: 24),
              ),
            ),
          ),

          // PANEL CHAT (bên phải)
          if (_showChat)
            Positioned(
              right: 10,
              top: 120,
              bottom: 20,
              width: 300,
              child: _buildChatPanel(),
            ),

          // NÚT TOGGLE CHAT (góc phải dưới)
          Positioned(
            bottom: 20,
            right: _showChat ? 320 : 20,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showChat = !_showChat;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _showChat ? Icons.chat : Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectedVideoPlayer() {
    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Chewie(controller: _chewieController!),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: CircularProgressIndicator(color: Colors.purpleAccent),
        ),
      );
    }
  }

  Widget _buildChatPanel() {
    return AnimatedContainer(
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
          // Header chat
          GestureDetector(
            onTap: () {
              setState(() {
                _isChatExpanded = !_isChatExpanded;
                _chatPanelHeight = _isChatExpanded
                    ? MediaQuery.of(context).size.height * 0.7
                    : 300;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Colors.purpleAccent, size: 18),
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
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.people_outline, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),

          // Danh sách tin nhắn
          Expanded(
            child: StreamBuilder(
              stream: ChatService.getStreamMessages(widget.currentUser.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.purpleAccent),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                  );
                }
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildSingleChatMessage(message);
                  },
                );
              },
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
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Nhắn tin với khán giả...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendChatMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.purpleAccent, Colors.blueAccent],
                      ),
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  void _endLiveStream() {
    // Dừng timer cập nhật viewer
    _viewerUpdateTimer?.cancel();

    // Giảm số viewer
    final viewerRef = FirebaseDatabase.instance.ref('streams/${widget.currentUser.userId}/viewers');
    viewerRef.runTransaction((currentData) {
      int current = (currentData as int? ?? 1) - 1;
      if (current < 0) current = 0;
      return Transaction.success(current);
    });

    // Gửi thông báo kết thúc stream
    ChatService.sendSystemMessage(
      streamId: widget.currentUser.userId,
      message: "🔴 ${widget.currentUser.name} đã kết thúc live stream",
    );

    // Dọn dẹp video controller
    _videoController?.dispose();
    _chewieController?.dispose();
    _videoController = null;
    _chewieController = null;

    // Quay lại màn hình chuẩn bị
    setState(() {
      _isStreamerMode = false;
      _isVideoReady = false;
      _videoStatus = 'Chưa kiểm tra';
      _liveViewerCount = 0;
    });

    // Bắt đầu lại timer kiểm tra video
    _startAutoCheckVideo();
    FirebaseDatabase.instance
        .ref('streamItems/stream_${widget.currentUser.userId}')
        .update({
      "isLiveNow": false,
      "endedAt": ServerValue.timestamp,
    });

    _showSnackBar('Đã kết thúc live stream');
  }

  // ===================== GIAO DIỆN CHUẨN BỊ =====================
  Widget _buildPreparationScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.transparent
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(widget.currentUser.avatar),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.currentUser.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${widget.currentUser.followers} followers',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue[900]!.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Server: ${Uri.parse(widget.currentUser.serverUrl).host}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // HƯỚNG DẪN OBS
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.computer,
                        size: 80,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'TRÌNH TỰ BẮT ĐẦU LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Bước 1: Cấu hình OBS
                      _buildStepCard(
                        number: 1,
                        title: 'Cấu hình OBS',
                        description: 'Mở OBS Studio → Settings → Stream\n'
                            'Server: ${widget.currentUser.serverUrl}',
                        icon: Icons.settings,
                      ),
                      const SizedBox(height: 15),

                      // Bước 2: Bật stream OBS
                      _buildStepCard(
                        number: 2,
                        title: 'Bật stream OBS',
                        description: 'Nhấn "Start Streaming" trong OBS\n'
                            'Chờ OBS kết nối thành công',
                        icon: Icons.play_arrow,
                      ),
                      const SizedBox(height: 15),

                      // Bước 3: Kiểm tra video
                      _buildStepCard(
                        number: 3,
                        title: 'Kiểm tra video',
                        description: 'Nhấn nút bên dưới để kiểm tra\n'
                            'Khi thấy "✅ Đã nhận tín hiệu" thì tiếp tục',
                        icon: Icons.videocam,
                      ),

                      const SizedBox(height: 25),

                      // NÚT KIỂM TRA VIDEO
                      Container(
                        width: double.infinity,
                        height: 55,
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        child: ElevatedButton.icon(
                          onPressed: _isCheckingVideo ? null : _checkOBSVideo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isVideoReady ? Colors.green : Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(
                            _isCheckingVideo
                                ? Icons.refresh
                                : (_isVideoReady ? Icons.check_circle : Icons.videocam),
                          ),
                          label: Text(
                            _isCheckingVideo
                                ? 'Đang kiểm tra...'
                                : (_isVideoReady ? '✅ VIDEO SẴN SÀNG' : 'KIỂM TRA VIDEO TỪ OBS'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // TRẠNG THÁI VIDEO
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _videoStatus,
                                style: TextStyle(
                                  color: _isVideoReady ? Colors.green : Colors.white70,
                                  fontSize: 14,
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

            // FORM NHẬP THÔNG TIN
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // TIÊU ĐỀ
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Nhập tiêu đề livestream...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.title, color: Colors.white54),
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 15),

                  // DANH MỤC
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.grey[900],
                    value: selectedCategory,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      hintText: "Chọn danh mục",
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.category, color: Colors.white54),
                    ),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: const TextStyle(color: Colors.white)),
                      ),
                    )
                        .toList(),
                    onChanged: (v) => setState(() => selectedCategory = v),
                  ),
                  const SizedBox(height: 20),

                  // NÚT BẮT ĐẦU LIVE
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _isVideoReady ? _startLiveBroadcast : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isVideoReady ? Colors.redAccent : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.live_tv, size: 24),
                      label: const Text(
                        "BẮT ĐẦU LIVE",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildStepCard({
    required int number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: Colors.blueAccent, size: 30),
        ],
      ),
    );
  }

  // ===================== TIỆN ÍCH =====================
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('✅') || message.contains('🎬')
            ? Colors.green
            : (message.contains('❌') ? Colors.red : Colors.blue),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nếu đang ở chế độ streamer, hiển thị control panel
    if (_isStreamerMode) {
      return _buildStreamerControlPanel();
    }

    // Ngược lại, hiển thị màn hình chuẩn bị
    return _buildPreparationScreen();
  }
}