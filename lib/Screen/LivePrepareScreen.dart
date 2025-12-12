import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled5/Model/user.dart';
class LivePrepareScreen extends StatefulWidget {
  final User currentUser;

  const LivePrepareScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<LivePrepareScreen> createState() => _LivePrepareScreenState();
}

class _LivePrepareScreenState extends State<LivePrepareScreen> {
  String? selectedCategory;
  bool micOn = true;
  bool camOn = true;
  bool _showStreamKey = false;
  String _streamKey = '';
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
  void initState() {
    super.initState();
    _generateStreamKey();
  }

  void _generateStreamKey() {
    // Tạo stream key dựa trên userId và timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.toString().substring(8, 13);
    setState(() {
      _streamKey = '${widget.currentUser.userId}_$random';
    });
  }

  Future<void> _copyStreamKey() async {
    await Clipboard.setData(ClipboardData(text: _streamKey));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã sao chép Stream Key!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showStreamKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin Streaming', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stream Key dùng cho OBS/Streaming Software:',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple),
              ),
              child: SelectableText(
                _streamKey,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text('Server URL:',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                widget.currentUser.serverUrl,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: _copyStreamKey,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text('Sao chép Key'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showStreamKey)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              width: 280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Stream Key',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18, color: Colors.purple),
                        onPressed: _copyStreamKey,
                      ),
                    ],
                  ),
                  Text(
                    _streamKey,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.currentUser.serverUrl,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          FloatingActionButton(
            onPressed: _showStreamKeyDialog,
            tooltip: 'Xem Stream Key',
            backgroundColor: Colors.purple,
            child: const Icon(Icons.video_settings, size: 28),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            onPressed: () {
              setState(() {
                _showStreamKey = !_showStreamKey;
              });
            },
            backgroundColor: Colors.grey[800],
            child: Icon(
              _showStreamKey ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ===================== CAMERA PREVIEW =====================
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      image: const DecorationImage(
                        image: NetworkImage(
                          "https://i.pinimg.com/736x/52/62/5b/52625b7622f5d0f7f4c8ad107ac2ff90.jpg",
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top gradient và user info
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.9),
                                Colors.transparent
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(widget.currentUser.avatar),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.currentUser.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${widget.currentUser.followers} followers',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
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

                  // Bottom controls
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
                          color: camOn ? Colors.greenAccent : Colors.redAccent,
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
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.title, color: Colors.white54),
                ),
                maxLength: 100,
              ),
            ),

            // ===================== CATEGORY SELECT =====================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DropdownButtonFormField<String>(
                dropdownColor: Colors.grey[900],
                value: selectedCategory,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white10,
                  hintText: "Chọn danh mục",
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.category, color: Colors.white54),
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
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Hãy nhập tiêu đề livestream")),
                      );
                      return;
                    }

                    if (selectedCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Hãy chọn danh mục")),
                      );
                      return;
                    }

                    // Truyền dữ liệu sang màn hình streaming
                    Navigator.pushNamed(
                      context,
                      "/streaming",
                      arguments: {
                        'user': widget.currentUser,
                        'streamKey': _streamKey,
                        'title': titleController.text,
                        'category': selectedCategory,
                        'micOn': micOn,
                        'camOn': camOn,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.live_tv, size: 24),
                  label: const Text(
                    "BẮT ĐẦU LIVE",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _roundButton({required IconData icon, required Color color, required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}