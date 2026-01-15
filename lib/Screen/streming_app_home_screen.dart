      import 'dart:async';
      import 'dart:ui';
      import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
      import 'package:flutter/material.dart';
      import 'package:firebase_core/firebase_core.dart';
      import 'package:firebase_database/firebase_database.dart';
      import 'package:untitled5/Screen/UserInfor.dart';
      import '../AI_Chat/chat_screen.dart';
      import '../Constants/colors.dart';
      import '../Notification/notification_screen.dart';
import 'live_stream_screen.dart';
      import 'profile_detail_screen.dart';
      import 'package:untitled5/Model/StreamCategory.dart';
      import 'package:untitled5/Model/model.dart';
      import 'package:untitled5/Model/user.dart';
      import 'package:untitled5/Screen/LivePrepareScreen.dart';

      class StremingAppHomeScreen extends StatefulWidget {
        const StremingAppHomeScreen({super.key});

        @override
        State<StremingAppHomeScreen> createState() => _StremingAppHomeScreenState();
      }

      class _StremingAppHomeScreenState extends State<StremingAppHomeScreen> {
        String selectedCategory = "Popular";

        List<StreamItem> streamItems = [];
        List<StreamItem> allStreams = [];
        List<StreamCategory> categories = [];
        bool isLoading = true;
        bool isInitializing = true;

        // Stream subscriptions để tránh memory leak
        StreamSubscription? _streamsSubscription;
        StreamSubscription? _categoriesSubscription;

        // Sử dụng single database instance
        static FirebaseDatabase? _database;
        DatabaseReference get streamsDbRef => _database!.ref().child('streamItems');
        DatabaseReference get categoriesDbRef => _database!.ref().child('categories');
        DatabaseReference get usersDbRef => _database!.ref().child('users');

        @override
        void initState() {
          super.initState();
          _initializeApp();
        }

        Future<void> _initializeApp() async {
          try {
            print('🟡 Initializing App...');

            // Initialize Firebase nếu chưa có
            if (Firebase.apps.isEmpty) {
              await Firebase.initializeApp();
              print('✅ Firebase initialized');
            }

            // Tạo database instance một lần
            _database ??= FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: "https://livestream-app-32b54-default-rtdb.firebaseio.com/",
            );

            // Tải dữ liệu mặc định ngay lập tức để có UI nhanh
            _loadDefaultCategories();

            // Thiết lập listeners
            _setupFirebaseListeners();

            setState(() {
              isInitializing = false;
            });

          } catch (e) {
            print('❌ App initialization error: $e');
            _loadMockData();
            setState(() {
              isInitializing = false;
            });
          }
        }

        void _setupFirebaseListeners() {
          print('🎯 Setting up Firebase listeners...');

          // Hủy subscriptions cũ nếu có
          _streamsSubscription?.cancel();
          _categoriesSubscription?.cancel();

          // Lắng nghe dữ liệu streams với debounce
          _streamsSubscription = streamsDbRef.onValue.listen((DatabaseEvent event) {
            print('🔵 Streams data received');

            final data = event.snapshot.value;

            if (data == null) {
              print('⚠️ No streams data in Firebase, using mock data');
              _loadMockData();
              return;
            }

            try {
              final dataMap = data as Map<dynamic, dynamic>;
              print('✅ Streams data map length: ${dataMap.length}');

              final List<StreamItem> tempList = [];
              dataMap.forEach((key, value) {
                try {
                  final itemData = Map<String, dynamic>.from(value);
                  final streamItem = StreamItem.fromJson(itemData);
                  tempList.add(streamItem);
                } catch (e) {
                  print('⚠️ Error parsing stream $key: $e');
                }
              });

              if (mounted) {
                setState(() {
                  allStreams = tempList;
                  _filterStreams();
                  isLoading = false;
                });
                print('🎉 Loaded ${allStreams.length} streams');
              }

            } catch (e) {
              print('❌ Streams data processing error: $e');
              if (mounted) {
                _loadMockData();
              }
            }
          }, onError: (error) {
            print('❌ Streams listener error: $error');
            if (mounted) {
              _loadMockData();
            }
          });

          // Lắng nghe dữ liệu categories
          _categoriesSubscription = categoriesDbRef.onValue.listen((DatabaseEvent event) {
            print('🟣 Categories data received');

            final data = event.snapshot.value;

            if (data == null) {
              print('⚠️ No categories data in Firebase, using default');
              return;
            }

            try {
              final dataMap = data as Map<dynamic, dynamic>;
              final List<StreamCategory> tempCategories = [];

              dataMap.forEach((key, value) {
                try {
                  final categoryData = Map<String, dynamic>.from(value);
                  final category = StreamCategory.fromJson(categoryData);
                  tempCategories.add(category);
                } catch (e) {
                  print('⚠️ Error parsing category $key: $e');
                }
              });

              if (mounted) {
                setState(() {
                  categories = tempCategories;
                  if (categories.isNotEmpty) {
                    selectedCategory = categories.first.title;
                    _filterStreams();
                  }
                });
                print('✅ Loaded ${categories.length} categories');
              }

            } catch (e) {
              print('❌ Categories data processing error: $e');
            }
          }, onError: (error) {
            print('❌ Categories listener error: $error');
          });
        }

        void _loadDefaultCategories() {
          if (categories.isNotEmpty) return;

          final defaultCategories = [
            StreamCategory(title: "Popular"),
            StreamCategory(title: "Gaming"),
            StreamCategory(title: "Sports"),
            StreamCategory(title: "Music"),
          ];

          if (mounted) {
            setState(() {
              categories = defaultCategories;
            });
          }
        }

        void _loadMockData() {
          print('🔄 Loading mock data...');
          final mockItems = [
            StreamItem(
              name: 'Randy Rangers',
              category: 'Popular',
              url: 'https://symbl-cdn.com/i/webp/ef/717de6be0d2c9eb4d9d91521542da2.webp',
              isLiveNow: true,
              colorHex: '#2196F3',
              image: 'https://media.istockphoto.com/id/1452486049/photo/young-woman-plays-video-game-online-and-streaming-at-home.jpg',
              streamTitle: 'Yeay Update Ep Ep',
              viewer: '1.2k',
              followers: '132k',
              coverImage: 'https://st2.depositphotos.com/1662991/45473/i/450/depositphotos_454739980-stock-photo-caucasian-woman-gamer-headphones-using.jpg',
              post: '950',
              following: '879',
              description: 'I am a gamer, I often do live streaming when I play games',
              userId: 'user_01',
            ),
            StreamItem(
              name: 'Aura Kirana',
              category: 'Gaming',
              url: 'https://symbl-cdn.com/i/webp/9c/4628a5e254c186333877e3449d1caf.webp',
              isLiveNow: true,
              colorHex: '#448AFF',
              image: 'https://st2.depositphotos.com/1662991/45473/i/450/depositphotos_454739980-stock-photo-caucasian-woman-gamer-headphones-using.jpg',
              streamTitle: 'Mabar With Ayang',
              viewer: '1.5k',
              followers: '159k',
              coverImage: 'https://media.istockphoto.com/id/1452486049/photo/young-woman-plays-video-game-online-and-streaming-at-home.jpg',
              post: '50',
              following: '79',
              description: 'I am a gamer, I often do live streaming when I play games',
              userId: 'user_02',
            ),
          ];

          if (mounted) {
            setState(() {
              allStreams = mockItems;
              _filterStreams();
              isLoading = false;
            });
          }
        }

        void _filterStreams() {
          if (selectedCategory == "Popular") {
            streamItems = allStreams
                .where((item) => item.isLiveNow)
                .toList();
          } else {
            streamItems = allStreams
                .where((item) =>
            item.category == selectedCategory && item.isLiveNow)
                .toList();
          }
        }


        void selectCategory(String category) {
          if (selectedCategory != category && mounted) {
            setState(() {
              selectedCategory = category;
              _filterStreams();
            });
          }
        }

        @override
        void dispose() {
          // Hủy tất cả subscriptions để tránh memory leak
          _streamsSubscription?.cancel();
          _categoriesSubscription?.cancel();
          super.dispose();
        }

        // Helper function để tìm user
        Future<User?> _findCurrentUser() async {
          final fbAuth.User? firebaseUser = fbAuth.FirebaseAuth.instance.currentUser;
          if (firebaseUser == null) return null;

          try {
            // Phương pháp 1: Tìm trong user_mapping
            final mappingRef = _database!.ref().child('user_mapping');
            final mappingSnapshot = await mappingRef.child(firebaseUser.uid).get();

            if (mappingSnapshot.exists) {
              final mappingData = Map<String, dynamic>.from(mappingSnapshot.value as Map);
              final simpleUserId = mappingData['simpleUserId'] as String;

              final userSnapshot = await usersDbRef.child(simpleUserId).get();
              if (userSnapshot.exists) {
                final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
                return User.fromJson(userData);
              }
            }

            // Phương pháp 2: Duyệt qua tất cả users
            final usersSnapshot = await usersDbRef.get();
            if (usersSnapshot.exists) {
              final allUsers = usersSnapshot.value as Map<dynamic, dynamic>;

              for (var entry in allUsers.entries) {
                final key = entry.key.toString();
                final value = entry.value;

                if (key == "chatHistory" || key == "system") continue;

                try {
                  final userData = Map<String, dynamic>.from(value);

                  if (userData['firebaseUid'] == firebaseUser.uid) {
                    return User.fromJson(userData);
                  }

                  if (userData['email'] == firebaseUser.email) {
                    return User.fromJson(userData);
                  }
                } catch (e) {
                  print("⚠️ Lỗi parse user $key: $e");
                }
              }
            }
          } catch (e) {
            print('❌ Error finding user: $e');
          }

          return null;
        }

        @override
        Widget build(BuildContext context) {
          if (isInitializing) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Initializing app...",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          if (isLoading) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Loading streams...",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildCategoryWidget(),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _buildContent(),
                      ),
                    ],
                  ),
                ),

                // 🤖 CHATBOX AI BUTTON
                Positioned(
                  bottom: 0,
                  right: 20,
                  child: FloatingActionButton(
                    heroTag: "ai_chat",
                    backgroundColor: Colors.deepPurple,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatScreen(),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomNav(),
          );
        }

        Widget _buildHeader() {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "GoLive",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () async {
                    final user = await _findCurrentUser();

                    if (user == null) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Vui lòng đăng nhập để xem thông báo"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationScreen(
                          currentUser: user, //
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }

        Widget _buildIconButton(IconData icon) {
          return CircleAvatar(
            radius: 22,
            backgroundColor: kSecondarybgColor,
            child: Icon(icon, size: 24, color: Colors.white),
          );
        }

        Widget _buildCategoryWidget() {
          final categoryTitles = categories.map((cat) => cat.title).toList();

          if (categoryTitles.isEmpty) {
            return Container(
              height: 45,
              alignment: Alignment.center,
              child: const Text(
                "No categories",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categoryTitles.length,
                itemBuilder: (context, index) {
                  final category = categoryTitles[index];
                  final isSelected = category == selectedCategory;
                  return GestureDetector(
                    onTap: () => selectCategory(category),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.purpleAccent : Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? Border.all(color: Colors.purpleAccent, width: 2) : null,
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }

        Widget _buildContent() {
          return Column(
            children: [
              _buildProfileList(),
              const SizedBox(height: 20),
              Expanded(child: _buildStreamGrid()),
            ],
          );
        }

        Widget _buildProfileList() {
          if (streamItems.isEmpty) {
            return SizedBox(
              height: 100,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, color: Colors.white54, size: 40),
                    SizedBox(height: 8),
                    Text(
                      "No streams available",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            );
          }

          return SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: streamItems.length,
              itemBuilder: (context, index) {
                final item = streamItems[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileDetailScreen(streamItem: item),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      left: index == 0 ? 0 : 7,
                      right: index == streamItems.length - 1 ? 0 : 7,
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: item.isLiveNow ? Colors.red : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(item.image),
                            ),
                            if (item.isLiveNow)
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    "LIVE",
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
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            item.name,
                            style: TextStyle(
                              color: item.isLiveNow ? Colors.white : Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }

        Widget _buildStreamGrid() {
          if (streamItems.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.live_tv_rounded, color: Colors.white54, size: 50),
                  SizedBox(height: 10),
                  Text(
                    "No streams in this category",
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: GridView.builder(
              itemCount: streamItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final item = streamItems[index];
                return GestureDetector(
                  onTap: () async {
                    try {
                      // ✅ LẤY USER ĐANG ĐĂNG NHẬP
                      final currentUser = await _findCurrentUser();

                      if (currentUser == null) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Vui lòng đăng nhập"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LiveStreamScreen(
                            streamItem: item,          // streamer
                            currentUser: currentUser,  // viewer
                          ),
                        ),
                      );
                    } catch (e) {
                      print('❌ Error opening stream: $e');
                    }
                  },
                  child: Card(
                    elevation: 6,
                    shadowColor: Colors.purpleAccent.withOpacity(0.3),
                    color: const Color(0xFF1C1C1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                              child: Stack(
                                children: [
                                  Image.network(
                                    item.coverImage.isNotEmpty
                                        ? item.coverImage
                                        : item.image,
                                    width: double.infinity,
                                    height: 160,
                                    fit: BoxFit.cover,
                                  ),

                                  // 🌈 Gradient làm ảnh sáng & nổi chữ
                                  Container(
                                    height: 160,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.1),
                                          Colors.black.withOpacity(0.45),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 🔴 LIVE badge sáng hơn
                            if (item.isLiveNow)
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.redAccent, Colors.red],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    "LIVE",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                            // 👁 Viewer badge glass style
                            Positioned(
                              bottom: 10,
                              left: 10,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    color: Colors.black.withOpacity(0.35),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.remove_red_eye,
                                            color: Colors.white, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.viewer,
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
                              ),
                            ),
                          ],
                        ),

                        // 📄 Text content
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.streamTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.name,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                );
              },
            ),
          );
        }

        Widget _buildBottomNav() {
          return Container(
            height: 80,
            color: Colors.black.withOpacity(0.8),
            child: Row(
              children: [
                // HOME
                Expanded(
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.home_filled,
                        color: Colors.purpleAccent, size: 28),
                  ),
                ),


                // 🔴 LIVE — NẰM CHUNG HÀNG
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final user = await _findCurrentUser();

                      if (user == null) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Vui lòng đăng nhập trước"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LivePrepareScreen(currentUser: user),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.pink, Colors.red],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.wifi_tethering,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),


                // PROFILE
                Expanded(
                  child: IconButton(
                    onPressed: () async {
                      final user = await _findCurrentUser();
                      if (user == null) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InfoUserScreen(user: user),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_outline,
                        color: Colors.white60, size: 26),
                  ),
                ),
              ],
            ),
          );
        }
      }