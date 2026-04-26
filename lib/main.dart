// Remember the Golden Rule: everything is a widget!
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// APP ROUTE
import 'app_routes.dart';
import '/providers/cycle_provider.dart';

// import 'dart:io'; // Required for Platform.isIOS (this is solely for mobile platforms, not compatible with the web)

// Global debug date (change this and hot reload)
final ValueNotifier<DateTime> mockToday = ValueNotifier(DateTime(2026, 4, 27));

// 1. The Ignition Point
void main() {
  // 2.The Attachment
  // runApp() is only in main.dart
  runApp(const PeriodTrackingApp());
}

// 3. MaterialApp: The Foundation
// StatelessWidget: The App's Blueprint / the Main Wrapper
class PeriodTrackingApp extends StatelessWidget {
  // Constructor
  const PeriodTrackingApp({super.key});

  // This widget is the root of your application.
  // Returns the a Widget Tree
  @override
  Widget build(BuildContext context) {
    // 1. Define your mock date here.
    // Simply change this date and save (Hot Reload) to move "Today" in the app.
    // final DateTime mockToday = DateTime.now();

    return ChangeNotifierProvider(
      create: (context) => CycleProvider(),
      child: MaterialApp(
        title: 'Period Tracker',
        debugShowCheckedModeBanner:
            false, // removes the "DEBUG" tag on the top right corner of the screen.
        // 1. Set the starting screen
        initialRoute: AppRoutes.dashboard,
        // 2. Load the map from app_routes.dart file
        routes: AppRoutes.define(mockToday),
        // 3. Set the global theme
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        ),
      ),
    );
  }
}

/* 
  main.dart's default screen 
  DO NOT USE THIS! Since it already has multiple files connected.
*/
// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // Horizontal bar at the top of the screen.
//       appBar: AppBar(
//         title: Text(widget.title),
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary /* safe for multi-platform checking */,
//       ),

//     );
//   }
// }

/*  
  NOTES:
  - Dart requires the class name for static methods and enums, unlike languages like Swift.
  - Why use Theme.of(context).platform?
  - Using the Theme approach is often better for UI logic because it allows you to test your 
    "Apple" layout on other platforms by simply overriding the ThemeData.platform in your MaterialApp. 
    If you strictly want to know the physical hardware platform, you can also use defaultTargetPlatform 
    after importing package:flutter/foundation.dart.
*/
