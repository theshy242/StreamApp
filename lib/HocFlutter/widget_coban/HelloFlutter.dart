import 'package:flutter/material.dart';
class Helloflutter extends StatelessWidget{
  const Helloflutter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Hello flutter"),
      ),
      body: const Center(
        child: Text("Hello flutter",
        style: TextStyle(fontSize: 32,fontWeight: FontWeight.bold,color: Colors.blue),),
      ),
    );//
  }
}