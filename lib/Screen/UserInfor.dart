import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../Model/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'vod_player_screen.dart';
import 'package:untitled5/LoGinScreen.dart';
import 'package:untitled5/Model/model.dart';

class InfoUserScreen extends StatefulWidget {
  final User user;

  const InfoUserScreen({super.key, required this.user});

  @override
  State<InfoUserScreen> createState() => _InfoUserScreenState();
}

class _InfoUserScreenState extends State<InfoUserScreen> {
  late User _currentUser;
  List<Map<String, dynamic>> _serverVodList = [];
  bool _isLoadingVods = true;
  String? _firebaseUserId;
  bool _isLoading = false;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final Random _random = Random();
  String? _serverError;
  String _serverIp = '192.168.1.8'; // ĐỔI IP CỦA BẠN Ở ĐÂY

  // 🔹 Danh sách API avatar
  final List<String> _avatarAPIs = [
    'https://api.dicebear.com/7.x/avataaars/png?seed={SEED}&size=200&backgroundColor=65c9ff,b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf',
    'https://api.dicebear.com/7.x/micah/png?seed={SEED}&size=200',
    'https://api.dicebear.com/7.x/personas/png?seed={SEED}&size=200',
    'https://api.dicebear.com/7.x/bottts/png?seed={SEED}&size=200',
    'https://i.pravatar.cc/300?img={RANDOM}',
    'https://randomuser.me/api/portraits/men/{RANDOM}.jpg',
    'https://randomuser.me/api/portraits/women/{RANDOM}.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    print('👤 User loaded: ${_currentUser.name} (${_currentUser.email})');
    _loadVODsFromServer();
  }

  // 🔹 Tạo URL avatar ngẫu nhiên
  String _generateRandomAvatar() {
    final api = _avatarAPIs[_random.nextInt(_avatarAPIs.length)];
    final seed = '${_currentUser.email}_${DateTime.now().millisecondsSinceEpoch}';
    final randomNum = _random.nextInt(100);

    return api
        .replaceAll('{SEED}', seed)
        .replaceAll('{RANDOM}', randomNum.toString());
  }

