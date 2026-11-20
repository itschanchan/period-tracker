import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:period_tracker/data/data.dart';
import 'package:period_tracker/features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'package:period_tracker/features/notification/views/notification_detail_screen.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final DatabaseService _dbService = DatabaseService();
  DashboardViewModel? _viewModel;
  BuildContext? _context;
  String? _fcmToken;

  Future<void> initialize(BuildContext context, DashboardViewModel viewModel) async {
    _context = context;
    _viewModel = viewModel;

    try {
      await _initializeLocalNotifications();
    } catch (e) {
      debugPrint('Local notification setup failed: $e');
    }

    try {
      await _setupFirebaseMessaging();
    } catch (e) {
      debugPrint('Firebase messaging setup failed: $e');
    }

    try {
      _scheduleDailyNotifications();
    } catch (e) {
      debugPrint('Daily notification scheduling failed: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (_context == null) return;

    Navigator.push(
      _context!,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(
          title: response.payload?.split('|')[0] ?? 'Notification',
          body: response.payload?.split('|')[1] ?? 'No details available',
        ),
      ),
    );
  }

  Future<void> _setupFirebaseMessaging() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Register for FCM and listen for token updates (replaces deprecated getToken/onTokenRefresh)
    FirebaseMessaging.instance.onRegistered.listen((newToken) {
      _fcmToken = newToken;
      debugPrint("FCM Token: $newToken");
      _dbService.updateFcmToken(newToken);
    });

    try {
      await _messaging.register(
        vapidKey:
            "BKuih-r3cgrc93IHsLhChqgAmCQ_KbiOXvDrZmcF5ESOdVlpFuqfGAhk7G_QPSJ9tOOkbWkjkIi86tAOnpJOXFU",
      );
    } catch (e) {
      debugPrint('Error registering for FCM token: $e');
    }

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Handle background notifications when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleBackgroundMessage(message);
    });

    // Handle terminated state notifications
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleTerminatedMessage(message);
      }
    });

  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (_context == null) return;

    final title = message.notification?.title ?? "N/A";
    final body = message.notification?.body ?? "N/A";

    showDialog(
      context: _context!,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(
          body,
          maxLines: 1,
          style: TextStyle(overflow: TextOverflow.ellipsis),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NotificationDetailScreen(title: title, body: body),
                ),
              );
            },
            child: Text("Next"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    if (_context == null) return;

    final title = message.notification?.title ?? "N/A";
    final body = message.notification?.body ?? "N/A";

    Navigator.push(
      _context!,
      MaterialPageRoute(
        builder: (context) =>
            NotificationDetailScreen(title: title, body: body),
      ),
    );
  }

  void _handleTerminatedMessage(RemoteMessage message) {
    if (_context == null) return;

    final title = message.notification?.title ?? "N/A";
    final body = message.notification?.body ?? "N/A";

    Navigator.push(
      _context!,
      MaterialPageRoute(
        builder: (context) =>
            NotificationDetailScreen(title: title, body: body),
      ),
    );
  }

  void _scheduleDailyNotifications() {
    _checkAndSendNotifications();
    _scheduleNextDayCheck();
  }

  void _scheduleNextDayCheck() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final midnight = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      0,
      0,
      0,
      0,
    );

    final duration = midnight.difference(now);

    Future.delayed(duration, () {
      _checkAndSendNotifications();
      _scheduleNextDayCheck();
    });
  }

  String? get fcmToken => _fcmToken;

  void _checkAndSendNotifications() {
    if (_viewModel == null) return;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final sentCountdown = _checkPrePeriodCountdown(todayOnly);

    if (!sentCountdown && _isTodayInPredictedPeriod(todayOnly)) {
      _sendNotification(
        title: "Period Reminder",
        body:
            "Today is your predicted period day. Have you started your period?",
        notificationType: "period_reminder",
      );
    }

    if (_isTodayInFertileWindow(todayOnly)) {
      _sendNotification(
        title: "Fertile Window",
        body: "Today is in your fertile window. Track your symptoms!",
        notificationType: "fertile_window",
      );
    }

    if (_isTodayOvulationDay(todayOnly)) {
      _sendNotification(
        title: "Ovulation Day",
        body: "Today is your ovulation day!",
        notificationType: "ovulation_day",
      );
    }
  }

  bool _isTodayInPredictedPeriod(DateTime today) {
    if (_viewModel == null) return false;

    final nextPeriodDate = _viewModel!.nextPeriodDate;
    final mensesLength = _viewModel!.mensesLength;

    for (int i = 0; i < mensesLength; i++) {
      final periodDay = nextPeriodDate.add(Duration(days: i));
      final periodDayOnly = DateTime(
        periodDay.year,
        periodDay.month,
        periodDay.day,
      );

      if (periodDayOnly.isAtSameMomentAs(today)) {
        return true;
      }
    }
    return false;
  }

  bool _isTodayInFertileWindow(DateTime today) {
    if (_viewModel == null) return false;

    final fertileStart = _viewModel!.fertileWindowStart;
    final fertileEnd = _viewModel!.fertileWindowEnd;

    final fertileStartOnly = DateTime(
      fertileStart.year,
      fertileStart.month,
      fertileStart.day,
    );
    final fertileEndOnly = DateTime(
      fertileEnd.year,
      fertileEnd.month,
      fertileEnd.day,
    );

    return today.isAtSameMomentAs(fertileStartOnly) ||
        today.isAtSameMomentAs(fertileEndOnly) ||
        (today.isAfter(fertileStartOnly) && today.isBefore(fertileEndOnly));
  }

  bool _isTodayOvulationDay(DateTime today) {
    if (_viewModel == null) return false;

    final ovulationDate = _viewModel!.ovulationDate;
    final ovulationOnly = DateTime(
      ovulationDate.year,
      ovulationDate.month,
      ovulationDate.day,
    );

    return today.isAtSameMomentAs(ovulationOnly);
  }

  bool _checkPrePeriodCountdown(DateTime today) {
    if (_viewModel == null) return false;

    final nextPeriod = _viewModel!.nextPeriodDate;
    final nextPeriodOnly = DateTime(
      nextPeriod.year,
      nextPeriod.month,
      nextPeriod.day,
    );

    final daysUntilPeriod = nextPeriodOnly.difference(today).inDays;

    if (daysUntilPeriod < 1 || daysUntilPeriod > 7) return false;

    if (_viewModel!.isPredictedPeriodDay(today)) {
      _sendNotification(
        title: "Period Check-In 🦈",
        body:
            "Hello user! Are you on your period today? Mark it down the calendar now.",
        notificationType: "pre_period_overlap",
      );
      return true;
    }

    final String body;
    if (daysUntilPeriod == 1) {
      body = "Your period starts tomorrow! Get ready! 📨";
    } else {
      body = "Your period is expected in $daysUntilPeriod days. Get ready! 📨";
    }

    _sendNotification(
      title: "Period Countdown 🔐",
      body: body,
      notificationType: "pre_period_countdown",
    );
    return true;
  }

  Future<void> _sendNotification({
    required String title,
    required String body,
    String notificationType = "period_reminder",
  }) async {
    await _sendLocalNotification(title: title, body: body);

    if (_fcmToken != null) {
      final message = {
        "to": _fcmToken,
        "notification": {"title": title, "body": body},
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "notification_type": notificationType,
        },
      };

      debugPrint("FCM Message ready for backend: $message");
    }
  }

  Future<void> _sendLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'period_tracker_channel',
      'Period Tracker Notifications',
      channelDescription: 'Notifications for period tracking reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: '$title|$body',
    );
  }

  void checkNotifications() {
    _checkAndSendNotifications();
  }
}