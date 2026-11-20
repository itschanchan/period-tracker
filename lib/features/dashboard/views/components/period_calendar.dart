import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter/rendering.dart';
import 'dart:math' as math;
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:provider/provider.dart';
import 'package:period_tracker/features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PeriodCalendar extends StatefulWidget {
  const PeriodCalendar({
    super.key,
    required this.calendarVersion,
    required this.selectedViewDate,
    required this.firstDate,
    required this.lastDate,
    required this.now,
    required this.todayDate,
    required this.isEditingPeriodDates,
    required this.value,
    required this.onDateTapped,
    required this.onDatesChanged,
    required this.onTodayVisibilityChanged, // Updated to pass visibility and position
  });

  final int calendarVersion;
  final DateTime selectedViewDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime now;
  final DateTime todayDate;
  final bool isEditingPeriodDates;
  final List<DateTime?> value;
  final ValueChanged<DateTime> onDateTapped;
  final ValueChanged<List<DateTime?>> onDatesChanged;
  final void Function(bool isVisible, bool isAbove, bool isManualScroll)
  onTodayVisibilityChanged;

  @override
  State<PeriodCalendar> createState() => _PeriodCalendarState();
}

class _PeriodCalendarState extends State<PeriodCalendar> {
  // Tracks the direction of the last user-initiated scroll
  bool _isTodayAbove = false;
  bool _isManualScrollActive = false;

  // Helper to check if two dates are the same day (ignoring time)
  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    // The dashboard "finds" the provider that was created in the main.dart
    final cycleData = context.watch<DashboardViewModel>();

    // UI-only list for the picker. We ensure the 'selectedViewDate' is at index 0
    // so the scroll view jumps there, but we will filter it out of the actual
    // data updates unless the user explicitly toggles it.
    final List<DateTime?> displayValues = [
      widget.selectedViewDate,
      ...widget.value.where(
        (d) => d != null && !_isSameDay(d, widget.selectedViewDate),
      ),
    ];

    // REBUILD LOGIC: The key now includes a signature of all selected dates AND
    // the provider's update timestamp. This forces the calendar to discard its
    // month cache and recalculate all decorations (Fertile, Ovulation, Predictions)
    // the moment a period is confirmed and history is updated.
    final String datesSignature = widget.value
        .map((d) => d?.millisecondsSinceEpoch ?? 0)
        .join('-');

    final Key calendarKey = ValueKey(
      'calendar_${widget.calendarVersion}_${datesSignature}_${widget.isEditingPeriodDates}_${cycleData.lastUpdated.millisecondsSinceEpoch}',
    );

