// Remember the Golden Rule: everything is a widget!
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// CORE
import 'package:period_tracker/core/core.dart';

// FEATURES
import 'package:period_tracker/features/features.dart';

// Global debug date (change this and hot reload)
final ValueNotifier<DateTime> mockToday = ValueNotifier(DateTime.now());

// Global navigator key for debugging context-related issues
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 1. The Ignition Point
void main() async {
  // 2.The Attachment
  // runApp() is only in main.dart
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core utilities (local persistence)
  await PrefsUtils.init();

  // Initialize ConfigService and remote services
  try {
    await ConfigService.instance.load();
    
    await Future.wait([
      _initFirebase(),
      _initSupabase(),
    ]).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Startup services timed out or failed: $e');
  }

  runApp(const PeriodTrackingApp());
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: ConfigService.instance.getFirebaseOptions(),
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
}

Future<void> _initSupabase() async {
  try {
    final supabaseConfig = ConfigService.instance.getSupabaseConfig();
    await Supabase.initialize(
      url: supabaseConfig.url,
      publishableKey: supabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => DashboardViewModel()..initialize(),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Initialize the notification service once the providers are ready.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              final dashboardViewModel = Provider.of<DashboardViewModel>(
                context,
                listen: false,
              );
              NotificationService().initialize(context, dashboardViewModel);
            } catch (e) {
              debugPrint('Notification service initialization failed: $e');
            }
          });

          return MaterialApp(
            title: AppConstants.appName,
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            initialRoute: AppRoutes.dashboard,
            routes: AppRoutes.define(mockToday),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
          );
        },
      ),
    );
  }
}