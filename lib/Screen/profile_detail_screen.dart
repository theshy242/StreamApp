import 'dart:ui';
import 'package:flutter/material.dart';
import '../Model/model.dart';
import 'live_stream_screen.dart';
import 'vod_player_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:untitled5/Model/user.dart';
import 'package:html/parser.dart' as parser;

class ProfileDetailScreen extends StatefulWidget {
  final StreamItem streamItem;
  const ProfileDetailScreen({super.key, required this.streamItem});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  User? currentUser;

  // ========== THÊM STATE CHO VODs ==========
  late TabController _tabController;
  List<StreamItem> _pastStreams = []; // Stream đã kết thúc = VODs (giữ nguyên)
  bool _isLoadingVODs = true;

  // THÊM STATE MỚI CHO SERVER VODs
  List<Map<String, dynamic>> _serverVodList = [];
  bool _isLoadingServerVODs = true;
  String? _serverError;
  String _serverIp = '172.16.12.54'; // THAY ĐỔI IP CỦA BẠN Ở ĐÂY

  // Database reference - GIỐNG NHƯ HOME SCREEN
  static FirebaseDatabase? _database;
  DatabaseReference get streamsDbRef => _database!.ref().child('streamItems');
  DatabaseReference get usersDbRef => _database!.ref().child('users');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeDatabase();
    _fetchUserData();
    _loadPastStreams(); // Load VODs từ Firebase (giữ nguyên)
    _loadVODsFromServer(); // THÊM: Load VODs từ server
  }

  void _initializeDatabase() {
    // GIỐNG LOGIC TRONG HOME SCREEN
    _database ??= FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: "https://livestream-app-32b54-default-rtdb.firebaseio.com/",
    );
  }

  Future<void> _fetchUserData() async {
    print("🔍 Bắt đầu fetch user data cho: ${widget.streamItem.userId}");

    try {
      final snapshot = await usersDbRef.child(widget.streamItem.userId).get();

      if (snapshot.exists) {
        print("✅ Tìm thấy user trong Firebase");
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          currentUser = User.fromJson(userData);
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

  // ========== LOAD VODs TỪ SERVER - ĐÃ SỬA ==========
  Future<void> _loadVODsFromServer() async {
    if (mounted) {
      setState(() {
        _isLoadingServerVODs = true;
        _serverError = null;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('http://$_serverIp/recordings/'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final links = document.querySelectorAll('a');
        final userId = widget.streamItem.userId.trim().toLowerCase();

        final currentUserVods = links
            .map((link) => link.attributes['href'] ?? '')
            .where((href) {
          final file = href.toLowerCase();
          return file.endsWith('.mp4') &&
              file.startsWith('$userId-');
        })
            .map((fileName) => {
          'fileName': fileName,
          'downloadUrl': 'http://$_serverIp/recordings/$fileName',
        })
            .toList();


        if (mounted) {
          setState(() {
            _serverVodList = currentUserVods;
            _isLoadingServerVODs = false;
          });
        }

        print("✅ Tìm thấy ${_serverVodList.length} file MP4 cho user ${widget.streamItem.userId}");
      } else {
        if (mounted) {
          setState(() {
            _serverError = 'Lỗi server: ${response.statusCode}';
            _isLoadingServerVODs = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _serverError = 'Không thể kết nối server: $error';
          _isLoadingServerVODs = false;
        });
      }
    }
  }

  // ========== LOAD VODs - LOGIC TƯƠNG TỰ HOME SCREEN (GIỮ NGUYÊN) ==========
  void _loadPastStreams() {
    print("🔄 Bắt đầu load VODs từ Firebase cho user: ${widget.streamItem.userId}");

    streamsDbRef.onValue.listen((DatabaseEvent event) {
      print("📥 Streams data received for VODs");

      final data = event.snapshot.value;

      if (data == null) {
        print("⚠️ No streams data in Firebase");
        if (mounted) {
          setState(() {
            _pastStreams = [];
            _isLoadingVODs = false;
          });
        }
        return;
      }

      try {
        final dataMap = data as Map<dynamic, dynamic>;
        print("✅ Streams data map length: ${dataMap.length}");

        final List<StreamItem> tempList = [];

        dataMap.forEach((key, value) {
          try {
            final itemData = Map<String, dynamic>.from(value);
            final streamItem = StreamItem.fromJson(itemData);

            if (streamItem.userId == widget.streamItem.userId &&
                !streamItem.isLiveNow) {
              tempList.add(streamItem);
              print("📁 Thêm VOD từ Firebase: ${streamItem.streamTitle}");
            }
          } catch (e) {
            print("⚠️ Error parsing stream $key: $e");
          }
        });

        if (mounted) {
          setState(() {
            _pastStreams = tempList;
            _isLoadingVODs = false;
          });
          print("🎉 Loaded ${_pastStreams.length} VODs từ Firebase");
        }

      } catch (e) {
        print("❌ VODs data processing error: $e");
        if (mounted) {
          setState(() {
            _pastStreams = [];
            _isLoadingVODs = false;
          });
        }
      }
    }, onError: (error) {
      print("❌ VODs listener error: $error");
      if (mounted) {
        setState(() {
          _isLoadingVODs = false;
        });
      }
    });
  }

  // ========== PHƯƠNG THỨC XỬ LÝ VODs TỪ SERVER ==========
  void _playServerVOD(Map<String, dynamic> vodData) {
    if (currentUser == null) {
      _createFallbackUser();
    }

    final fileName = vodData['fileName'] as String;
    final downloadUrl = vodData['downloadUrl'] as String;

    // Tạo title từ tên file
    String title = _extractTitleFromFileName(fileName);

    // Tạo StreamItem từ VOD data
    final vodItem = StreamItem(
      name: widget.streamItem.name,
      category: 'VOD',
      url: downloadUrl,
      isLiveNow: false,
      colorHex: widget.streamItem.colorHex,
      image: widget.streamItem.image,
      streamTitle: title,
      viewer: '0',
      followers: widget.streamItem.followers,
      coverImage: widget.streamItem.coverImage,
      post: widget.streamItem.post,
      following: widget.streamItem.following,
      description: 'Video đã ghi từ server',
      userId: widget.streamItem.userId,
    );

    print("🎬 Opening Server VOD: $title");
    print("📁 URL: $downloadUrl");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VODPlayerScreen(
          streamItem: vodItem,
          user: currentUser!,
          vodUrl: downloadUrl,
        ),
      ),
    );
  }

  // ========== PHƯƠNG THỨC XỬ LÝ VODs TỪ FIREBASE ==========
  void _playVOD(StreamItem vodItem) {
    if (currentUser == null) {
      _createFallbackUser();
    }

    // Tạo URL VOD từ server NGINX
    String getVODUrl() {
      final safeTitle = vodItem.streamTitle
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_')
          .toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'http://$_serverIp/vods/stream_${vodItem.userId}_${safeTitle}_$timestamp.mp4';
    }

    final vodUrl = getVODUrl();
    print("🎬 Opening Firebase VOD: $vodUrl");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VODPlayerScreen(
          streamItem: vodItem,
          user: currentUser!,
          vodUrl: vodUrl,
        ),
      ),
    );
  }

  // ========== CÁC HELPER METHODS ==========
  String _extractTitleFromFileName(String fileName) {
    // SỬA: Xử lý file .mp4
    String name = fileName.replaceAll('.mp4', '');
    name = name.replaceAll(RegExp(r'_\d{8}_\d{6}'), '');
    name = name.replaceAll(RegExp(r'-\d+'), '');

    if (name.contains('-')) {
      name = name.substring(name.indexOf('-') + 1);
    }

    name = name.replaceAll('_', ' ');
    name = name.replaceAll('-', ' ');

    if (name.isNotEmpty) {
      name = name[0].toUpperCase() + name.substring(1);
    }

    return name.isNotEmpty ? name : 'Stream Recording';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  String _formatDateFromTimestamp(int timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) return 'Hôm nay';
      if (difference.inDays == 1) return 'Hôm qua';
      if (difference.inDays < 7) return '${difference.inDays} ngày trước';
      if (difference.inDays < 30) return '${(difference.inDays / 7).ceil()} tuần trước';
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Không xác định';
    }
  }

  // Format date cho VOD từ Firebase (dựa trên index)
  String _formatDateForVOD(int index) {
    final daysAgo = index + 1;
    if (daysAgo == 1) return 'Hôm qua';
    if (daysAgo == 2) return '2 ngày trước';
    if (daysAgo <= 7) return '$daysAgo ngày trước';
    if (daysAgo <= 30) return '${(daysAgo / 7).ceil()} tuần trước';
    return '${(daysAgo / 30).ceil()} tháng trước';
  }

  void _createFallbackUser() {
    setState(() {
      currentUser = User(
        userId: widget.streamItem.userId,
        name: widget.streamItem.name,
        email: "${widget.streamItem.name.toLowerCase().replaceAll(' ', '')}@example.com",
        avatar: widget.streamItem.image,
        followers: <String>[],
        serverUrl: widget.streamItem.url,
        description: widget.streamItem.description,
      );
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
      _createFallbackUser();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamScreen(
          streamItem: widget.streamItem,
          currentUser: currentUser!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeaderSection(size),
                  const SizedBox(height: 80),
                  _buildDescriptionSection(),
                  const SizedBox(height: 30),
                  _buildStatsSection(size),
                  const SizedBox(height: 30),
                ],
              ),
            ),

            // TabBar
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                child: Container(
                  color: Colors.black,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.purpleAccent,
                    labelColor: Colors.purpleAccent,
                    unselectedLabelColor: Colors.white54,
                    tabs: const [
                      Tab(text: 'Live Stream'),
                      Tab(text: 'VODs'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: LIVE STREAM
            _buildLiveStreamTab(),

            // TAB 2: VODs
            _buildVODsTab(),
          ],
        ),
      ),
    );
  }

  // ========== TAB VODs ==========
  Widget _buildVODsTab() {
    // Nếu đang tải cả hai
    if (_isLoadingVODs && _isLoadingServerVODs) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.purpleAccent),
            SizedBox(height: 16),
            Text(
              'Đang tải VODs...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final totalVODs = _pastStreams.length + _serverVodList.length;

    if (totalVODs == 0 && _serverError == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              color: Colors.white54,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có VODs nào',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // HIỂN THỊ VODs TỪ SERVER NẾU CÓ
        if (_serverVodList.isNotEmpty || _serverError != null)
          _buildServerVODsSection(),

        // HIỂN THỊ VODs TỪ FIREBASE NẾU CÓ
        if (_pastStreams.isNotEmpty)
          _buildFirebaseVODsSection(),
      ],
    );
  }

  // SECTION VODs TỪ SERVER
  Widget _buildServerVODsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(
                Icons.storage,
                color: Colors.purpleAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Recordings từ Server',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_serverError != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  onPressed: _loadVODsFromServer,
                ),
            ],
          ),
        ),

        // Error message
        if (_serverError != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _serverError!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _loadVODsFromServer,
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(color: Colors.purpleAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // Grid VODs từ server
        if (_serverVodList.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: _serverVodList.length,
            itemBuilder: (context, index) {
              return _buildServerVodCard(_serverVodList[index]);
            },
          ),

        const SizedBox(height: 24),
      ],
    );
  }

  // SECTION VODs TỪ FIREBASE
  Widget _buildFirebaseVODsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(
                Icons.cloud,
                color: Colors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Stream đã kết thúc',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_pastStreams.length} video',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // List VODs từ Firebase
        ..._pastStreams.asMap().entries.map((entry) {
          final index = entry.key;
          final vod = entry.value;
          return _buildVODCard(vod, index);
        }).toList(),
      ],
    );
  }

  // CARD CHO VOD TỪ SERVER - ĐÃ SỬA
  Widget _buildServerVodCard(Map<String, dynamic> vod) {
    final fileName = vod['fileName'] as String;
    final downloadUrl = vod['downloadUrl'] as String;
    final title = _extractTitleFromFileName(fileName);

    return GestureDetector(
      onTap: () => _playServerVOD(vod),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey[800],
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.blueAccent,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'MP4',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'MP4',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: Colors.white54,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.streamItem.userId,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          const Icon(
                            Icons.video_file,
                            color: Colors.white54,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'MP4',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CARD CHO VOD TỪ FIREBASE
  Widget _buildVODCard(StreamItem vod, int index) {
    return GestureDetector(
      onTap: () => _playVOD(vod),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    vod.coverImage.isNotEmpty ? vod.coverImage : vod.image,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(
                            Icons.videocam_outlined,
                            color: Colors.white54,
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircleAvatar(
                        backgroundColor: Colors.purpleAccent,
                        radius: 24,
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'VOD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
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
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.remove_red_eye,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vod.viewer,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vod.streamTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.purpleAccent),
                        ),
                        child: Text(
                          vod.category,
                          style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 11,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white54,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateForVOD(index),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== CÁC PHẦN GIỮ NGUYÊN ==========
  Widget _buildHeaderSection(Size size) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
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
        ),

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
            ),
          ),
        ),

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

        Positioned(
          bottom: -40,
          right: 20,
          child: GestureDetector(
            onTap: () {
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

  Widget _buildLiveStreamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}