    return Material(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        // Multi-Select Scroll Calendar
        // Step 2: Multi Scroll = Fixed Day Indicator (Header)
        // We build this manually so it stays fixed while you scroll the page.
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
          ), // Adjust character spacing in the header.
          child: Row(
            children: ['S', 'M', 'T', 'W', 'TH', 'F', 'S'].asMap().entries.map((
              entry,
            ) {
              final int index = entry.key;
              final String day = entry.value;
              Color textColor = Colors.pink; // Default color

              // Customize Saturday's 'S' (index 6) to be a lighter pink
              if (index == 6) {
                textColor = Colors.blueGrey;
              }

              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const Divider(height: 1), // Reduced height from default 16 to 1

        SizedBox(
          height: 350, // Adjust calendar height
          child: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              _isManualScrollActive = true;
              // If scrolling 'reverse' (moving down the list to future), Today is moving UP (above)
              if (notification.direction == ScrollDirection.reverse) {
                _isTodayAbove = true;
              }
              // If scrolling 'forward' (moving up the list to past), Today is moving DOWN (below)
              else if (notification.direction == ScrollDirection.forward) {
                _isTodayAbove = false;
              }
              return false;
            },
            child: CalendarDatePicker2(
                key: calendarKey,
              config: CalendarDatePicker2Config(
                firstDate: widget.firstDate,
                lastDate: widget.lastDate,
                currentDate: widget.selectedViewDate,
                disableMonthPicker: true,
                /*
                NOTES:
                - .single = Single Date Picker
                - .multi = Multi Date Picker
                - .range = Range Date Picker
              */
                // displayDayOfWeek:
                //     false, // Hide the built-in day of week labels
                calendarType: CalendarDatePicker2Type.multi,
                calendarViewMode: CalendarDatePicker2Mode.scroll,

                // We set this to transparent because we will handle the
                // "Selected" decoration manually in dayBuilder to prevent
                // the "scroll anchor" from appearing selected.
                selectedDayHighlightColor: Colors.transparent,

                // Hides the built-in Scroll Day Header
                hideScrollViewTopHeader: true,

                // Adjust this value to reduce the gap between Month/Year and days
                controlsHeight: 30,
                dayMaxWidth: 45,
                // headerTextStyle: const TextStyle(fontWeight: FontWeight.bold),

                // Hides the built-in day labels
                weekdayLabelTextStyle: const TextStyle(
                  color: Colors.transparent,
                ),
                // Custom Day Builder | dayBuilder property.
                dayBuilder:
                    ({
                      required date,
                      textStyle,
                      decoration,
                      isSelected,
                      isDisabled,
                      isToday,
                      isWeekends,
                    }) {
                      final bool isMockToday = _isSameDay(date, widget.now);
                      // We manually check if the date is actually a period date
                      // because 'isSelected' will be true for our scroll anchor.
                      final bool isActuallySelected = widget.value.any(
                        (d) => _isSameDay(d, date),
                      );

                      // Initialize styles from the config defaults
                      BoxDecoration? effectiveDecoration = decoration;
                      TextStyle? effectiveTextStyle = textStyle;

                      // Step 1: Neutralize the system's "today" if it's not our mock today.
                      if ((isToday ?? false) && !isMockToday) {
                        effectiveDecoration = null;
                        effectiveTextStyle = textStyle?.copyWith(
                          color: Colors.black,
                        );
                      }

                      // Identify prediction flags
                      final isNextPeriod = cycleData.isPredictedPeriodDay(date);
                      // While the user is editing period dates the fertile window and
                      // ovulation markers are hidden so they don't interfere with
                      // the selection UI.
                      final isOvulation = !widget.isEditingPeriodDates &&
                          cycleData.isPredictedOvulationDay(date);
                      final isFertile = !widget.isEditingPeriodDates &&
                          cycleData.isPredictedFertileDay(date);

                      // Check if this is a predicted day that has already passed without confirmation
                      final bool isPastUnconfirmed =
                          isNextPeriod &&
                          !isActuallySelected &&
                          // Only mark as "past" if it's before today AND doesn't overlap today
                          date.isBefore(widget.todayDate) &&
                          !_isSameDay(date, widget.todayDate);

                      final Color predictionColor = isPastUnconfirmed
                          ? Colors.grey.withValues(alpha: 0.5)
                          : Colors.pink;

                      // Step 2: Determine Styles (Layered logic)
                      // Priority for background: Actual Selection (Pink) > Ovulation (Blue) > Fertile (Cyan).
                      // We reset the decoration if it's a predicted day to ensure our colors override
                      // any system-provided "selected" or "current" decorations.
                      if (isActuallySelected) {
                        // If the date is a confirmed period, show solid pink.
                        // This takes highest priority.
                        effectiveDecoration = const BoxDecoration(
                          color: Colors.pink,
                          shape: BoxShape.circle,
                        );
                        effectiveTextStyle = textStyle?.copyWith(
                          color: Colors.white,
                        );
                      } else if (isOvulation) {
                        // Show blue for predicted ovulation.
                        effectiveDecoration = const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        );
                        effectiveTextStyle = textStyle?.copyWith(
                          color: Colors.white,
                        );
                      } else if (isFertile) {
                        // Show cyan for fertile window.
                        effectiveDecoration = const BoxDecoration(
                          color: Colors.cyan,
                          shape: BoxShape.circle,
                        );
                        effectiveTextStyle = textStyle?.copyWith(
                          color: Colors.white,
                        );
                      }

                      // Apply pink text for predicted period days only if the background isn't already colored
                      if (isNextPeriod &&
                          !isActuallySelected &&
                          !isOvulation &&
                          !isFertile) {
                        effectiveTextStyle = textStyle?.copyWith(
                          color: predictionColor,
                        );
                      }

                      // Step 3: Handle "Today" indicator text color
                      if (isMockToday &&
                          !isActuallySelected &&
                          !isOvulation &&
                          !isFertile) {
                        effectiveTextStyle = textStyle?.copyWith(
                          color: Colors.pink,
                        );
                      }

                      final bool isPressedDay =
                          !widget.isEditingPeriodDates &&
                          _isSameDay(date, widget.selectedViewDate);

                      // 3. Render the day cell
                      return Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          if (isPressedDay)
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Colors.black12,
                                shape: BoxShape.circle,
                              ),
                            ),
                          _buildDayContent(
                            isMockToday: isMockToday,
                            decoration: effectiveDecoration,
                            isActuallySelected: isActuallySelected,
                            isOvulation: isOvulation,
                            isFertile: isFertile,
                            isNextPeriod: isNextPeriod,
                            date: date,
                            textStyle: effectiveTextStyle,
                            isPastUnconfirmed: isPastUnconfirmed,
                          ),
                          // We draw the dashed circle on top of the cell content.
                          // This ensures that even if a day is confirmed (solid pink),
                          // the prediction outline remains visible for comparison.
                          if (isNextPeriod)
                            IgnorePointer(
                              child: SizedBox(
                                width: 38,
                                height: 38,
                                child: CustomPaint(
                                  painter: _DashedCirclePainter(
                                    color: predictionColor,
                                    strokeWidth:
                                        2.5, // Slightly thicker for visibility
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                // Disable selection for all days unless we are in editing mode
                // It handles 'read-only' logic.
                selectableDayPredicate: (day) => true,
              ),
              // Use our modified list to control the initial scroll position
              value: displayValues,
              onValueChanged: (dates) {
                // Identify which date was just tapped by comparing the new UI state
                // with the previous UI state (displayValues).
                DateTime? tappedDate;
                bool isAdded = false;

                // Check if a date was added (selected)
                for (final d in dates) {
                  if (!displayValues.any((p) => _isSameDay(d, p))) {
                    tappedDate = d;
                    isAdded = true;
                    break;
                  }
                }

                // Check if a date was removed
                for (final p in displayValues) {
                  if (p != null && !dates.any((d) => _isSameDay(d, p))) {
                    tappedDate = p;
                    isAdded = false;
                    break;
                  }
                }

                if (tappedDate != null) {
                  widget.onDateTapped(tappedDate);

                  if (widget.isEditingPeriodDates) {
                    List<DateTime?> newSelection = List.from(widget.value);
                    if (isAdded) {
                      // SEPARATED LOGIC:
                      // 1. Initial Setup: If no periods exist, auto-fill a range for convenience.
                      // 2. Confirmation/Append: If data exists, treat every tap as an
                      //    "added selection" to the current period list.
                      if (newSelection.isEmpty) {
                        // Only auto-fill if the selection is completely empty (First Time Setup)
                        newSelection = List.generate(
                          cycleData.mensesLength,
                          (i) => tappedDate!.add(Duration(days: i)),
                        );
                      } else {
                        // Count as an added selection (Append mode)
                        newSelection.add(tappedDate);
                      }
                    } else {
                      newSelection.removeWhere(
                        (d) => _isSameDay(d, tappedDate),
                      );
                    }
                    widget.onDatesChanged(newSelection);
                  }
                }
              },
            ),
          ),
        ),
      ],
    ));
  }

  /// Builds the content of a day cell, wrapping the 'Today' indicator with visibility tracking.
  Widget _buildDayContent({
    required bool isMockToday,
    required BoxDecoration? decoration,
    required bool isActuallySelected,
    required bool isOvulation,
    required bool isFertile,
    required bool isNextPeriod,
    required bool isPastUnconfirmed,
    required DateTime date,
    required TextStyle? textStyle,
  }) {
    final Widget content = Container(
      decoration: decoration,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icons: Prioritize ovulation/fertile, then actual period, then predicted period.
          // This ensures that if a day is also an ovulation/fertile day, that icon is shown.
          // The `TODAY` text will be rendered below these icons if `isMockToday` is true.
          if (isOvulation)
            const Icon(Icons.star, size: 10, color: Colors.white)
          else if (isFertile)
            const Icon(Icons.favorite, size: 10, color: Colors.white)
          else if (isActuallySelected)
            const Icon(Icons.water_drop, size: 10, color: Colors.white)
          else if (isNextPeriod)
            Icon(
              Icons.water_drop,
              size: 10,
              color: isPastUnconfirmed
                  ? Colors.grey.withValues(alpha: 0.5)
                  : Colors.pinkAccent,
            )
          else
            const SizedBox(height: 10), // Placeholder for consistent spacing

          if (isMockToday) // TODAY text (if applicable)
            Text(
              'TODAY',
              style: TextStyle(
                fontSize: 6,
                fontWeight: FontWeight.bold,
                color: isActuallySelected || isOvulation || isFertile
                    ? Colors.white
                    : Colors.pink,
              ),
            ),
          Text(date.day.toString(), style: textStyle),
        ],
      ),
    );

    if (isMockToday) {
      return VisibilityDetector(
        key: const Key('today-visibility-key'),
        onVisibilityChanged: (info) {
          // Trigger callback if Today's visibility drops below 10%.
          final bool isVisible = info.visibleFraction > 0.1;

          if (isVisible) _isManualScrollActive = false;

          widget.onTodayVisibilityChanged(
            isVisible,
            _isTodayAbove,
            _isManualScrollActive,
          );
        },
        child: content,
      );
    }

    return content;
  }
}

// Dashed Lines for Predicted Cycles
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;

  _DashedCirclePainter({required this.color, this.strokeWidth = 2})
    : dashLength = 4,
      dashSpace = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double radius = (size.width - strokeWidth) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final double circumference = 2 * math.pi * radius;
    final int dashCount = (circumference / (dashLength + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = (i * (dashLength + dashSpace)) / radius;
      final double sweepAngle = dashLength / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}
