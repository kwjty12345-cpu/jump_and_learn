import 'package:flutter/material.dart';

class WarmupScreen extends StatelessWidget {
  const WarmupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warm-Up Phase'),
      ),
      body: Column(
        children: [
          Text('03:00'),
          Text('Summary Notes'),
          Text('Object Oriented Programming...'),
          ElevatedButton(
            onPressed: () {},
            child: Text("I'm Ready"),
          ),
        ],
      ),
    );
  }
}