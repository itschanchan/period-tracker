import 'package:flutter/material.dart' hide DateUtils;
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'package:period_tracker/core/core.dart';
import 'health_log.dart';

class PeriodDescription extends StatelessWidget {
  final DateTime? _selectedViewDate;
  final DateTime todayDate;
  final DashboardViewModel cycleData;
  final Function(DateTime date, bool confirmed)? onConfirmPeriod;

  const PeriodDescription({
    super.key,
    required DateTime? selectedViewDate,
    required this.todayDate,
    required this.cycleData,
    this.onConfirmPeriod,
  }) : _selectedViewDate = selectedViewDate;

  @override
  Widget build(BuildContext context) {
    if (_selectedViewDate == null) {
      return const SizedBox.shrink();
    }

    final viewDate = _selectedViewDate;
    int cycleNumber = 1; // Default to Cycle 1
    int dayInCycle = cycleData.getDayInCycle(viewDate);

    // Generate dynamic status reports for the selected day
    String? statusReport;
    if (cycleData.cycleModel.periodDates.isNotEmpty && dayInCycle > 0) {
      final menses = cycleData.mensesLength;
      final cycle = cycleData.cycleLength;
      final ov = cycleData.ovulationDayNumber;

      // Check if the viewed date is actually marked as a period day in history
      final bool isConfirmedToday = cycleData.cycleModel.periodDates.any(
        (d) => DateUtils.isSameDay(d, viewDate),
      );

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
                  ],
                ),
                // Only show the button if the viewed date falls on a predicted period day
                // Show the button only if the date is a predicted period day
                // AND the date is today or in the past.
                if (cycleData.isPredictedPeriodDay(viewDate) &&
                    (viewDate.isBefore(todayDate) ||
                        DateUtils.isSameDay(viewDate, todayDate)))
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

                        if (isPeriod == true && onConfirmPeriod != null) {
                          // When user confirms 'Yes', trigger callback to convert the
                          // predicted day into an actual period cycle day.
                          // This updates the data model and UI accordingly.
                          onConfirmPeriod!(viewDate, true);
                        }
                      },
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // VITALS SECTION
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildVitalItem(
                  icon: Icons.medication_outlined,
                  label: 'Meds',
                  value: 'Add',
                  onTap: () =>
                      _showSymptomsDialog(context, 'Medications', viewDate),
                ),
                _buildVitalItem(
                  icon: Icons.water_drop_outlined,
                  label: 'Water',
                  value: '0 ml',
                  onTap: () => _showSymptomsDialog(context, 'Water', viewDate),
                ),
                _buildVitalItem(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Weight',
                  value: '-- kg',
                  onTap: () => _showSymptomsDialog(context, 'Weight', viewDate),
                ),
                _buildVitalItem(
                  icon: Icons.thermostat_outlined,
                  label: 'Temp',
                  value: '36.6°C',
                  onTap: () =>
                      _showSymptomsDialog(context, 'Temperature', viewDate),
                ),
                _buildVitalItem(
                  icon: Icons.edit_note_outlined,
                  label: 'Notes',
                  value: 'Add',
                  onTap: () => _showSymptomsDialog(context, 'Notes', viewDate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalItem({
    required dynamic icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.pink.shade100),
          color: Colors.pink.shade50,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon is IconData
                ? Icon(icon, color: Colors.pink, size: 22)
                : HugeIcon(icon: icon, color: Colors.pink, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSymptomsDialog(BuildContext context, String type, DateTime date) {
    showDialog(
      context: context,
      builder: (context) => SymptomsDialog(type: type, date: date),
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
