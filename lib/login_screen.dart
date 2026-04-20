import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
// import 'dart:io'; // Required for Platform.isIOS (this is solely for mobile platforms, not compatible with the web)

import '../app_routes.dart';

class LoginScreen extends StatefulWidget {
  // final bool isLogggedIn;

  const LoginScreen({super.key /*, required this.isLoggedIn*/});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Always put the validator variable on the state class.
  // Move the form key here so it persists across rebuilds
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Name Input Controller
  final TextEditingController _userNameController = TextEditingController();
  // String _displayUsername = "";

  // Password Input Controller
  final TextEditingController _passwordController = TextEditingController();
  // String _password = "";

  // Login Validator
  void validateLogin() {}

  // Clear Button Handler
  void handleClear() {
    setState(() {
      _userNameController.clear();
      _passwordController.clear();
      _formKey.currentState
          ?.reset(); // Optional: clears validation error messages
    });
  }

  // Login Button Handler
  void handleLogin() {
    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState!.validate()) {
      // If the form is valid, display a snackbar. In the Real world,
      // you'd often call a server or save the information in a database.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logged In!')));

      setState(() {
        // _displayUsername = _userNameController.text;
      });

      Navigator.pushNamed(
        context,
        AppRoutes.dashboard,
        arguments: _userNameController.text,
      );
    }
  }

  /*
    prevents from having memory leaks.
    put all the controllers here :)
  */
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Checks if the device is an iOS device.
    // bool isApple = Platform.isIOS; (not platform aware)
    bool isApple =
        Theme.of(context).platform == TargetPlatform.iOS; // platform-aware

    // Scaffold: The Skeleton of the App.
    return Scaffold(
      // Horizontal bar at the top of the screen.
      appBar: AppBar(
        // title: const Text(
        //   'Login',
        //   style: const TextStyle(fontWeight: FontWeight.bold),
        // ),
        // backgroundColor: Theme.of(
        //   context,
        // ).colorScheme.inversePrimary /* safe for multi-platform checking */,
        backgroundColor: Colors.transparent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.network(
                      "https://cdn-icons-png.freepik.com/256/9978/9978583.png?semt=ais_white_label",
                      width: null,
                      height: 100,
                      fit: BoxFit.cover,
                    ),

                    const SizedBox(height: 10),

                    // Brand
                    const Text(
                      'FlowTrack',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),

                    // Tagline
                    const Text(
                      'Your go to period tracker!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.pinkAccent,
                      ),
                    ),

                    const SizedBox(height: 50),

                    // User Input Fields Container
                    Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Username Row
                          Row(
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
                                child: TextFormField(
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your username.';
                                    }
                                    return null;
                                  },

                                  controller: _userNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
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
                          Row(
                            children: [
                              const Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              // Password Input
                              Expanded(
                                child: TextFormField(
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password.';
                                    } else if (value.length < 8) {
                                      return 'Password must be at least 8 characters long.';
                                    }
                                    return null;
                                  },

                                  controller: _passwordController,
                                  decoration: const InputDecoration(
                                    labelText: 'Enter your password',
                                    hintText: 'e.g., password123',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.lock),
                                  ),
                                  obscureText:
                                      true, // Hides password characters
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Login Button
                              isApple
                                  ? CupertinoButton.filled(
                                      onPressed: () {
                                        handleLogin();
                                      },
                                      child: const Text('Login'),
                                    )
                                  : ElevatedButton(
                                      onPressed: () {
                                        handleLogin();
                                      },
                                      child: const Text('Login'),
                                    ),

                              // Register Button
                              isApple
                                  ? CupertinoButton.filled(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.register,
                                        );
                                      },
                                      child: const Text('Register'),
                                    )
                                  : ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.register,
                                        );
                                      },
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
