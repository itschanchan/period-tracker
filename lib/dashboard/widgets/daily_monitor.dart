import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

// Project files
import '../../providers/cycle_provider.dart';
import '../widgets/health_logger.dart';

/// Mapping of symptom/activity names to HugeIcons
final Map<String, dynamic> logIconMapping = {
  // Symptoms
  'Everything is fine': HugeIcons.strokeRoundedTick01,
  'Cramps': HugeIcons.strokeRoundedFlash,
  'Tender breasts': HugeIcons.strokeRoundedCircle,
  'Headache': HugeIcons.strokeRoundedBrain,
  'Acne (breakouts)': HugeIcons.strokeRoundedFaceId,
  'Backache': HugeIcons.strokeRoundedBodyPartMuscle,
  'Fatigue': HugeIcons.strokeRoundedBatteryLow,
  'Cravings': HugeIcons.strokeRoundedPizza01,
  'Insomnia': HugeIcons.strokeRoundedMoon02,
  'Abdominal Pain': HugeIcons.strokeRoundedBackMuscleBody,
  'Vaginal itching': HugeIcons.strokeRoundedOval,
  'Vaginal dryness': HugeIcons.strokeRoundedDroplet,
  'Calm': HugeIcons.strokeRoundedSunrise,
  'Happy': HugeIcons.strokeRoundedHappy,
  'Energetic': HugeIcons.strokeRoundedEnergy,
  // Activities
  'Positive': HugeIcons.strokeRoundedAdd01,
  'Negative': HugeIcons.strokeRoundedMinusSignCircle,
  'Protected sex': HugeIcons.strokeRoundedShield01,
  'Unprotected sex': HugeIcons.strokeRoundedFavourite,
  'Yoga': HugeIcons.strokeRoundedYoga01,
  'Gym': HugeIcons.strokeRoundedDumbbell01,
  'Running': HugeIcons.strokeRoundedRunningShoes,
  'Cycling': HugeIcons.strokeRoundedBicycle,
  'Walking': HugeIcons.strokeRoundedWalking,
  'Travel': HugeIcons.strokeRoundedAirplane01,
  'Stress': HugeIcons.strokeRoundedDead,
  'Meditation': HugeIcons.strokeRoundedYoga02,
};

dynamic _getIcon(String name) =>
    logIconMapping[name] ?? HugeIcons.strokeRoundedQuestion;

