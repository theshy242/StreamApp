import 'package:flutter/material.dart';

class LivePrepareScreen extends StatefulWidget {
  const LivePrepareScreen({super.key});

  @override
  State<LivePrepareScreen> createState() => _LivePrepareScreenState();
}

class _LivePrepareScreenState extends State<LivePrepareScreen> {
  String? selectedCategory;
  bool micOn = true;
  bool camOn = true;

  final titleController = TextEditingController();

  final List<String> categories = [
    "Gaming",
    "Entertainment",
    "Education",
    "Music",
    "Lifestyle",
    "IRL",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ===================== CAMERA PREVIEW (fake) =====================
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      image: DecorationImage(
                        image: NetworkImage(
                          "https://i.pinimg.com/736x/52/62/5b/52625b7622f5d0f7f4c8ad107ac2ff90.jpg",
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mic toggle
                        _roundButton(
                          icon: micOn ? Icons.mic : Icons.mic_off,
                          color: micOn ? Colors.greenAccent : Colors.redAccent,
                          onTap: () => setState(() => micOn = !micOn),
                        ),
                        const SizedBox(width: 20),

                        // Camera toggle
                        _roundButton(
                          icon: camOn ? Icons.videocam : Icons.videocam_off,
                          color:
                          camOn ? Colors.greenAccent : Colors.redAccent,
                          onTap: () => setState(() => camOn = !camOn),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            // ===================== TITLE INPUT =====================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Nhập tiêu đề livestream...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ),

            // ===================== CATEGORY SELECT =====================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DropdownButtonFormField<String>(
                dropdownColor: Colors.black87,
                value: selectedCategory,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white10,
                  hintText: "Chọn danh mục",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
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
            ),

            const SizedBox(height: 20),

            // ===================== GO LIVE BUTTON =====================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Hãy nhập tiêu đề livestream")));
                      return;
                    }

                    Navigator.pushNamed(context, "/streaming");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    "Start Live",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _roundButton({required IconData icon, required Color color, required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.black54,
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
