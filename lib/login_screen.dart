import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
// import 'dart:io'; // Required for Platform.isIOS (this is solely for mobile platforms, not compatible with the web)

import '../app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Name Input Controller 
  final TextEditingController _nameController = TextEditingController();
  String _displayUsername = "";

  // Password Input Controller
  final TextEditingController _passwordController = TextEditingController();
  // String _password = "";

  // Clear Button Handler
  void handleClear() {
    setState(() {
      _nameController.clear();
      _passwordController.clear();
      _displayUsername = "";
    });
  }

  /*
    prevents from having memory leaks.
    put all the controllers here :)
  */
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Checks if the device is an iOS device.
    // bool isApple = Platform.isIOS; (not platform aware)
    bool isApple = Theme.of(context).platform == TargetPlatform.iOS; // platform-aware

    // Scaffold: The Skeleton of the App.
    return Scaffold(
       // Horizontal bar at the top of the screen.     
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary, /* safe for multi-platform checking */
      ),
      body: SingleChildScrollView(
        child: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Your go to period tracker!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),

            const SizedBox(height: 10),

            Image.network(
              "https://cdn-icons-png.freepik.com/256/9978/9978583.png?semt=ais_white_label",
              width: null,
              height: 100,
              fit: BoxFit.cover,
            ),

            const SizedBox(height: 10),

            // User Input Fields Container
            Container (
              margin: const EdgeInsets.symmetric(horizontal: 50),
              padding: const EdgeInsets.all(15),
              child: Column (
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Username Row
                  Row (
                    children: [
                      const Text(
                        'Username',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Name Input
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Enter your username',
                            hintText: 'e.g., Bebi',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Password Row
                  Row (children: [
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      ),

                      // Password Input
                      Expanded(
                        child: TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Enter your password',
                            hintText: 'e.g., password123',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true, // Hides password characters
                          ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Row (
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Login Button
                isApple
                    ? CupertinoButton.filled(
                        onPressed: () {
                          setState(() {
                            _displayUsername = _nameController.text;
                          });
                          // use pushReplacementNamed if don't want to go back to login screen again.
                          // declare an argument to pass the username to dashboard_screen.dart
                          // called outside setState() for better performance: navigate after the state update is requested
                          Navigator.pushNamed(
                            context,
                            AppRoutes.dashboard,
                            arguments: _nameController.text,
                          );
                        },
                        child: const Text('Login'),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _displayUsername = _nameController.text;
                          });
                          // use pushReplacementNamed if don't want to go back to login screen again.
                          // declare an argument to pass the username to dashboard_screen.dart
                          // called outside setState() for better performance: navigate after the state update is requested
                          Navigator.pushNamed(
                            context,
                            AppRoutes.dashboard,
                            arguments: _nameController.text,
                          );
                        },
                        child: const Text('Login'),
                      ),


                // Register Button
                isApple
                  ? CupertinoButton.filled(
                      onPressed: () {},
                      child: const Text('Register'),
                    )
                  : ElevatedButton(
                      onPressed: () {},
                      child: const Text('Register'),
                    ),

                // Clear Button
                isApple
                  ? CupertinoButton.filled(
                      onPressed: () {
                        handleClear();
                      },
                      child: const Text('Clear'),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        handleClear();
                      },
                      child: const Text('Clear'),
                    ),
              ],
            ),

            const SizedBox(height: 10),

            // Welcome Message      
            GestureDetector(
              onTap: () {
                handleClear();
              },
              child: Padding(
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


            // Navigation Bar
            Row (
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'Navigation Bar',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ],
            ),

          Container (
              // Margin (space outside)
              margin: const EdgeInsets.symmetric(horizontal: 20),
              // Padding (space inside)
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue,width: 2),
              ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Icon(Icons.camera_alt, color: Colors.blue, size: 30),
                    Icon(Icons.video_library, color: Colors.blue, size: 30),
                    Icon(Icons.settings, color: Colors.blue, size: 30),
                    Icon(Icons.chat_bubble, color: Colors.blue, size: 30),
                  ],
                ),
            ),

            // const SizedBox(height: 20),

            // const Icon(
            //   Icons.favorite,
            //   color: Colors.pink,
            //   size: 38.0,
            // ),

            // const SizedBox(height: 20),
            // isApple  // Checks if the devices is iOS
            //     ? CupertinoButton.filled(
            //         onPressed: () {},
            //         child: const Text('Cupertino Button'),
            //       )
            //     : ElevatedButton(
            //         onPressed: () {},
            //         child: const Text('Material Button'),
            //       ),
          ],
        ),
      ),
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }


}