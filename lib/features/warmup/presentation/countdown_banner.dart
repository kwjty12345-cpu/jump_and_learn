import 'package:flutter/material.dart';

class CountdownBanner extends StatelessWidget {
  final String time;

  const CountdownBanner({
    super.key,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      time,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}