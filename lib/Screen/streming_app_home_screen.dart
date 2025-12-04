import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../Constants/colors.dart';
import 'Navbar/bottom_navbar.dart';
import 'live_stream_screen.dart';
import 'profile_detail_screen.dart';
import 'package:untitled5/Model/StreamCategory.dart';
import 'package:untitled5/Model/model.dart';
import 'package:untitled5/Model/user.dart';

class StremingAppHomeScreen extends StatefulWidget {
  const StremingAppHomeScreen({super.key});

  @override
  State<StremingAppHomeScreen> createState() => _StremingAppHomeScreenState();
}

class _StremingAppHomeScreenState extends State<StremingAppHomeScreen> {
  String selectedCategory = "🔥Popular";
  List<StreamItem> streamItems = [];
  List<StreamItem> allStreams = [];
  List<StreamCategory> categories = [];
  bool isLoading = true;

  final DatabaseReference streamsDbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: "https://livestream-app-32b54-default-rtdb.firebaseio.com/",
  ).ref().child('streamItems');

  final DatabaseReference categoriesDbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: "https://livestream-app-32b54-default-rtdb.firebaseio.com/",
  ).ref().child('categories');

  final DatabaseReference usersDbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: "https://livestream-app-32b54-default-rtdb.firebaseio.com/",
  ).ref().child('users');

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  void _initializeFirebase() async {
    print('🟡 Initializing Firebase...');

    try {
      await Firebase.initializeApp();
      print('✅ Firebase initialized');
      _setupFirebaseListeners();
    } catch (e) {
      print('❌ Firebase init error: $e');
      _loadMockData();
    }
  }

  void _setupFirebaseListeners() {
    print('🎯 Setting up Firebase listeners...');

    // Lắng nghe dữ liệu streams
    streamsDbRef.onValue.listen((DatabaseEvent event) {
      print('🔵 Streams data received');

      final data = event.snapshot.value;
      print('🔥 Streams data type: ${data.runtimeType}');

      if (data == null) {
        print('❌ No streams data in Firebase');
        _loadMockData();
        return;
      }

      try {
        final dataMap = data as Map<dynamic, dynamic>;
        print('✅ Streams data map length: ${dataMap.length}');

        final List<StreamItem> tempList = [];
        dataMap.forEach((key, value) {
          try {
            print('🔄 Processing stream key: $key');
            final itemData = Map<String, dynamic>.from(value);
            final streamItem = StreamItem.fromJson(itemData);
            tempList.add(streamItem);
            print('✅ Added stream: ${streamItem.name}');
          } catch (e) {
            print('❌ Error parsing stream $key: $e');
          }
        });

        setState(() {
          allStreams = tempList;
          _filterStreams();
          isLoading = false;
        });

        print('🎉 SUCCESS! Loaded ${allStreams.length} streams from Firebase');

      } catch (e) {
        print('❌ Streams data processing error: $e');
        _loadMockData();
      }
    }, onError: (error) {
      print('❌ Streams listener error: $error');
      _loadMockData();
    });

    // Lắng nghe dữ liệu categories
    categoriesDbRef.onValue.listen((DatabaseEvent event) {
      print('🟣 Categories data received');

      final data = event.snapshot.value;

      if (data == null) {
        print('❌ No categories data in Firebase');
        _loadDefaultCategories();
        return;
      }

      try {
        final dataMap = data as Map<dynamic, dynamic>;
        print('✅ Categories data map length: ${dataMap.length}');

        final List<StreamCategory> tempCategories = [];
        dataMap.forEach((key, value) {
          try {
            print('🔄 Processing category key: $key');
            final categoryData = Map<String, dynamic>.from(value);
            final category = StreamCategory.fromJson(categoryData);
            tempCategories.add(category);
            print('✅ Added category: ${category.title}');
          } catch (e) {
            print('❌ Error parsing category $key: $e');
          }
        });

        setState(() {
          categories = tempCategories;
          // Nếu có categories từ Firebase, chọn category đầu tiên
          if (categories.isNotEmpty) {
            selectedCategory = categories.first.title;
            _filterStreams();
          }
        });

        print('🎉 SUCCESS! Loaded ${categories.length} categories from Firebase');

      } catch (e) {
        print('❌ Categories data processing error: $e');
        _loadDefaultCategories();
      }
    }, onError: (error) {
      print('❌ Categories listener error: $error');
      _loadDefaultCategories();
    });
  }

  void _loadDefaultCategories() {
    print('🔄 Loading default categories...');
    final defaultCategories = [
      StreamCategory(title: "🔥Popular"),
      StreamCategory(title: "🎮Gaming"),
      StreamCategory(title: "⚽️Sports"),
      StreamCategory(title: "🎧Music"),
    ];

    setState(() {
      categories = defaultCategories;
    });
  }

  void _loadMockData() {
    print('🔄 Loading mock data...');
    final mockItems = [
      StreamItem(
        name: 'Randy Rangers',
        category: '🔥Popular',
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
        userId: 'user_01', // ⭐ trỏ tới user
      ),
      StreamItem(
        name: 'Aura Kirana',
        category: '🎮Gaming',
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
        userId: 'user_02', // ⭐ trỏ tới user
      ),
    ];

    setState(() {
      allStreams = mockItems;
      _filterStreams();
      isLoading = false;
    });
  }

  void _filterStreams() {
    if (selectedCategory == "🔥Popular") {
      // Hiển thị tất cả stream hoặc stream phổ biến
      streamItems = allStreams.where((item) => item.isLiveNow).toList();
      if (streamItems.isEmpty) {
        streamItems = allStreams;
      }
    } else {
      streamItems = allStreams
          .where((item) => item.category == selectedCategory)
          .toList();
    }

    // Nếu không có item trong category, hiển thị tất cả
    if (streamItems.isEmpty && allStreams.isNotEmpty) {
      streamItems = allStreams;
    }
  }

  void selectCategory(String category) {
    setState(() {
      selectedCategory = category;
      _filterStreams();
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    if (isLoading) {
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildCategoryWidget(),
            const SizedBox(height: 20),
            Expanded(
              child: _buildContent(size),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purpleAccent,
        onPressed: () {
          Navigator.pushNamed(context, '/prepare');
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar:  BottomNavBar(parentContext: context,currentIndex: 0,),
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
          _buildIconButton(Icons.search),
          const SizedBox(width: 15),
          _buildIconButton(Icons.notifications_outlined),
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
    // Sử dụng categories từ Firebase hoặc default
    final categoryTitles = categories.map((cat) => cat.title).toList();

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

  Widget _buildContent(Size size) {
    return Column(
      children: [
        _buildProfileList(size),
        const SizedBox(height: 20),
        Expanded(child: _buildStreamGrid(size)),
      ],
    );
  }

  Widget _buildProfileList(Size size) {
    if (streamItems.isEmpty) {
      return SizedBox(
        height: size.height * 0.16,
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
      height: size.height * 0.16,
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

  Widget _buildStreamGrid(Size size) {
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
            onTap: () {
              usersDbRef.child(item.userId).get().then((snapshot) {
                if (snapshot.exists) {
                  final userData = Map<String, dynamic>.from(snapshot.value as Map);
                  final user = User.fromJson(userData);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LiveStreamScreen(
                        streamItem: item,
                        user: user, // truyền user
                      ),
                    ),
                  );
                } else {
                  print("❌ User not found for userId: ${item.userId}");
                }
              });

            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        item.image,
                        width: double.infinity,
                        height: size.height * 0.22,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: size.height * 0.22,
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.error_outline,
                              color: Colors.white54,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                    if (item.isLiveNow)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
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
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.remove_red_eye, color: Colors.white, size: 12),
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
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.streamTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
}