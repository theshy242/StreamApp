import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled5/Model/user.dart';
import 'package:untitled5/SplashScreen.dart';
import 'LoGinScreen.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await updateAllUsersServerUrl();
  runApp(const MyApp());
}

Future<void> updateAllUsersServerUrl() async {
  final ref = FirebaseDatabase.instance.ref('users');
  final snapshot = await ref.get();

  if (!snapshot.exists) {
    print('❌ Không có user nào');
    return;
  }

  final users = snapshot.value as Map<dynamic, dynamic>;

  for (final entry in users.entries) {
    final userId = entry.key.toString();


    final newServerUrl = "http://172.16.12.118/live/$userId/index_1.m3u8";


    await ref.child(userId).update({
      'serverUrl': newServerUrl,
    });

    print('✅ $userId → $newServerUrl');


    await Future.delayed(const Duration(milliseconds: 80));
  }

  print('🎉 Cập nhật xong ${users.length} users');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      home:  LoginScreenb(),

      routes: {

        '/login': (context) => LoginScreenb(), // màn hình login
      },
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            const Text(
              "Firebase đã khởi tạo thành công 🎉",
              style: TextStyle(color: Colors.green),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }


}

