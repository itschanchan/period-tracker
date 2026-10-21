import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:period_tracker/data/data.dart';
import 'package:period_tracker/features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'package:period_tracker/features/dashboard/views/components/period_calendar.dart';

/// In-memory repository so the test does not depend on platform channels.
class _FakeCycleRepository implements CycleRepository {
  Map<String, dynamic>? _cycleData;
  Map<String, dynamic>? _userSettings;

  @override
  Future<void> clearCycleData() async => _cycleData = null;

  @override
  Future<void> clearUserSettings() async => _userSettings = null;

  @override
  Map<String, dynamic>? getCycleData() => _cycleData;

  @override
  Map<String, dynamic>? getUserSettings() => _userSettings;

  @override
  Future<void> saveCycleData(Map<String, dynamic> data) async =>
      _cycleData = data;

  @override
  Future<void> saveUserSettings(Map<String, dynamic> settings) async =>
      _userSettings = settings;
}

void main() {
  setUpAll(() {
    // Make VisibilityDetector updates synchronous in test environment
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets(
    'PeriodCalendar hides fertile window and ovulation dates in selection mode',
    (WidgetTester tester) async {
      // 1. Setup the view model with some period history to generate predictions
      final dashboardViewModel = DashboardViewModel(
        repository: _FakeCycleRepository(),
      );
      final anchorDate = DateTime(2026, 5, 1);
      dashboardViewModel.updateDates([anchorDate]);

      // Ovulation and Fertile window days should be predicted for the next cycle
      final ovulationDate = DateTime(2026, 5, 15);
      final fertileDate = DateTime(2026, 5, 12);

      expect(dashboardViewModel.isPredictedOvulationDay(ovulationDate), isTrue);
      expect(dashboardViewModel.isPredictedFertileDay(fertileDate), isTrue);

      // 2. Render calendar in NON-selection mode (isEditingPeriodDates = false)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DashboardViewModel>.value(
              value: dashboardViewModel,
              child: PeriodCalendar(
                calendarVersion: 0,
                selectedViewDate: anchorDate,
                firstDate: DateTime(2026, 5, 1),
                lastDate: DateTime(2026, 5, 30),
                now: anchorDate,
                todayDate: anchorDate,
                isEditingPeriodDates: false,
                value: [anchorDate],
                onDateTapped: (_) {},
                onDatesChanged: (_) {},
                onTodayVisibilityChanged: (_, _, _) {},
              ),
            ),
          ),
        ),
      );

      // Pump frames to let the visibility detector and other state settle
      await tester.pumpAndSettle();

      // Verify that ovulation (star) and fertile window (favorite) icons are present in normal mode
      expect(find.byIcon(Icons.star), findsAtLeast(1));
      expect(find.byIcon(Icons.favorite), findsAtLeast(1));

      // 3. Render calendar in selection/editing mode (isEditingPeriodDates = true)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DashboardViewModel>.value(
              value: dashboardViewModel,
              child: PeriodCalendar(
                calendarVersion: 1,
                selectedViewDate: anchorDate,
                firstDate: DateTime(2026, 5, 1),
                lastDate: DateTime(2026, 5, 30),
                now: anchorDate,
                todayDate: anchorDate,
                isEditingPeriodDates: true,
                value: [anchorDate],
                onDateTapped: (_) {},
                onDatesChanged: (_) {},
                onTodayVisibilityChanged: (_, _, _) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that ovulation and fertile window icons are completely hidden in selection mode
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.favorite), findsNothing);
    },
  );
}
