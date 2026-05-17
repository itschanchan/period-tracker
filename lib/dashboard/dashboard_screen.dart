import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:clock/clock.dart';
// import 'package:intl/intl.dart'; // For date formatting
// Useful for date formatting.
// import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Project files
import '../providers/cycle_provider.dart';
import '../backend/auth_service.dart';

// Dashboard Components
import 'widgets/period_calendar.dart';
import 'widgets/period_description.dart';
import 'widgets/daily_monitor.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.title,
    required this.simulatedToday,
  });

  final String title; // Initializes the title of the page.
  final DateTime simulatedToday;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// State representing the 'Today' marker's position and visibility for the Scroll Spy.
class TodayVisibilityState {
  final bool isVisible;
  final bool isAbove;
  final bool isManualScroll;

  TodayVisibilityState({
    this.isVisible = true,
    this.isAbove = false,
    this.isManualScroll = false,
  });
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  StreamSubscription<AuthState>? _authSubscription;

  // Helper to check if a date falls within a specific range
  // bool _isDateInRange(DateTime date, DateTime start, DateTime end) {
  //   final d = DateTime(date.year, date.month, date.day);
  //   final s = DateTime(start.year, start.month, start.day);
  //   final e = DateTime(end.year, end.month, end.day);
  //   return (d.isAtSameMomentAs(s) || d.isAfter(s)) &&
  //       (d.isAtSameMomentAs(e) || d.isBefore(e));
  // }

  // Multi Scroll: step 1
  List<DateTime?> _dates = []; // Initialize an empty list for selected dates.

  bool _isEditingPeriodDates = false;

  // Scroll Trigger: Signals the calendar to jump to a date without rebuilding the Dashboard.
  final ValueNotifier<DateTime?> _scrollTriggerNotifier =
      ValueNotifier<DateTime?>(null);

  // Tracks which date the user is currently inspecting for details
  /* 
    Must stay in the Dashboard because it's shared between the calendar
    and the info Container below it.
  */
  DateTime? _selectedViewDate;

  // stores dates before editing for potential cancellation.
  List<DateTime?> _initialDatesForEdit = [];

  // Scroll Spy: Tracks 'Today' visibility without rebuilding the whole Dashboard.
  final ValueNotifier<TodayVisibilityState> _todayVisibilityNotifier =
      ValueNotifier(TodayVisibilityState());

