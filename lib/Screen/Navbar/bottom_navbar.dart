import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final BuildContext parentContext;
  final int currentIndex;

   BottomNavBar({super.key, required this.parentContext,
   required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Colors.purpleAccent;
    const Color inactiveColor = Colors.white70;
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon Home (index = 0)
          IconButton(
            onPressed: () {
              // Chỉ điều hướng nếu chưa ở trang đó
              if (currentIndex != 0) {
                Navigator.pushNamed(context, '/home');
              }
            },
            icon: Icon(
              Icons.home_filled,
              // 4. Sử dụng toán tử 3 ngôi để quyết định màu sắc
              color: currentIndex == 0 ? activeColor : inactiveColor,
              size: 30,
            ),
          ),
          // Icon Chat (index = 1)
          IconButton(
            onPressed: () {
              if (currentIndex != 1) {
                Navigator.pushNamed(context, '/chat');
              }
            },
            icon: Icon(
              Icons.chat_bubble_outline,
              color: currentIndex == 1 ? activeColor : inactiveColor,
              size: 26,
            ),
          ),
          // Icon Favorite (index = 2)
          IconButton(
            onPressed: () {
              if (currentIndex != 2) {
                Navigator.pushNamed(context, '/favor');
              }
            },
            icon: Icon(
              Icons.favorite_border,
              color: currentIndex == 2 ? activeColor : inactiveColor,
              size: 26,
            ),
          ),
          // Icon Info (index = 3)
          IconButton(
            onPressed: () {
              if (currentIndex != 3) {
                Navigator.pushNamed(context, '/info');
              }
            },
            icon: Icon(
              Icons.person_outline,
              color: currentIndex == 3 ? activeColor : inactiveColor,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}
