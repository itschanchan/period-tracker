import 'package:intl/intl.dart';

class DateUtils {
  static final DateFormat _dayFormat = DateFormat('d');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _fullDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  
  static String formatDay(DateTime date) => _dayFormat.format(date);
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);
  static String formatFullDate(DateTime date) => _fullDateFormat.format(date);
  static String formatDisplayDate(DateTime date) => _displayDateFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);
  
  static DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);
  static DateTime endOfDay(DateTime date) => DateTime(date.year, date.month, date.day, 23, 59, 59);
  
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
  
  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());
  
  static int daysBetween(DateTime start, DateTime end) {
    final startDay = startOfDay(start);
    final endDay = startOfDay(end);
    return endDay.difference(startDay).inDays;
  }
  
  static DateTime addDays(DateTime date, int days) => date.add(Duration(days: days));
  static DateTime subtractDays(DateTime date, int days) => date.subtract(Duration(days: days));
  
  static List<DateTime> getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final days = <DateTime>[];
    
    for (int i = 0; i <= lastDay.difference(firstDay).inDays; i++) {
      days.add(firstDay.add(Duration(days: i)));
    }
    return days;
  }
  
  static int getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final dayOfMonth = date.day;
    final weekdayOfFirstDay = firstDayOfMonth.weekday;
    return ((dayOfMonth + weekdayOfFirstDay - 1) / 7).ceil();
  }
}