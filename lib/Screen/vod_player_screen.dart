import 'dart:ui';
import 'package:flutter/material.dart';
import '../Model/model.dart';
import 'package:untitled5/Model/user.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VODPlayerScreen extends StatefulWidget {
  final StreamItem streamItem;
  final User user;
  final String vodUrl;

  VODPlayerScreen({
    super.key,
    required this.streamItem,
    required this.user,
    required this.vodUrl,
  });

  @override
  State<StatefulWidget> createState() {
    return _VODPlayerScreenState();
  }
}

class _VODPlayerScreenState extends State<VODPlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _isPlaying = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    print('🎬 Loading VOD from: ${widget.vodUrl}');
    print('📁 File extension: ${widget.vodUrl.split('.').last}');

    // Kiểm tra URL
    if (!widget.vodUrl.startsWith('http')) {
      _showError('URL không hợp lệ: ${widget.vodUrl}');
      return;
    }

    // Kiểm tra định dạng
    final supportedFormats = ['mp4', 'm4v', 'mov', 'avi'];
    final fileExt = widget.vodUrl.split('.').last.toLowerCase();

    if (!supportedFormats.contains(fileExt)) {
      _showError('Định dạng không hỗ trợ: .$fileExt');
      return;
    }

    print('✅ URL và định dạng OK');

    _videoController = VideoPlayerController.network(
      widget.vodUrl,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )
      ..initialize().then((_) {
        print('✅ Video initialized successfully');
        print('📊 Duration: ${_videoController.value.duration}');
        print('🎞️ Aspect ratio: ${_videoController.value.aspectRatio}');

        if (_videoController.value.hasError) {
          _showError(_videoController.value.errorDescription ?? 'Lỗi tải video');
          return;
        }

        final videoAspectRatio = _videoController.value.aspectRatio;

        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: false,
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
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
          additionalOptions: (context) => [
            OptionItem(
              onTap: (context) => _changePlaybackSpeed(0.5),
              iconData: Icons.slow_motion_video,
              title: '0.5x',
            ),
            OptionItem(
              onTap: (context) => _changePlaybackSpeed(1.0),
              iconData: Icons.speed,
              title: '1.0x',
            ),
            OptionItem(
              onTap: (context) => _changePlaybackSpeed(1.5),
              iconData: Icons.fast_forward,
              title: '1.5x',
            ),
            OptionItem(
              onTap: (context) => _changePlaybackSpeed(2.0),
              iconData: Icons.double_arrow,
              title: '2.0x',
            ),
          ],
        );

        setState(() {
          _isLoading = false;
        });
      }).catchError((error) {
        print('❌ Error loading VOD: $error');
        _showError('Không thể tải video: $error');
      });
  }

  void _showError(String message) {
    print('❌ $message');
    setState(() {
      _hasError = true;
      _errorMessage = message;
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _changePlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _videoController.setPlaybackSpeed(speed);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tốc độ phát: ${speed}x'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _videoController.play();
    } else {
      _videoController.pause();
    }
  }

  String _formatDate(dynamic value) {
    try {
      DateTime date;

      if (value is String) {
        date = DateTime.parse(value);
      } else if (value is int) {
        date = DateTime.fromMillisecondsSinceEpoch(value);
      } else {
        date = value.toDate();
      }

      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Không xác định';
    }
  }

  void _seekForward() {
    final currentPosition = _videoController.value.position;
    final duration = _videoController.value.duration;
    final newPosition = currentPosition + const Duration(seconds: 10);

    if (newPosition < duration) {
      _videoController.seekTo(newPosition);
    } else {
      _videoController.seekTo(duration);
    }
  }

  void _seekBackward() {
    final currentPosition = _videoController.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);

    if (newPosition > Duration.zero) {
      _videoController.seekTo(newPosition);
    } else {
      _videoController.seekTo(Duration.zero);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Widget _buildVideoPlayer() {
    if (_hasError) {
      return _buildErrorScreen();
    }

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

          // Custom controls overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Current time
                  StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      final position = _videoController.value.position;
                      final duration = _videoController.value.duration;

                      return Text(
                        '${_formatDuration(position)} / ${_formatDuration(duration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // Speed indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_playbackSpeed}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              'Không thể phát video',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text(
                'Quay lại',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _errorMessage = '';
                });
                _initializeVideoPlayer();
              },
              child: const Text(
                'Thử lại',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // VIDEO PLAYER hoặc ERROR SCREEN
          Positioned.fill(
            child: _buildVideoPlayer(),
          ),

          // Chỉ hiển thị UI khi không có lỗi
          if (!_hasError && !_isLoading)
            Column(
              children: [
                // Gradient overlay
                Container(
                  height: 100,
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
                Expanded(child: Container()),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),

          // Header (chỉ hiển thị khi không có lỗi)
          if (!_hasError && !_isLoading)
            Positioned(
              top: 50,
              left: 15,
              right: 15,
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
                        size: 24,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // User info
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(widget.streamItem.image),
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
                                "VOD • ${widget.streamItem.viewer} views",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent, // Màu xanh cho MP4
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "MP4",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Video title (chỉ hiển thị khi không có lỗi)
          if (!_hasError && !_isLoading)
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

          // Custom controls (chỉ hiển thị khi không có lỗi)
          if (!_hasError && !_isLoading)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Backward 10s
                  GestureDetector(
                    onTap: _seekBackward,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.replay_10,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),

                  const SizedBox(width: 30),

                  // Play/Pause
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                  const SizedBox(width: 30),

                  // Forward 10s
                  GestureDetector(
                    onTap: _seekForward,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.forward_10,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // VOD actions (chỉ hiển thị khi không có lỗi)
          if (!_hasError && !_isLoading)
            Positioned(
              bottom: 120,
              right: 15,
              child: Column(
                children: [
                  _buildVODActionButton(
                    icon: Icons.download,
                    label: "Download",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tính năng download sẽ có trong phiên bản tới'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildVODActionButton(
                    icon: Icons.share,
                    label: "Share",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Chia sẻ VOD: ${widget.streamItem.streamTitle}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildVODActionButton(
                    icon: Icons.info_outline,
                    label: "Info",
                    onTap: () {
                      _showVODInfo();
                    },
                  ),
                ],
              ),
            ),

          // Loading indicator
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.purpleAccent),
                      SizedBox(height: 16),
                      Text(
                        'Đang tải VOD...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVODActionButton({
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

  void _showVODInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thông tin VOD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.title, color: Colors.white54),
                title: const Text('Tiêu đề', style: TextStyle(color: Colors.white54)),
                subtitle: Text(
                  widget.streamItem.streamTitle,
                  style: const TextStyle(color: Colors.white),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.category, color: Colors.white54),
                title: const Text('Danh mục', style: TextStyle(color: Colors.white54)),
                subtitle: Text(
                  widget.streamItem.category,
                  style: const TextStyle(color: Colors.white),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.white54),
                title: const Text('Lượt xem', style: TextStyle(color: Colors.white54)),
                subtitle: Text(
                  widget.streamItem.viewer,
                  style: const TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 20),

              if (widget.vodUrl.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.link, color: Colors.white54),
                  title: const Text('Video URL', style: TextStyle(color: Colors.white54)),
                  subtitle: GestureDetector(
                    onTap: () {
                      // Copy to clipboard
                    },
                    child: Text(
                      widget.vodUrl.length > 50
                          ? '${widget.vodUrl.substring(0, 50)}...'
                          : widget.vodUrl,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}