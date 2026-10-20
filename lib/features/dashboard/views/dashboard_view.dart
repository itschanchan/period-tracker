import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:period_tracker/features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'package:period_tracker/features/dashboard/views/components/period_calendar.dart';
import 'package:period_tracker/features/dashboard/views/components/period_description.dart';
import 'package:period_tracker/features/dashboard/views/components/health_log.dart';
import 'package:period_tracker/features/dashboard/views/components/floating_nav.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    final cycleData = context.watch<DashboardViewModel>();
    final DateTime now = widget.simulatedToday;
    final DateTime todayDate = DateTime(now.year, now.month, now.day);
    final DateTime firstDate = DateTime(now.year - 2, now.month, now.day);
    final DateTime lastDate = DateTime(now.year + 2, now.month, now.day);

    final bool isApple = Theme.of(context).platform == TargetPlatform.iOS;
    final String displayUsername = widget.username ?? "Bebi";

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
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => debugPrint("Profile Clicked!"),
              child: const CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://static.zerochan.net/Sailor.Chibi.Moon.full.3236721.jpg',
                ),
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
                                    onPressed: () {
                                      setState(() {
                                        cycleData.updateDates(
                                            _dates.whereType<DateTime>().toList());
                                        _calendarVersion++;
                                        _isEditingPeriodDates = false;
                                      });
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
                                    onPressed: () {
                                      setState(() {
                                        cycleData.updateDates(
                                            _dates.whereType<DateTime>().toList());
                                        _calendarVersion++;
                                        _isEditingPeriodDates = false;
                                      });
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
                  onConfirmPeriod: (date, isConfirmed) {
                    if (isConfirmed) {
                      cycleData.addDate(date);
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