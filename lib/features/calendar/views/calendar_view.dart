import 'package:flutter/material.dart' hide DateUtils;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/core/core.dart';
import 'package:period_tracker/features/calendar/viewmodels/calendar_viewmodel.dart';
import 'package:period_tracker/features/calendar/models/calendar_model.dart';
import 'package:period_tracker/features/dashboard/viewmodels/dashboard_viewmodel.dart';

class CalendarView extends StatefulWidget {
  final DashboardViewModel dashboardViewModel;
  
  const CalendarView({
    super.key,
    required this.dashboardViewModel,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late CalendarViewModel _calendarViewModel;
  DateTime? _selectedDate;
  
  @override
  void initState() {
    super.initState();
    _calendarViewModel = CalendarViewModel(widget.dashboardViewModel);
    _selectedDate = DateTime.now();
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _calendarViewModel,
      child: Consumer<CalendarViewModel>(
        builder: (context, viewModel, child) {
          final monthData = viewModel.getCurrentMonthData();
          final firstWeekday = DateTime(monthData.month.year, monthData.month.month, 1).weekday;
          
          return Scaffold(
            appBar: AppBar(
              title: Text(
                DateFormat('MMMM yyyy').format(monthData.month),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => viewModel.previousMonth(),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => viewModel.nextMonth(),
                ),
              ],
            ),
            body: Column(
              children: [
                _buildWeekHeader(),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: firstWeekday % 7 + monthData.days.length,
                    itemBuilder: (context, index) {
                      if (index < firstWeekday % 7) {
                        return const SizedBox.shrink();
                      }
                      
                      final dayIndex = index - (firstWeekday % 7);
                      final day = monthData.days[dayIndex];
                      final events = monthData.events[day] ?? [];
                      final isToday = viewModel.isToday(day);
                      final isSelected = viewModel.isSelected(day, _selectedDate!);
                      
                      return _buildDayCell(day, events, isToday, isSelected, viewModel);
                    },
                  ),
                ),
                if (_selectedDate != null) _buildEventList(_selectedDate!),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildWeekHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
            .asMap()
            .entries
            .map((entry) => Expanded(
                  child: Center(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: entry.key == 6 ? Colors.blueGrey : Colors.pink,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
  
  Widget _buildDayCell(
    DateTime day,
    List<CalendarEvent> events,
    bool isToday,
    bool isSelected,
    CalendarViewModel viewModel,
  ) {
    final hasPeriod = events.any((e) => e.type == CalendarEventType.period);
    final hasFertile = events.any((e) => e.type == CalendarEventType.fertile);
    final hasOvulation = events.any((e) => e.type == CalendarEventType.ovulation);
    
    Color? backgroundColor;
    Color textColor = Colors.black;
    
    if (isSelected) {
      backgroundColor = Colors.pink;
      textColor = Colors.white;
    } else if (isToday) {
      backgroundColor = Colors.pink.withValues(alpha: 0.1);
      textColor = Colors.pink;
    } else if (hasPeriod) {
      backgroundColor = AppTheme.periodColor.withValues(alpha: 0.2);
      textColor = AppTheme.periodColor;
    } else if (hasOvulation) {
      backgroundColor = AppTheme.ovulationColor.withValues(alpha: 0.2);
      textColor = AppTheme.ovulationColor;
    } else if (hasFertile) {
      backgroundColor = AppTheme.fertileColor.withValues(alpha: 0.2);
      textColor = AppTheme.fertileColor;
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = day;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(color: Colors.pink, width: 2)
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                day.day.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
            ),
            if (events.isNotEmpty)
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: events.take(3).map((e) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: e.color,
                      shape: BoxShape.circle,
                    ),
                  )).toList(),
                ),
              ),
          ],
        ),
      ).animate().scale(duration: 150.ms, delay: (day.day * 10).ms),
    );
  }
  
  Widget _buildEventList(DateTime selectedDate) {
    final events = _calendarViewModel.getEventsForDate(selectedDate);
    
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Events for ${DateFormat('MMM d, yyyy').format(selectedDate)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return ListTile(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: event.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(event.title),
                  subtitle: event.description != null ? Text(event.description!) : null,
                  dense: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}