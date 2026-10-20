import 'package:flutter/material.dart';

class FloatingNav extends StatelessWidget {
  const FloatingNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Margin (space outside)
      margin: const EdgeInsets.symmetric(horizontal: 20),
      // Padding (space inside)
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.camera_alt, color: Colors.blue, size: 30),
          Icon(Icons.video_library, color: Colors.blue, size: 30),
          Icon(Icons.settings, color: Colors.blue, size: 30),
          Icon(Icons.chat_bubble, color: Colors.blue, size: 30),
        ],
      ),
    );
  }
}
