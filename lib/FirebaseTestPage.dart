import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'Screen/Mystream.dart';
class PushMyStreamPage extends StatefulWidget {
  const PushMyStreamPage({super.key});

  @override
  State<PushMyStreamPage> createState() => _PushMyStreamPageState();
}

class _PushMyStreamPageState extends State<PushMyStreamPage> {
  late DatabaseReference dbRef;
  String statusText = "Ready to push data";

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    dbRef = FirebaseDatabase.instance.ref().child('my_streams'); // node mới
    print("✅ Firebase initialized");
  }

  Future<void> _pushSampleStream() async {
    final newStream = MyStream(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Live Coding Session",
      category: "🔥Popular",
      imageUrl: "https://example.com/image.jpg",
      isLive: true,
    );

    try {
      DatabaseReference newNode = dbRef.push(); // tạo key ngẫu nhiên
      await newNode.set(newStream.toJson());

      print("🎉 Data pushed with key: ${newNode.key}");
      setState(() {
        statusText = "Data pushed successfully!\nKey: ${newNode.key}";
      });
    } catch (e) {
      print("❌ Push error: $e");
      setState(() {
        statusText = "Push failed";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Push MyStream to Firebase")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(statusText, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pushSampleStream,
              child: const Text("Push Sample Stream"),
            ),
          ],
        ),
      ),
    );
  }
}
