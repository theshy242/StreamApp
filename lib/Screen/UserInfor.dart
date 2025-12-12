import 'dart:ui';
import 'package:flutter/material.dart';
import '../Model/user.dart';

class InfoUserScreen extends StatelessWidget {
  final User user; // 🔹 user được truyền từ Home

  const InfoUserScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
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
            child: Container(color: const Color(0x55000000)),
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
                        color: const Color(0xFFFF4D67).withOpacity(0.6),
                        blurRadius: 25,
                        spreadRadius: 3,
                      )
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundImage: NetworkImage(
                      user.avatar.isNotEmpty
                          ? user.avatar
                          : "[https://cdn-icons-png.flaticon.com/512/1144/1144760.png](https://cdn-icons-png.flaticon.com/512/1144/1144760.png)",
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  user.name.isNotEmpty ? user.name : "No Name",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "@${user.email} • ${user.followers} Followers",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserInfoRow("Email", user.email),
                      UserInfoRow("Server URL", user.serverUrl),
                      UserInfoRow("Description", user.description),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                _glassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      UserStatBox("Streams", "0"),
                      UserStatBox("Followers", user.followers.toString()),
                      UserStatBox("Following", "0"),
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
    );
  }
}

// Glass Card
Widget _glassCard({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0x22FFFFFF),
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

class UserInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const UserInfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
            ),
          ),
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