  @override
  void initState() {
    super.initState();
    final DateTime now = widget.simulatedToday;
    _selectedViewDate = DateTime(now.year, now.month, now.day);

    // Listen for auth state changes to rebuild the UI when login succeeds via Google.
    _authSubscription = _authService.onAuthStateChange.listen((data) async {
      debugPrint(
        'Auth State Changed: ${data.event} | User: ${data.session?.user.email}',
      );

      // Only fetch data if the user just signed in or restored a session.
      // This prevents redundant fetches on every token refresh.
      final bool shouldFetch =
          data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.initialSession;

      if (shouldFetch && data.session != null && mounted) {
        try {
          final dates = await _authService.fetchPeriodDates();
          if (mounted) {
            context.read<CycleProvider>().updateDates(dates);
          }
        } catch (e) {
          debugPrint('Error fetching period dates: $e');
        }
      }

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _todayVisibilityNotifier.dispose();
    _scrollTriggerNotifier.dispose();
    super.dispose();
  }

  void _showLoginModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'FlowTrack Login',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('Sign in to sync your cycle data and settings.'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await _authService.signInWithGoogle();
                      // Note: On Web, the lines below will not run due to page redirect
                    } catch (e) {
                      debugPrint('Login Error: $e');
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.account_circle),
                  label: const Text('Sign-in with Google'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // build method
  @override
  Widget build(BuildContext context) {
    // The dashboard "finds" the provider that was created in the main.dart
    final cycleData = context.watch<CycleProvider>();

    // Initialize the selected view date to today if nothing is selected yet
    /* 
      now and todayDate

      these are used both to initialize _selectedViewDate and to handle the 
      "Go to Today" button logic, it's easier to keep them in the Dashboard
      and pass them down where needed.
    */
    final DateTime now = widget.simulatedToday;

    // Capture the mock clock time once at the start of the build.
    // This ensures consistency across all calculations in this build cycle.
    // final DateTime now = clock.now();
    final DateTime todayDate = DateTime(now.year, now.month, now.day);

    final DateTime firstDate = DateTime(now.year - 2, now.month, now.day);
    final DateTime lastDate = DateTime(now.year + 2, now.month, now.day);

    // Checks if the device is an iOS device.
    // bool isApple = Platform.isIOS; (not platform aware)
    bool isApple =
        Theme.of(context).platform == TargetPlatform.iOS; // platform-aware

    // Identify the range for the info container: "from the very first record to TODAY"
    final List<DateTime> recordedDates = cycleData.selectedDates
        .whereType<DateTime>()
        .toList();
    DateTime? firstPeriodDate;
    if (recordedDates.isNotEmpty) {
      // Find the earliest recorded period date
      firstPeriodDate = recordedDates.reduce((a, b) => a.isBefore(b) ? a : b);
      // Normalize to midnight for accurate comparison
      firstPeriodDate = DateTime(
        firstPeriodDate.year,
        firstPeriodDate.month,
        firstPeriodDate.day,
      );
    }

    // Conditional rendering for Edit/Cancel/Save buttons
    final String periodButtonText = cycleData.selectedDates.isEmpty
        ? 'Add Period Dates'
        : 'Edit Period Dates';

    // Retrieve the username from the route arguments
    final String displayUsername =
        (ModalRoute.of(context)?.settings.arguments as String?) ?? "Bebi";

    return Scaffold(
      // Top app bar with title and back button.
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back arrow button.
        title: Text(
          'Dashboard',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.inversePrimary /* safe for multi-platform checking */,
        actions: [
          _authService.currentUser == null
              ? Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton(
                    onPressed: () => _showLoginModal(context),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.pinkAccent,
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                    onTap: () => print("Profile Clicked!"),
                    child: CircleAvatar(
                      backgroundColor: Colors.pink.shade100,
                      child: _authService.currentUser?.email != null
                          ? Text(
                              _authService.currentUser!.email![0].toUpperCase(),
                            )
                          : const Icon(Icons.person, color: Colors.pink),
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Welcome Message
                  Text(
                    'Welcome, ${_authService.currentUser?.email?.split('@')[0] ?? displayUsername}!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Edit Period Dates Button
                  // Conditional rendering for Edit/Cancel/Save buttons
                  _isEditingPeriodDates
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Cancel Button
                            isApple
                                ? CupertinoButton(
                                    color: Colors.grey,
                                    onPressed: () {
                                      setState(() {
                                        _dates = List.from(
                                          _initialDatesForEdit,
                                        );
                                        _isEditingPeriodDates = false;
                                        _scrollTriggerNotifier.value =
                                            todayDate;
                                      });
                                    },
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _dates = List.from(
                                          _initialDatesForEdit,
                                        );
                                        _isEditingPeriodDates = false;
                                        _scrollTriggerNotifier.value =
                                            todayDate;
                                      });
                                    },
                                    child: const Text('Cancel'),
                                  ),

                            // Save Button
                            isApple
                                ? CupertinoButton(
                                    color: Colors.pink,
                                    onPressed: () async {
                                      setState(() {
                                        // Save the local draft to the provider
                                        cycleData.updateDates(_dates);
                                        _scrollTriggerNotifier.value =
                                            todayDate;
                                        _isEditingPeriodDates = false;
                                      });
                                      await _authService.syncFullData(
                                        cycleData,
                                      );
                                    },
                                    child: const Text(
                                      'Save',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.pink,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      setState(() {
                                        // Save the local draft to the provider
                                        cycleData.updateDates(_dates);
                                        _scrollTriggerNotifier.value =
                                            todayDate;
                                        _isEditingPeriodDates = false;
                                      });
                                      await _authService.syncFullData(
                                        cycleData,
                                      );
                                    },
                                    child: const Text('Save'),
                                  ),
                          ],
                        )
                      : // Edit Period Dates Button
                        isApple
                      ? CupertinoButton(
                          color: Colors.pink,
                          onPressed: () {
                            setState(() {
                              _isEditingPeriodDates = true;
                              // Sync local list with current provider data before editing
                              _dates = List.from(cycleData.selectedDates);
                              _initialDatesForEdit = List.from(_dates);
                              _scrollTriggerNotifier.value = todayDate;
                            });
                          },
                          child: Text(
                            periodButtonText,
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _isEditingPeriodDates = true;
                              // Sync local list with current provider data before editing
                              _dates = List.from(cycleData.selectedDates);
                              _initialDatesForEdit = List.from(_dates);
                              _scrollTriggerNotifier.value = todayDate;
                            });
                          },
                          child: Text(periodButtonText),
                        ),
                ],
              ),

              const SizedBox(height: 20),

              Stack(
                children: [
                  // Main Interactive Calendar
                  PeriodCalendar(
                    scrollTrigger: _scrollTriggerNotifier,
                    selectedViewDate: _selectedViewDate!,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    now: now,
                    todayDate: todayDate,
                    isEditingPeriodDates: _isEditingPeriodDates,
                    value: _isEditingPeriodDates
                        ? _dates
                        : cycleData.selectedDates,
                    onDateTapped: (date) {
                      setState(() {
                        _selectedViewDate = date;
                      });
                    },
                    onDatesChanged: (updatedDates) {
                      setState(() {
                        _dates = updatedDates;
                      });
                    },
                    onTodayVisibilityChanged: (isVisible, isAbove, isManualScroll) {
                      // Scroll Spy: Update the notifier instead of triggering a full screen rebuild.
                      // This ensures smooth tracking as the user scrolls.
                      _todayVisibilityNotifier.value = TodayVisibilityState(
                        isVisible: isVisible,
                        isAbove: isAbove,
                        isManualScroll: isManualScroll,
                      );
                    },
                  ),

                  // Scroll Spy: Use ValueListenableBuilder to rebuild only the floating button.
                  ValueListenableBuilder<TodayVisibilityState>(
                    valueListenable: _todayVisibilityNotifier,
                    builder: (context, state, child) {
                      // Only show button if 'Today' is not visible.
                      if (state.isVisible) return const SizedBox.shrink();

                      return Positioned(
                        bottom: 10,
                        right: 10,
                        child: _buildScrollToTodayButton(
                          isUp: state.isAbove,
                          isApple: isApple,
                          today: todayDate,
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // INFO CONTAINER (Updates based on _selectedViewDate)
              if (_selectedViewDate != null && !_isEditingPeriodDates)
                PeriodDescription(
                  selectedViewDate: _selectedViewDate,
                  todayDate: todayDate,
                  cycleData: cycleData,
                  onConfirmPeriod: (date, isConfirmed) async {
                    if (isConfirmed) {
                      cycleData.addDate(date);
                      await _authService.syncFullData(cycleData);
                    }
                  },
                ),

              if (_selectedViewDate != null && !_isEditingPeriodDates)
                HealthLog(
                  selectedViewDate: _selectedViewDate!,
                  todayDate: todayDate,
                ),

              const SizedBox(height: 20),

              // Expanded(
              //   child: ListWheelScrollView.useDelegate(
              //     itemExtent: 60,
              //     perspective: 0.005,
              //     diameterRatio: 1.2,
              //     physics: const FixedExtentScrollPhysics(),
              //     onSelectedItemChanged: (index) {
              //       setState(() {
              //         selectedDate = DateTime.now().subtract(
              //           Duration(days: 365 - index),
              //         );
              //       });
              //     },
              //     childDelegate: ListWheelChildBuilderDelegate(
              //       childCount: 366,
              //       builder: (context, index) {
              //         DateTime date = DateTime.now().subtract(
              //           Duration(days: 365 - index),
              //         );

              //         bool isSelected =
              //             date.day == selectedDate.day &&
              //             date.month == selectedDate.month &&
              //             date.year == selectedDate.year;

              //         return Center(
              //           child: Text(
              //             "${date.day}/${date.month}/${date.year}",
              //             style: TextStyle(
              //               fontSize: isSelected ? 22 : 18,
              //               fontWeight: isSelected
              //                   ? FontWeight.bold
              //                   : FontWeight.normal,
              //               color: isSelected ? Colors.pink : Colors.grey,
              //             ),
              //           ),
              //         );
              //       },
              //     ),
              //   ),
              // ),

              // Row(
              //   // Parent position of the Row container
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   // Position of the children in the Row container
              //   crossAxisAlignment: CrossAxisAlignment.center,
              //   children: [
              //     const Text('Try the new period tracker!'),

              //     Image.network(
              //       "https://static.vecteezy.com/system/resources/previews/036/152/193/non_2x/uterus-cute-cartoon-character-in-kawaii-style-drop-of-blood-menstruation-women-health-female-reproductive-system-cycle-anatomy-cervix-ovaries-fallopian-tubes-illustration-flat-style-vector.jpg",
              //       // Saves RAM, good for thumbnails
              //       cacheWidth: null,
              //       cacheHeight: 100,
              //       fit: BoxFit.cover,
              //     ),
              //   ],
              // ),

              // Floating Navigation Bar
              // const FloatingNav(),
              // const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      // Floating Action Button
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {},
      //   tooltip: 'Add',
      //   child: const Icon(Icons.add),
      // ),
    );
  }

  /// Builds the 'Go to Today' button as a separate component logic
  Widget _buildScrollToTodayButton({
    required bool isUp,
    required bool isApple,
    required DateTime today,
  }) {
    // Optimized: Only the trigger changes, no full screen setState().
    void onPressed() {
      _selectedViewDate = today;
      _scrollTriggerNotifier.value = today;
    }

    if (isApple) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        color: Colors.pink.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        onPressed: onPressed,
        child: Icon(
          isUp ? CupertinoIcons.arrow_up : CupertinoIcons.arrow_down,
          color: Colors.white,
        ),
      );
    }

    return FloatingActionButton.small(
      backgroundColor: Colors.pink.withOpacity(0.8),
      onPressed: onPressed,
      child: Icon(
        isUp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        color: Colors.white,
      ),
    );
  }
}

/* 
  NOTES:
    - onValueChanged - acts as a second layer of security,
    it ensures that even if a tap event were to slip through,
    the _dates state remains unchanged unless _isEditingPeriodDates
    is true.
*/
