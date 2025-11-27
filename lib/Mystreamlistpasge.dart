import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'Screen/MyStream.dart'; // import class MyStream của bạn

class StreamListScreen extends StatefulWidget {
  const StreamListScreen({super.key});

  @override
  State<StreamListScreen> createState() => _StreamListScreenState();
}

class _StreamListScreenState extends State<StreamListScreen> {
  final DatabaseReference dbRef =
  FirebaseDatabase.instance.ref().child('my_streams'); // node của bạn

  List<MyStream> streamList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStreams();
  }

  void _fetchStreams() {
    dbRef.onValue.listen((event) {
      final data = event.snapshot.value;
      List<MyStream> tempList = [];

      if (data != null) {
        final dataMap = Map<String, dynamic>.from(data as Map);
        dataMap.forEach((key, value) {
          try {
            final itemMap = Map<String, dynamic>.from(value);
            final streamItem = MyStream(
              id: itemMap['id'] ?? '',
              title: itemMap['title'] ?? '',
              category: itemMap['category'] ?? '',
              imageUrl: itemMap['imageUrl'] ?? '',
              isLive: itemMap['isLive'] ?? false,
            );
            tempList.add(streamItem);
          } catch (e) {
            print("Error parsing $key: $e");
          }
        });
      }

      setState(() {
        streamList = tempList;
        isLoading = false;
      });
    }, onError: (error) {
      print("Firebase listen error: $error");
      setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Streams")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : streamList.isEmpty
          ? const Center(child: Text("Không có dữ liệu"))
          : ListView.builder(
        itemCount: streamList.length,
        itemBuilder: (context, index) {
          final stream = streamList[index];
          return ListTile(
            leading: Image.network(
              stream.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image),
            ),
            title: Text(stream.title),
            subtitle: Text(stream.category),
            trailing: stream.isLive
                ? const Icon(Icons.circle, color: Colors.red, size: 12)
                : null,
          );
        },
      ),
    );
  }
}
