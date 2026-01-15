import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled5/Screen/streming_app_home_screen.dart';
import 'package:untitled5/RegisterScreen.dart';
import 'Screen/streming_app_home_screen.dart';
import 'ForgotPassword.dart';
import 'package:untitled5/Model/user.dart';

class LoginScreenb extends StatefulWidget {
  const LoginScreenb({Key? key}) : super(key: key);

  @override
  State<LoginScreenb> createState() => _LoginScreenState();
}




class _LoginScreenState extends State<LoginScreenb>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  late TextEditingController _emailController;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    // Animation controller cho logo glow & pulse
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() => _loading = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Đăng nhập thành công ✅")));


      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => StremingAppHomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _loading = false);

      String message = "Đăng nhập thất bại ❌";
      if (e.code == 'user-not-found') {
        message = "Không tìm thấy tài khoản!";
      } else if (e.code == 'wrong-password') {
        message = "Sai mật khẩu!";
      } else if (e.code == 'invalid-email') {
        message = "Email không hợp lệ!";
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ảnh nền
          Image.network(
            'https://st2.depositphotos.com/1662991/45473/i/450/depositphotos_454739980-stock-photo-caucasian-woman-gamer-headphones-using.jpg',
            fit: BoxFit.cover,
          ),

          // Lớp mờ
          Container(color: Colors.black.withOpacity(0.6)),

          // FORM LOGIN
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🔥 Logo có animation glow
                  ScaleTransition(
                    scale: Tween(begin: 0.95, end: 1.05).animate(
                      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
                    ),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Colors.pinkAccent, Colors.orangeAccent],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pinkAccent.withOpacity(0.8),
                            blurRadius: 30,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.live_tv, color: Colors.white, size: 50),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      prefixIcon: const Icon(Icons.email_outlined),
                      hintText: "Email hoặc số điện thoại",
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

                  Row(
                    children: [
                      const Text(
                        "Bạn chưa có tài khoản?",
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => RegisterScreen()));
                        },
                        child: const Text("Đăng ký",style: TextStyle(color: Colors.pink,fontWeight: FontWeight.bold),),
                      ),
                    ],
                  ),

                  TextButton(
                    onPressed: () {Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ForgotPasswordScreen()));
                    },
                    child: const Text(
                      "Quên mật khẩu?",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _loading ? null : _login,
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
                      "Đăng nhập",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),



                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _socialButton(IconData icon, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}
