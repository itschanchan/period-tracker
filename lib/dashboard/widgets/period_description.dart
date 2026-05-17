import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

// Project files
import '../../providers/cycle_provider.dart';

class PeriodDescription extends StatefulWidget {
  final DateTime? _selectedViewDate;
  final DateTime todayDate;
  final CycleProvider cycleData;
  final Function(DateTime date, bool confirmed)? onConfirmPeriod;

  const PeriodDescription({
    super.key,
    required DateTime? selectedViewDate,
    required this.todayDate,
    required this.cycleData,
    this.onConfirmPeriod,
  }) : _selectedViewDate = selectedViewDate;

  @override
  State<PeriodDescription> createState() => _PeriodDescriptionState();
}

class _PeriodDescriptionState extends State<PeriodDescription> {
  /// Shows a platform-specific number picker for pain levels 0-10.
  void _showPainPicker(
    BuildContext context,
    CycleProvider cycleData,
    DateTime viewDate,
    bool isApple,
  ) {
    final int currentPain = cycleData.getPainForDate(viewDate);

    if (isApple) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: CupertinoPicker(
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: currentPain,
                    ),
                    onSelectedItemChanged: (int value) {
                      cycleData.updatePain(viewDate, value);
                    },
                    children: List.generate(
                      11,
                      (i) => Center(child: Text(i.toString())),
                    ),
                  ),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) => SizedBox(
          height: 250,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Select Pain Level',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 40,
                  physics: const FixedExtentScrollPhysics(),
                  controller: FixedExtentScrollController(
                    initialItem: currentPain,
                  ),
                  onSelectedItemChanged: (index) =>
                      cycleData.updatePain(viewDate, index),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 11,
                    builder: (context, index) => Center(
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget._selectedViewDate == null) {
      return const SizedBox.shrink();
    }

    final viewDate = widget._selectedViewDate!;
    final cycleData = widget.cycleData;
    final todayDate = widget.todayDate;
    int cycleNumber = 1; // Default to Cycle 1
    int dayInCycle = cycleData.getDayInCycle(viewDate);

    final bool isApple = Theme.of(context).platform == TargetPlatform.iOS;

    // Check if the viewed date is actually marked as a period day in history
    final bool isConfirmedToday = cycleData.selectedDates.any(
      (d) => DateUtils.isSameDay(d, viewDate),
    );

    final DateTime? firstStart = widget.cycleData.firstRecordedPeriodStart;

    // Determine if the 'Confirm' button should be shown for future dates (Ongoing Period logic)
    bool isFutureConfirmable = false;
    if (viewDate.isAfter(todayDate) && cycleData.selectedDates.isNotEmpty) {
      final latestConfirmed = cycleData.selectedDates.last; // History is sorted
      if (latestConfirmed != null) {
        final bool isOngoing =
            latestConfirmed.isAfter(todayDate) ||
            DateUtils.isSameDay(latestConfirmed, todayDate);

        if (isOngoing) {
          final int diff = viewDate.difference(latestConfirmed).inDays;
          isFutureConfirmable = diff > 0 && diff <= 4;
        }
      }
    }

    final bool isConfirmable =
        (firstStart != null &&
            (viewDate.isAfter(firstStart) ||
                DateUtils.isSameDay(viewDate, firstStart)) &&
            (viewDate.isBefore(todayDate) ||
                DateUtils.isSameDay(viewDate, todayDate))) ||
        isFutureConfirmable;

    // Generate dynamic status reports for the selected day
    String? statusReport;
    if (cycleData.selectedDates.isNotEmpty && dayInCycle > 0) {
      final menses = cycleData.mensesLength;
      final cycle = cycleData.cycleLength;
      final ov = cycleData.ovulationDayNumber;

      // 1. Period status (Start/End)
      final String pReport = isConfirmedToday
          ? 'Logged period'
          : (dayInCycle <= menses
                ? (menses - dayInCycle == 0
                      ? 'Period ends today'
                      : 'Period ends in ${menses - dayInCycle} days')
                : 'Period will start in ${cycle - dayInCycle + 1} days');

      // 2. Ovulation status
      final String oReport = dayInCycle == ov
          ? 'Ovulation today'
          : (dayInCycle < ov
                ? 'Ovulation in ${ov - dayInCycle} days'
                : 'Ovulation in ${cycle - dayInCycle + ov} days');

      // 3. Fertile Window status
      String fReport = '';
      const int postOvulationBuffer = 4; // Matches logic in CycleProvider
      if (cycleData.isPredictedFertileDay(viewDate)) {
        final rem = (ov + postOvulationBuffer) - dayInCycle;
        fReport =
            ' • Fertile window ${rem == 0 ? 'ends today' : 'ends in $rem days'}';
      }

      // 4. Missed Period advice (Medically accurate)
      String mReport = '';
      final bool isToday = DateUtils.isSameDay(viewDate, todayDate);

      // Days since expected start (Day 1 = first day of missed period)
      final int daysLate =
          todayDate.difference(cycleData.nextPeriodDate).inDays + 1;

      if (isToday && !isConfirmedToday && daysLate >= 1) {
        if (daysLate == 1) {
          mReport =
              '\nPeriod late? Consider taking a pregnancy test or consulting a doctor.';
        } else if (daysLate >= 7) {
          mReport =
              '\nTesting 1–2 weeks after a missed period provides the most reliable results.';
        }
      }
      statusReport = '$pReport • $oReport$fReport$mReport';
    }

    return Center(
      child: Column(
        children: [
          Container(
            // width: 300,
            margin: const EdgeInsets.symmetric(horizontal: 25),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.pink.shade100),
              color: Colors.pink.shade50,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${DateFormat('MMMM d').format(viewDate)} | Cycle $cycleNumber, Day $dayInCycle',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (statusReport != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          statusReport,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.pink.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Body logic
                    if (cycleData.isPredictedOvulationDay(viewDate))
                      const Text(
                        'Ovulation Day - High chance of pregnancy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (cycleData.isPredictedFertileDay(viewDate))
                      Text(
                        dayInCycle >= (cycleData.ovulationDayNumber - 2) &&
                                dayInCycle <= cycleData.ovulationDayNumber
                            ? 'High chance of pregnancy'
                            : 'Medium chance of pregnancy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                    if (isConfirmedToday) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(
                            Icons.water_drop,
                            color: Colors.red,
                            size: 20,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(
                                    'Flow: ${CycleProvider.flowIntensityLabels[cycleData.getFlowForDate(viewDate).round().clamp(0, CycleProvider.flowIntensityLabels.length - 1)]}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Slider(
                                  value: cycleData.getFlowForDate(viewDate),
                                  min: 0,
                                  max: 4,
                                  divisions: 4,
                                  activeColor: Colors.redAccent,
                                  onChanged: (val) {
                                    setState(() {
                                      cycleData.updateFlow(viewDate, val);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Pain Tolerance Button
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Pain Level',
                                style: TextStyle(fontSize: 10),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _showPainPicker(
                                  context,
                                  cycleData,
                                  viewDate,
                                  isApple,
                                ),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Colors.pink,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${cycleData.getPainForDate(viewDate)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                // The 'Confirm' button is now available for any day from the first
                // recorded period start up to today, provided it's not already logged.
                // This allows for easy confirmation of both predicted and unpredicted
                // period days.
                if (isConfirmable && !isConfirmedToday)
                  Positioned(
                    top: -10,
                    right: -10,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        final bool? isPeriod = await showDialog<bool>(
                          context: context,
                          builder: (context) =>
                              const ConfirmPeriodDialog(type: 'Period'),
                        );

                        if (isPeriod == true &&
                            widget.onConfirmPeriod != null) {
                          // When user confirms 'Yes', trigger callback to convert the
                          // predicted day into an actual period cycle day.
                          // This updates the data model and UI accordingly.
                          widget.onConfirmPeriod!(viewDate, true);
                        }
                      },

                      child: Icon(Icons.water_drop_outlined),
                      // child: const Text(
                      //   'Confirm',
                      //   style: TextStyle(
                      //     fontSize: 11,
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// CONFIRM PERIOD DIALOG CLASS
class ConfirmPeriodDialog extends StatelessWidget {
  final String type;
  const ConfirmPeriodDialog({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Confirm Period'),
      content: const Text('Are you on your period today?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No'),
        ),

        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Yes'),
        ),
      ],
    );
  }
}