  // 🔹 Tìm userId thực tế trong Firebase bằng email
  Future<String?> _findUserIdInFirebase() async {
    try {
      print('🔍 Searching userId for email: ${_currentUser.email}');

      final snapshot = await _dbRef.child('users').get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        // Cách 1: Tìm bằng email trực tiếp
        for (var entry in data.entries) {
          final key = entry.key.toString();
          final value = entry.value;

          // Bỏ qua các node đặc biệt
          if (key == 'chatHistory' || key == 'system') {
            print('⏭️ Skipping special node: $key');
            continue;
          }

          try {
            final userData = value as Map<dynamic, dynamic>;
            final userEmail = userData['email']?.toString() ?? '';

            if (userEmail == _currentUser.email) {
              print('✅ Found userId by email: $key');
              return key;
            }
          } catch (e) {
            print('⚠️ Error parsing user $key: $e');
          }
        }

        // Cách 2: Tìm bằng tên (fallback)
        print('🔄 Trying to find by name: ${_currentUser.name}');
        for (var entry in data.entries) {
          final key = entry.key.toString();
          final value = entry.value;

          if (key == 'chatHistory' || key == 'system') continue;

          try {
            final userData = value as Map<dynamic, dynamic>;
            final userName = userData['name']?.toString() ?? '';

            if (userName == _currentUser.name) {
              print('✅ Found userId by name: $key');
              return key;
            }
          } catch (e) {
            print('⚠️ Error parsing user $key: $e');
          }
        }
      }

      print('❌ No matching userId found in Firebase');
      return null;

    } catch (e) {
      print('❌ Error searching userId: $e');
      return null;
    }
  }
  Future<void> _logout() async {
    try {
      await auth.FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreenb()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đăng xuất thất bại ❌"),
        ),
      );
    }
  }


  // 🔹 Cập nhật avatar lên Firebase
  Future<void> _updateAvatar(String newAvatarUrl) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    print('🔄 Starting avatar update...');

    try {
      // 1. Tìm userId trong Firebase
      final userId = await _findUserIdInFirebase();

      if (userId == null) {
        print('❌ Cannot update: userId not found');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không tìm thấy thông tin user trong hệ thống'),
            backgroundColor: Colors.orange[800],
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      print('🎯 Updating for userId: $userId');

      // 2. Cập nhật trong node users
      await _dbRef.child('users').child(userId).update({
        'avatar': newAvatarUrl,
      });
      print('✅ Updated users/$userId/avatar');

      // 3. Cập nhật trong streamItems
      try {
        final streamItemsSnapshot = await _dbRef
            .child('streamItems')
            .orderByChild('userId')
            .equalTo(userId)
            .once();

        if (streamItemsSnapshot.snapshot.value != null) {
          final data = streamItemsSnapshot.snapshot.value as Map<dynamic, dynamic>;
          print('📊 Found ${data.length} stream items to update');

          for (var key in data.keys) {
            await _dbRef.child('streamItems').child(key.toString()).update({
              'image': newAvatarUrl,
            });
            print('✅ Updated streamItems/$key/image');
          }
        } else {
          print('ℹ️ No stream items found for this user');
        }
      } catch (e) {
        print('⚠️ Error updating streamItems: $e');
      }

      // 4. Cập nhật UI
      setState(() {
        _currentUser = User(
          userId: _currentUser.userId,
          name: _currentUser.name,
          email: _currentUser.email,
          avatar: newAvatarUrl,
          followers: _currentUser.followers,
          description: _currentUser.description,
          serverUrl: _currentUser.serverUrl,
        );
        _isLoading = false;
      });

      // 5. Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[800],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Avatar đã được cập nhật thành công!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

    } catch (error) {
      print('❌ Update error: $error');
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[900],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    error.toString().contains('Permission denied')
                        ? 'Lỗi: Không có quyền cập nhật database'
                        : 'Lỗi: Có vấn đề khi kết nối đến server',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ========== LOAD VODs TỪ SERVER - ĐÃ SỬA LỖI ==========
  Future<void> _loadVODsFromServer() async {
    if (mounted) {
      setState(() {
        _isLoadingVods = true;
        _serverError = null;
      });
    }

    try {
      // 1. Lấy userId thật trong Firebase
      final userId = await _findUserIdInFirebase();
      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoadingVods = false;
            _serverError = 'Không tìm thấy userId trong Firebase';
          });
        }
        return;
      }

      _firebaseUserId = userId;
      print('🎬 Loading VOD từ server: $_serverIp cho user: $userId');

      final response = await http.get(
        Uri.parse('http://$_serverIp/recordings/'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final links = document.querySelectorAll('a');

        final userLowerCase = userId.trim().toLowerCase(); // Tên biến đúng
        final currentUserVods = links
            .map((link) => link.attributes['href'] ?? '')
            .where((href) {
          final file = href.toLowerCase();
          // QUAN TRỌNG: Kiểm tra đúng pattern tên file
          return file.endsWith('.mp4') &&
              (file.startsWith('$userLowerCase-') ||
                  file.startsWith('${userLowerCase}_') ||
                  file.contains('_$userLowerCase'));
        })
            .map((fileName) => {
          'fileName': fileName,
          'downloadUrl': 'http://$_serverIp/recordings/$fileName',
        })
            .toList();

        if (mounted) {
          setState(() {
            _serverVodList = currentUserVods;
            _isLoadingVods = false;
          });
        }

        print('✅ Tìm thấy ${_serverVodList.length} file MP4 cho user $userLowerCase');

        // Debug: in tất cả file tìm thấy
        print('📁 Tất cả file MP4 trong server:');
        for (var link in links) {
          final href = link.attributes['href'] ?? '';
          if (href.toLowerCase().endsWith('.mp4')) {
            print('  - $href');
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _serverError = 'Lỗi server: ${response.statusCode}';
            _isLoadingVods = false;
          });
        }
      }
    } catch (error) {
      print('❌ Error loading VODs: $error');
      if (mounted) {
        setState(() {
          _serverError = 'Không thể kết nối server: $error';
          _isLoadingVods = false;
        });
      }
    }
  }

  // ========== PHƯƠNG THỨC XỬ LÝ VODs TỪ SERVER ==========
  void _playServerVOD(Map<String, dynamic> vodData) {
    final fileName = vodData['fileName'] as String;
    final downloadUrl = vodData['downloadUrl'] as String;

    // Tạo title từ tên file
    String title = _extractTitleFromFileName(fileName);

    // Tạo StreamItem từ VOD data - GIỐNG ProfileDetailScreen
    final vodItem = StreamItem(
      name: _currentUser.name,
      category: 'VOD',
      url: downloadUrl,
      isLiveNow: false,
      colorHex: '#FF4D67',
      image: _currentUser.avatar,
      streamTitle: title,
      viewer: '0',
      followers: _currentUser.followers.toString(),
      coverImage: _currentUser.avatar,
      post: '0',
      following: '0',
      description: 'Video đã ghi từ server',
      userId: _firebaseUserId ?? _currentUser.userId,
    );

    print('🎬 Opening Server VOD: $title');
    print('📁 URL: $downloadUrl');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VODPlayerScreen(
          streamItem: vodItem,
          user: _currentUser,
          vodUrl: downloadUrl,
        ),
      ),
    );
  }

  // ========== HELPER METHODS ==========
  String _extractTitleFromFileName(String fileName) {
    // Xóa .mp4
    String name = fileName.replaceAll('.mp4', '');

    // Xóa timestamp pattern: _YYYYMMDD_HHMMSS
    name = name.replaceAll(RegExp(r'_\d{8}_\d{6}'), '');

    // Xóa số ở cuối: -1, -2, etc
    name = name.replaceAll(RegExp(r'-\d+$'), '');

    // Tách userId nếu có
    if (name.contains('-')) {
      final parts = name.split('-');
      if (parts.length > 1) {
        name = parts.sublist(1).join('-');
      }
    }

    // Thay _ bằng space
    name = name.replaceAll('_', ' ');

    // Thay - bằng space
    name = name.replaceAll('-', ' ');

    // Capitalize first letter
    if (name.isNotEmpty) {
      name = name[0].toUpperCase() + name.substring(1);
    }

    return name.isNotEmpty ? name : 'Stream Recording';
  }

  // ========== HIỂN THỊ AVATAR PICKER ==========
  Future<void> _showAvatarPicker() async {
    if (_isLoading) return;

    List<String> sampleAvatars = List.generate(6, (index) => _generateRandomAvatar());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        title: const Center(
          child: Text(
            'Chọn Avatar Mới',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: sampleAvatars.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _updateAvatar(sampleAvatars[index]),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF4D67).withOpacity(0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          sampleAvatars[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                                color: const Color(0xFFFF4D67),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[900],
                              child: const Icon(
                                Icons.person,
                                color: Colors.white60,
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator(
                  color: Color(0xFFFF4D67),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'HỦY',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateAvatar(_generateRandomAvatar());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4D67),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'NGẪU NHIÊN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFF4D67),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/bg_login.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                const SizedBox(height: 110),

                // Avatar với click
                GestureDetector(
                  onTap: _isLoading ? null : _showAvatarPicker,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF4D67), Color(0xFFFF784E)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF4D67).withOpacity(0.6),
                                blurRadius: 25,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),

                        // Avatar image
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _isLoading
                                ? Container(
                              color: Colors.grey[900],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFF4D67),
                                ),
                              ),
                            )
                                : Image.network(
                              _currentUser.avatar.isNotEmpty
                                  ? _currentUser.avatar
                                  : "https://cdn-icons-png.flaticon.com/512/1144/1144760.png",
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress
                                        .expectedTotalBytes !=
                                        null
                                        ? loadingProgress
                                        .cumulativeBytesLoaded /
                                        loadingProgress
                                            .expectedTotalBytes!
                                        : null,
                                    color: const Color(0xFFFF4D67),
                                  ),
                                );
                              },
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[900],
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white70,
                                    size: 50,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Edit icon
                        if (!_isLoading)
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4D67),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  _currentUser.name.isNotEmpty ? _currentUser.name : "No Name",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "@${_currentUser.email} • ${_currentUser.followers} Followers",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 30),
                _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UserInfoRow("Email", _currentUser.email),
                      _UserInfoRow("Server", _serverIp),
                      _UserInfoRow("User ID", _firebaseUserId ?? _currentUser.userId),
                      _UserInfoRow("Description", _currentUser.description),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _glassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _UserStatBox("Streams", _serverVodList.length.toString()),
                      _UserStatBox(
                          "Followers", _currentUser.followers.toString()),
                      _UserStatBox("Following", "0"),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child:ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Đăng xuất",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _showAvatarPicker,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text(
                      "Change Avatar",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Video Recordings",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // ========== HIỂN THỊ VODs TỪ SERVER ==========
                if (_isLoadingVods)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Color(0xFFFF4D67)),
                    ),
                  )
                else if (_serverError != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _serverError!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadVODsFromServer,
                          child: const Text(
                            'Thử lại',
                            style: TextStyle(
                              color: Color(0xFFFF4D67),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_serverVodList.isEmpty)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.video_library_outlined,
                              color: Colors.white54,
                              size: 60,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Chưa có video nào",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "User ID: ${_firebaseUserId ?? _currentUser.userId}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "Server: $_serverIp",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.video_file,
                                color: Color(0xFFFF4D67),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "recordings (${_serverVodList.length})",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: _loadVODsFromServer,
                                icon: const Icon(Icons.refresh,
                                    color: Colors.white54, size: 18),
                                label: const Text(
                                  'Refresh',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GridView.builder(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _serverVodList.length,
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemBuilder: (context, index) {
                            final vodData = _serverVodList[index];
                            final fileName = vodData['fileName'] as String;
                            final title = _extractTitleFromFileName(fileName);

                            return _buildVodCard(vodData, title, fileName);
                          },
                        ),
                      ],
                    ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CARD CHO VOD - GIỐNG ProfileDetailScreen
  Widget _buildVodCard(Map<String, dynamic> vodData, String title, String fileName) {
    return GestureDetector(
      onTap: () => _playServerVOD(vodData),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
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
                              color: const Color(0xFFFF4D67)
                                  .withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Color(0xFFFF4D67),
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'MP4',
                            style: TextStyle(
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
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4D67),
                          borderRadius:
                          BorderRadius.circular(4),
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
                    children: [
                      const Icon(
                        Icons.person,
                        color: Colors.white54,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _currentUser.name,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.video_file,
                        color: Colors.white54,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          fileName.length > 20
                              ? '${fileName.substring(0, 20)}...'
                              : fileName,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
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
}

// Glass Card Widget
Widget _glassCard({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.15)),
    ),
    child: child,
  );
}

// User Info Row Widget
class _UserInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _UserInfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value.isNotEmpty ? value : "Not set",
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// User Stat Box Widget
class _UserStatBox extends StatelessWidget {
  final String title;
  final String count;

  const _UserStatBox(this.title, this.count);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}