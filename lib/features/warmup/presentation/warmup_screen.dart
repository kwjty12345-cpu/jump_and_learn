import 'package:flutter/material.dart';

class WarmupScreen extends StatelessWidget {
  const WarmupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warm-Up Phase'),
      ),
      body: const Center(
        child: Text(
          'Member 3 Warm-Up Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}