import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Screen/streming_app_home_screen.dart';
import 'package:firebase_database/firebase_database.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  // Hàm tạo userId tuần tự: user09, user10, user11... (tiếp theo số 8 hiện tại)
  Future<String> _generateSequentialUserId() async {
    try {
      // Lấy counter hiện tại từ Firebase
      final counterRef = FirebaseDatabase.instance.ref("counters/user_counter");
      final counterSnapshot = await counterRef.get();

      int currentCounter = 9; // Bắt đầu từ 9 (vì đã có 8 user)

      if (counterSnapshot.exists) {
        currentCounter = (counterSnapshot.value as int? ?? 8) + 1;
      }

      // Tăng counter lên 1
      await counterRef.set(currentCounter);

      // Format: user09, user10, user11...
      return "user${currentCounter.toString().padLeft(2, '0')}";
    } catch (e) {
      print("Lỗi khi tạo userId: $e");
      // Fallback: dùng timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return "user_${timestamp.toString().substring(9, 13)}";
    }
  }

  Future<void> _register() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu xác nhận không trùng khớp ❌")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // 1. Tạo user Firebase Auth
      UserCredential userCred =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCred.user;

      if (user != null) {
        // 2. Tạo userId tuần tự: user09, user10,...
        final userId = await _generateSequentialUserId();

        // 3. StreamKey = userId (user09, user10,...)
        final streamKey = userId;

        // 4. Lưu user vào Realtime DB với key là userId đơn giản
        final userRef = FirebaseDatabase.instance.ref("users/$userId");
        await userRef.set({
          "userId": userId,           // user09, user10,...
          "firebaseUid": user.uid,    // UID thật từ Firebase Auth
          "name": "New User",
          "email": user.email ?? "",
          "avatar": "https://cdn-icons-png.flaticon.com/512/1144/1144760.png",
          "serverUrl": "rtmp://192.168.1.249/live/$streamKey",
          "description": "",
          "followers": 0,
          "createdAt": DateTime.now().millisecondsSinceEpoch,
          "streamKey": streamKey,     // streamKey = userId
        });

        print('✅ Đã tạo user: $userId (Firebase UID: ${user.uid})');
      }

      setState(() => _loading = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Đăng ký thành công ✅")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => StremingAppHomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _loading = false);

      String message = "Đăng ký thất bại ❌";
      if (e.code == 'email-already-in-use') {
        message = "Email đã được sử dụng!";
      } else if (e.code == 'invalid-email') {
        message = "Email không hợp lệ!";
      } else if (e.code == 'weak-password') {
        message = "Mật khẩu quá yếu!";
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://st2.depositphotos.com/1662991/45473/i/450/depositphotos_454739980-stock-photo-caucasian-woman-gamer-headphones-using.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.6)),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🔥 Logo
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.pink, Colors.orange],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_add, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 24),


                  // Email
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      prefixIcon: const Icon(Icons.email_outlined),
                      hintText: "Email của bạn",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      hintText: "Mật khẩu",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm password
                  TextField(
                    controller: _confirmController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      prefixIcon: const Icon(Icons.lock_reset),
                      hintText: "Nhập lại mật khẩu",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.pinkAccent,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                        : const Text(
                      "Đăng ký",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Đã có tài khoản?",
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Đăng nhập"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}