import 'package:flutter/material.dart';

import 'bottom_navbar.dart';

class ChatBubbleScreen extends StatelessWidget {
  const ChatBubbleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Chats",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141226), Color(0xFF2A1A3C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 80),
          itemCount: 10,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(
                    "https://i.pravatar.cc/150?img=4"
                ),
              ),
              title: Text(
                "User $index",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              subtitle: const Text(
                "Tin nhắn gần đây...",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38),
            );
          },
        ),
      ),
        bottomNavigationBar:  BottomNavBar(parentContext: context,currentIndex: 1,)
    );
  }
}
