import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart'; // Import for HugeIcon
import 'package:period_tracker/dashboard/widgets/daily_monitor.dart'; // Import for SymptomsDialog

class HealthLogger extends StatefulWidget {
  final DateTime date; // Add date parameter
  const HealthLogger({super.key, required this.date});

  @override
  State<HealthLogger> createState() => _HealthLoggerState();
}

class _HealthLoggerState extends State<HealthLogger> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300, // Provides a bounded width for the horizontal scroll view
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Drink Water Section
            _buildSection(
              title: 'Drink Water',
              icon: Icons.water,
              overlayButtons: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.remove)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
              ],
              content: Column(
                children: [
                  const Text(
                    '0/1 L',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ListTile(
                    title: const Text('Set up Reminders'),
                    trailing: const Icon(Icons.chevron_right),
                    dense: true,
                    onTap: () {}, // Interactive callback
                  ),
                ],
              ),
            ),

            const Divider(),

            // Other Pills Section
            _buildSection(
              title: 'Other Pills',
              icon: Icons.medication,
              content: Column(
                children: [
                  const Text('Log other pills you take a day.'),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('Add pill'),
                  ),
                  ListTile(
                    title: const Text('Set up Reminders'),
                    trailing: const Icon(Icons.chevron_right),
                    dense: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const Divider(),

            // Weight Section
            _buildSection(
              title: 'Weight',
              icon: Icons.monitor_weight,
              overlayButtons: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.delete)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
              ],
              content: Column(
                children: [
                  const Text(
                    '60kg',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ListTile(
                    title: const Text('View Chart'),
                    trailing: const Icon(Icons.chevron_right),
                    dense: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const Divider(),

            // Basal Temperature Section
            _buildSection(
              title: 'Basal Temperature',
              icon: Icons.thermostat,
              overlayButtons: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.delete)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
              ],
              content: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Log your temperature'),
                  ),
                  ListTile(
                    title: const Text('View Chart'),
                    trailing: const Icon(Icons.chevron_right),
                    dense: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const Divider(),

            // Notes Section
            _buildSection(
              title: 'Notes',
              icon: Icons.edit_note,
              overlayButtons: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.delete)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
              ],
              content: const Column(
                children: [
                  TextField(
                    minLines: 2,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Add a note...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to build a consistent section with an optional button overlay
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget content,
    List<Widget>? overlayButtons,
  }) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.pink),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              content,
            ],
          ),
        ),
        if (overlayButtons != null)
          Positioned(top: 0, right: 0, child: Row(children: overlayButtons)),
      ],
    );
  }

  Widget _buildVitalItem({
    required BuildContext context,
    required dynamic icon,
    required String label,
    required String value,
    required String type,
    required DateTime date, // Add date parameter
  }) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (context) =>
            SymptomsDialog(type: type, date: date), // Use the passed date
      ),
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
}