class LogTagList extends StatelessWidget {
  final Set<String> items;
  const LogTagList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text(
        'None logged',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.pink.shade100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: _getIcon(item), color: Colors.pink, size: 14),
              const SizedBox(width: 4),
              Text(
                item,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.pink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Main Constructor
class HealthLog extends StatefulWidget {
  final DateTime selectedViewDate;
  final DateTime todayDate;

  const HealthLog({
    super.key,
    required this.selectedViewDate,
    required this.todayDate,
  });

  @override
  State<HealthLog> createState() => _HealthLogState();
}

// Main Class
class _HealthLogState extends State<HealthLog> {
  void _showSymptomsDialog(BuildContext context, String type, DateTime date) {
    showDialog(
      context: context,
      builder: (context) => SymptomsDialog(type: type, date: date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cycleData = context.watch<CycleProvider>();
    final viewDate = widget.selectedViewDate;
    final todayDate = widget.todayDate;
    bool showSymptoms = false;
    int cycleNumber = 1;
    bool isApple = Theme.of(context).platform == TargetPlatform.iOS;

    if (cycleData.firstRecordedPeriodStart != null) {
      final firstPeriodStart = DateUtils.dateOnly(
        cycleData.firstRecordedPeriodStart!,
      );
      final normalizedViewDate = DateUtils.dateOnly(viewDate);
      final normalizedToday = DateUtils.dateOnly(todayDate);

      final diffFromFirstPeriod = normalizedViewDate
          .difference(firstPeriodStart)
          .inDays;

      if (diffFromFirstPeriod >= 0) {
        // Calculate current cycle number
        cycleNumber = (diffFromFirstPeriod / cycleData.cycleLength).floor() + 1;

        // Symptoms & Activities should only display from the first record up to TODAY
        showSymptoms =
            (normalizedViewDate.isBefore(normalizedToday) ||
                DateUtils.isSameDay(normalizedViewDate, normalizedToday)) &&
            (normalizedViewDate.isAfter(firstPeriodStart) ||
                DateUtils.isSameDay(normalizedViewDate, firstPeriodStart));
      }
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Daily Monitoring',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                // GestureDetector(
                //   onTap: () => print("oh I tapped it!"),
                //   child: Text('Edit'),
                // ),
              ],
            ),

            const SizedBox(height: 16),

            // Mood & Health Log Row
            Row(
              children: [
                // Mood Log
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.mood, color: Colors.orange),
                    title: const Text('Mood'),
                    subtitle: const Text('Happy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ), // Prevents the space to bleed.
                // Health Log
                ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) =>
                        VitalsDialog(date: widget.selectedViewDate),
                  ),
                  child: const Text('Log Your Health'),
                ),
              ],
            ),

            if (showSymptoms) ...[
              // Symptoms Section
              ListTile(
                leading: const Icon(Icons.monitor_weight, color: Colors.blue),
                title: const Text(
                  'Symptoms',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: LogTagList(
                    items: cycleData.getSymptomsForDate(viewDate),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSymptomsDialog(context, 'Symptoms', viewDate),
              ),
              // Activities Section
              ListTile(
                leading: const Icon(Icons.directions_run, color: Colors.green),
                title: const Text(
                  'Activities',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: LogTagList(
                    items: cycleData.getActivitiesForDate(viewDate),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _showSymptomsDialog(context, 'Activities', viewDate),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class VitalsDialog extends StatelessWidget {
  final DateTime date;
  const VitalsDialog({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Your Health'),
      content: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HealthLogger(date: date), // Integrated HealthLogger here
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class SymptomsDialog extends StatefulWidget {
  final String type;
  final DateTime date;
  const SymptomsDialog({super.key, required this.type, required this.date});

  @override
  State<SymptomsDialog> createState() => _SymptomsDialogState();
}

class _SymptomsDialogState extends State<SymptomsDialog> {
  late Set<String> _tempSelection;

  @override
  void initState() {
    super.initState();
    final cycleData = context.read<CycleProvider>();
    _tempSelection = Set.from(
      widget.type == 'Symptoms'
          ? cycleData.getSymptomsForDate(widget.date)
          : cycleData.getActivitiesForDate(widget.date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cycleData = context.read<CycleProvider>();
    final Map<String, List<String>> categories = widget.type == 'Symptoms'
        ? {
            'Symptoms': [
              'Everything is fine',
              'Cramps',
              'Tender breasts',
              'Headache',
              'Acne (breakouts)',
              'Backache',
              'Fatigue',
              'Cravings',
              'Insomnia',
              'Abdominal Pain',
              'Vaginal itching',
              'Vaginal dryness',
            ],
            'Mood': [
              'Calm',
              'Happy',
              'Energetic',
              'Frisky',
              'Mood swings',
              'Irritated',
              'Sad',
              'Anxious',
              'Depressed',
              'Feeling guilty',
              'Obsessive thoughts',
              'Low energy',
              'Apathetic',
              'Confused',
              'Very self-critical',
            ],
            'Sex Drive': [
              'High sex drive',
              'Neutral sex drive',
              'Low sex drive',
            ],
            'Vaginal Discharge': [
              'No discharge',
              'Creamy',
              'Watery',
              'Sticky',
              'Egg white',
              'Spotting',
              'Unusual',
              'Clumpy white',
              'Gray',
            ],
            'Digestion & Stool': [
              'Nausea',
              'Bloating',
              'Constipation',
              'Diarrhea',
            ],
          }
        : {
            'Pregnancy Test': [
              "Didn't take tests",
              'Positive',
              'Negative',
              'Faint line',
            ],
            'Ovulation Test (OPK)': [
              "Didn't take tests",
              'Test: positive',
              'Test: negative',
              'Ovulation: my method',
            ],
            'Sex': [
              "Didn't have sex",
              'Protected sex',
              'Unprotected sex',
              'Oral sex',
              'Anal sex',
              'Masturbation',
              'Sensual touch',
              'Sex toys',
              'Orgasm',
            ],
            'Physical Activities': [
              "Didn't exercise",
              'Yoga',
              'Gym',
              'Aerobics & dancing',
              'Swimming',
              'Team sports',
              'Running',
              'Cycling',
              'Walking',
            ],
            'Other Activities': [
              'Travel',
              'Stress',
              'Meditation',
              'Journaling',
              'Kegel exercises',
              'Breathing exercises',
              'Disease or injury',
              'Alcohol',
            ],
          };

    return AlertDialog(
      title: Text('Add ${widget.type}'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: categories.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                      dense: true,
                    ),
                    const Divider(height: 1),
                    ...entry.value.map((item) {
                      final isSelected = _tempSelection.contains(item);
                      return ListTile(
                        leading: HugeIcon(
                          icon: _getIcon(item),
                          color: isSelected ? Colors.pink : Colors.grey,
                          size: 20,
                        ),
                        title: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? Colors.pink : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: Colors.pink.shade50,
                        dense: true,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _tempSelection.remove(item);
                            } else {
                              _tempSelection.add(item);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            if (widget.type == 'Symptoms') {
              cycleData.updateSymptoms(widget.date, _tempSelection);
            } else {
              cycleData.updateActivities(widget.date, _tempSelection);
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
