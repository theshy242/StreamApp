import 'dart:ui';
import 'package:flutter/material.dart';

import 'bottom_navbar.dart';

class InfoUserScreen extends StatelessWidget {
  const InfoUserScreen({super.key}); // <-- FIX key warning

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
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
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: const Color(0x55000000), // withValues() equivalent
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                const SizedBox(height: 110),

                // Avatar neon glowing
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4D67), Color(0xFFFF784E)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4D67).withValues(alpha: 150),
                        blurRadius: 25,
                        spreadRadius: 3,
                      )
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 55,
                    backgroundImage: AssetImage("assets/images/user.png"),
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  "YOUR NAME",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const Text(
                  "@abc_ui • 12.5k Followers",
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 20),

                _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      UserInfoRow("Email", "abc@example.com"),
                      UserInfoRow("Phone", "0123 456 789"),
                      UserInfoRow("Status", "● Online"),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                _glassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      UserStatBox("Streams", "120"),
                      UserStatBox("Followers", "12.5k"),
                      UserStatBox("Following", "240"),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _pinkButton("Edit Profile"),
                const SizedBox(height: 12),
                _whiteButton("Security Settings", Icons.lock_outline),
                const SizedBox(height: 12),
                _whiteButton("My Wallet", Icons.account_balance_wallet_outlined),

                const SizedBox(height: 30),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Highlight Streams",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: 6,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, idx) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          Image.asset(
                            "assets/images/demo${(idx % 3) + 1}.jpg",
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4D67),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                "Replay",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
        bottomNavigationBar:  BottomNavBar(parentContext: context,currentIndex: 3,)
    );
  }
}

// Glass card widget
Widget _glassCard({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0x22FFFFFF), // replaces withOpacity(0.15)
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0x33FFFFFF)),
    ),
    child: child,
  );
}

Widget _pinkButton(String text) {
  return Container(
    width: double.infinity,
    height: 48,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      gradient: const LinearGradient(
        colors: [Color(0xFFFF4D67), Color(0xFFFF784E)],
      ),
    ),
    child: Center(
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

Widget _whiteButton(String text, IconData icon) {
  return Container(
    height: 48,
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0x22FFFFFF),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}

// Info row component
class UserInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const UserInfoRow(this.label, this.value, {super.key}); // FIX key warning

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class UserStatBox extends StatelessWidget {
  final String title;
  final String count;

  const UserStatBox(this.title, this.count, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(color: Colors.white70),
        )
      ],
    );
  }
}
