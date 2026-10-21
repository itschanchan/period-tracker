import 'dart:async';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:period_tracker/features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'package:period_tracker/features/dashboard/views/components/period_calendar.dart';
import 'package:period_tracker/features/dashboard/views/components/period_description.dart';
import 'package:period_tracker/features/dashboard/views/components/health_log.dart';
import 'package:period_tracker/features/dashboard/views/components/floating_nav.dart';
import 'package:period_tracker/backend/services/auth_service.dart';
import 'package:period_tracker/backend/viewModels/health_logs_view_model.dart';
import 'package:period_tracker/backend/viewModels/daily_monitor_view_model.dart';

class DashboardView extends StatefulWidget {
  final DateTime simulatedToday;
  final String? username;

  const DashboardView({
    super.key,
    required this.simulatedToday,
    this.username,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final AuthService _authService = AuthService();
  StreamSubscription<AuthState>? _authSubscription;

  List<DateTime?> _dates = [];
  int _calendarVersion = 0;
  bool _isEditingPeriodDates = false;
  DateTime? _selectedViewDate;
  List<DateTime?> _initialDatesForEdit = [];
  bool _isTodayVisible = true;
  bool _isTodayAbove = false;

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
            context.read<DashboardViewModel>().updateDates(dates);
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

  /// Pushes the local cycle state to Supabase. Silently skips when the user
  /// is not signed in.
  Future<void> _syncToSupabase(DashboardViewModel cycleData) async {
    try {
      await _authService.syncFullData(
        cycleData,
        healthLogs: context.read<HealthLogsViewModel?>(),
        dailyMonitor: context.read<DailyMonitorViewModel?>(),
      );
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cycleData = context.watch<DashboardViewModel>();
    final DateTime now = widget.simulatedToday;
    final DateTime todayDate = DateTime(now.year, now.month, now.day);
    final DateTime firstDate = DateTime(now.year - 2, now.month, now.day);
    final DateTime lastDate = DateTime(now.year + 2, now.month, now.day);

    final bool isApple = Theme.of(context).platform == TargetPlatform.iOS;
    final String displayUsername =
        (ModalRoute.of(context)?.settings.arguments as String?) ?? "Bebi";

    final String periodButtonText = cycleData.cycleModel.periodDates.isEmpty
        ? 'Add Period Dates'
        : 'Edit Period Dates';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_authService.currentUser == null)
            Padding(
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
          else
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: GestureDetector(
                onTap: () => debugPrint("Profile Clicked!"),
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
                  GestureDetector(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Welcome, $displayUsername!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  _isEditingPeriodDates
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            isApple
                                ? CupertinoButton(
                                    color: Colors.grey,
                                    onPressed: () {
                                      setState(() {
                                        _dates = List.from(_initialDatesForEdit);
                                        _isEditingPeriodDates = false;
                                        _calendarVersion++;
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
                                        _dates = List.from(_initialDatesForEdit);
                                        _isEditingPeriodDates = false;
                                        _calendarVersion++;
                                      });
                                    },
                                    child: const Text('Cancel'),
                                  ),
                            isApple
                                ? CupertinoButton(
                                    color: Colors.pink,
                                    onPressed: () async {
                                      setState(() {
                                        cycleData.updateDates(
                                            _dates.whereType<DateTime>().toList());
                                        _calendarVersion++;
                                        _isEditingPeriodDates = false;
                                      });
                                      await _syncToSupabase(cycleData);
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
                                        cycleData.updateDates(
                                            _dates.whereType<DateTime>().toList());
                                        _calendarVersion++;
                                        _isEditingPeriodDates = false;
                                      });
                                      await _syncToSupabase(cycleData);
                                    },
                                    child: const Text('Save'),
                                  ),
                          ],
                        )
                      : isApple
                          ? CupertinoButton(
                              color: Colors.pink,
                              onPressed: () {
                                setState(() {
                                  _isEditingPeriodDates = true;
                                  _dates = List.from(cycleData.cycleModel.periodDates);
                                  _initialDatesForEdit = List.from(_dates);
                                  _calendarVersion++;
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
                                  _dates = List.from(cycleData.cycleModel.periodDates);
                                  _initialDatesForEdit = List.from(_dates);
                                  _calendarVersion++;
                                });
                              },
                              child: Text(periodButtonText),
                            ),
                ],
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  PeriodCalendar(
                    calendarVersion: _calendarVersion,
                    selectedViewDate: _selectedViewDate!,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    now: now,
                    todayDate: todayDate,
                    isEditingPeriodDates: _isEditingPeriodDates,
                    value: _isEditingPeriodDates
                        ? _dates
                        : cycleData.cycleModel.periodDates.map((d) => d as DateTime?).toList(),
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
                    onTodayVisibilityChanged:
                        (isVisible, isAbove, isManualScroll) {
                      if (isVisible || isManualScroll) {
                        if (_isTodayVisible != isVisible ||
                            _isTodayAbove != isAbove) {
                          setState(() {
                            _isTodayVisible = isVisible;
                            _isTodayAbove = isAbove;
                          });
                        }
                      }
                    },
                  ),
                  if (!_isTodayVisible)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: _isTodayAbove
                          ? _buildScrollToTodayButton(
                              isUp: true,
                              isApple: isApple,
                              today: todayDate,
                            )
                          : _buildScrollToTodayButton(
                              isUp: false,
                              isApple: isApple,
                              today: todayDate,
                            ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_selectedViewDate != null && !_isEditingPeriodDates)
                PeriodDescription(
                  selectedViewDate: _selectedViewDate,
                  todayDate: todayDate,
                  cycleData: cycleData,
                  onConfirmPeriod: (date, isConfirmed) async {
                    if (isConfirmed) {
                      cycleData.addDate(date);
                      await _syncToSupabase(cycleData);
                    }
                  },
                ),
              if (_selectedViewDate != null && !_isEditingPeriodDates)
                HealthLog(
                  selectedViewDate: _selectedViewDate!,
                  todayDate: todayDate,
                ),
              const SizedBox(height: 20),
              const FloatingNav(),
              const SizedBox(height: 20),
            ],
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
        ),
      ),
    );
  }

  Widget _buildScrollToTodayButton({
    required bool isUp,
    required bool isApple,
    required DateTime today,
  }) {
    void onPressed() {
      setState(() {
        _selectedViewDate = today;
        _isTodayVisible = true;
        _calendarVersion++;
      });
    }

    if (isApple) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        color: Colors.pink.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(25),
        onPressed: onPressed,
        child: Icon(
          isUp ? CupertinoIcons.arrow_up : CupertinoIcons.arrow_down,
          color: Colors.white,
        ),
      );
    }

    return FloatingActionButton.small(
      backgroundColor: Colors.pink.withValues(alpha: 0.8),
      onPressed: onPressed,
      child: Icon(
        isUp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        color: Colors.white,
      ),
    );
  }
}