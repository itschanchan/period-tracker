import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../app_routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.title});

  final String title; // Initializes the title of the page.

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    // Checks if the device is an iOS device.
    // bool isApple = Platform.isIOS; (not platform aware)
    bool isApple = Theme.of(context).platform == TargetPlatform.iOS; // platform-aware

    // Retrieve the username from the route arguments
    final String _displayUsername = (ModalRoute.of(context)?.settings.arguments as String?) ?? "Guest";

    return Scaffold(
      // Horizontal bar at the top of the screen.
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary /* safe for multi-platform checking */,
      ),

      body: SingleChildScrollView(
        child: Center(
          child:  Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Welcome Message
              GestureDetector(
                child: Padding (
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Welcome, $_displayUsername!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Row (
                // Parent position of the Row container
                mainAxisAlignment: MainAxisAlignment.center,
                // Position of the children in the Row container
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Try the new period tracker!',
                  ),

                  Image.network(
                    "https://static.vecteezy.com/system/resources/previews/036/152/193/non_2x/uterus-cute-cartoon-character-in-kawaii-style-drop-of-blood-menstruation-women-health-female-reproductive-system-cycle-anatomy-cervix-ovaries-fallopian-tubes-illustration-flat-style-vector.jpg",
                    // Saves RAM, good for thumbnails
                    cacheWidth: null,
                    cacheHeight: 100,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}