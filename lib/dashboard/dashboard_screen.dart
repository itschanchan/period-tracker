import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/cupertino.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.title});

  final String title; // Initializes the title of the page.

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Multi Scroll: step 1
  List<DateTime?> _dates = []; // Initialize an empty list for selected dates.
  Key _calendarKey =
      UniqueKey(); // use a key to recalculate the calendar's position.

  DateTime _focusedDay = DateTime.now(); // Initialized current date.

  bool _isEditingPeriodDates = false;
  List<DateTime?> _initialDatesForEdit =
      []; // Array to store dates before editing for potential cancellation.

  @override
  Widget build(BuildContext context) {
    // Checks if the device is an iOS device.
    // bool isApple = Platform.isIOS; (not platform aware)
    bool isApple =
        Theme.of(context).platform == TargetPlatform.iOS; // platform-aware

    // initialize DatePicker
    DateTime selectedDate = DateTime.now();

    // Retrieve the username from the route arguments
    final String displayUsername =
        (ModalRoute.of(context)?.settings.arguments as String?) ?? "Guest";

    return Scaffold(
      // Horizontal bar at the top of the screen.
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.inversePrimary /* safe for multi-platform checking */,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Welcome Message
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

              const SizedBox(height: 20),

              // Multi-Select Scroll Calendar
              // Step 2: Multi Scroll = Fixed Day Indicator (Header)
              // We build this manually so it stays fixed while you scroll the page.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['S', 'M', 'T', 'W', 'TH', 'F', 'S']
                      .asMap()
                      .entries
                      .map((entry) {
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
                      })
                      .toList(),
                ),
              ),

              // Wrapped in SizedBox to provide a fixed height inside a nested SingleChildScrollView
              SizedBox(
                height:
                    400, // Added height to allow the scrollable calendar to render within the SingleChildScrollView
                child: CalendarDatePicker2(
                  key: _calendarKey, // declare the key here.
                  config: CalendarDatePicker2Config(
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
                    selectedDayHighlightColor: Colors.pink,

                    // Hides the built-in Scroll Day Header
                    hideScrollViewTopHeader: true,

                    // Hides the built-in day labels
                    weekdayLabelTextStyle: const TextStyle(
                      color: Colors.transparent,
                    ),
                    // Disable selection for all days unless we are in editing mode
                    // It handles 'read-only' logic.
                    selectableDayPredicate: (day) => _isEditingPeriodDates,
                  ),
                  // The value dusplayed by the calendar.
                  // When editing, _dates is directly modified by onValueChanged.
                  value: _dates,
                  onValueChanged: (dates) {
                    // Only allow changes to the state if we are in editing mode
                    if (_isEditingPeriodDates) {
                      setState(() {
                        _dates = dates;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Back to current day button
              isApple
                  ? CupertinoButton.filled(
                      onPressed: () {
                        setState(() {
                          // To "Jump" to today without clearing other dates,
                          // today must be the first item in the list for this package's scroll mode.
                          // Note: This approach selects Today.
                          _dates = [
                            DateTime.now(),
                            ..._dates.where(
                              (d) => d != null && d.day != DateTime.now().day,
                            ),
                          ];
                        });
                        _calendarKey =
                            UniqueKey(); // Force the widget to rebuild and scroll to today
                      },
                      child: const Text('Go to Today'),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Selection logic same as above
                          _dates = [
                            DateTime.now(),
                            ..._dates.where(
                              (d) => d != null && d.day != DateTime.now().day,
                            ),
                          ];
                          _calendarKey =
                              UniqueKey(); // Force the widget to rebuild and scroll to today
                        });
                      },
                      child: const Text('Go to Today'),
                    ),

              const SizedBox(height: 20),

              // Edit Period Dates Button
              // Conditional rendering for Edit/Cancel/Save buttons
              _isEditingPeriodDates
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Cancel Button
                        isApple
                            ? CupertinoButton(
                                color: Colors.grey,
                                onPressed: () {
                                  setState(() {
                                    _dates = List.from(_initialDatesForEdit);
                                    _isEditingPeriodDates = false;
                                    _calendarKey = UniqueKey();
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
                                    _calendarKey = UniqueKey();
                                  });
                                },
                                child: const Text('Cancel'),
                              ),

                        // Save Button
                        isApple
                            ? CupertinoButton(
                                color: Colors.pink,
                                onPressed: () {
                                  setState(() {
                                    // _dates is already updated by onValueChanged
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
                                    // _dates is already updated by onValueChanged
                                    _isEditingPeriodDates = false;
                                  });
                                },
                                child: const Text('Save'),
                              ),
                      ],
                    )
                  : // Edit Period Dates Button
                    isApple
                  ? CupertinoButton(
                      color: Colors.pink,
                      onPressed: () {
                        setState(() {
                          _isEditingPeriodDates = true;
                          _initialDatesForEdit = List.from(
                            _dates,
                          ); // Store current dates for potential revert
                          _calendarKey =
                              UniqueKey(); // Refresh UI to enable selection
                        });
                      },
                      child: const Text(
                        'Edit Period Dates',
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
                          _isEditingPeriodDates = true;
                          _initialDatesForEdit = List.from(
                            _dates,
                          ); // Store current dates for potential revert
                          _calendarKey =
                              UniqueKey(); // Refresh UI to enable selection
                        });
                      },
                      child: const Text('Edit Period Dates'),
                    ),

              const SizedBox(height: 20),

              // Expanded(
              //   child: ListWheelScrollView.useDelegate(
              //     itemExtent: 60,
              //     perspective: 0.005,
              //     diameterRatio: 1.2,
              //     physics: const FixedExtentScrollPhysics(),
              //     onSelectedItemChanged: (index) {
              //       setState(() {
              //         selectedDate = DateTime.now().subtract(
              //           Duration(days: 365 - index),
              //         );
              //       });
              //     },
              //     childDelegate: ListWheelChildBuilderDelegate(
              //       childCount: 366,
              //       builder: (context, index) {
              //         DateTime date = DateTime.now().subtract(
              //           Duration(days: 365 - index),
              //         );

              //         bool isSelected =
              //             date.day == selectedDate.day &&
              //             date.month == selectedDate.month &&
              //             date.year == selectedDate.year;

              //         return Center(
              //           child: Text(
              //             "${date.day}/${date.month}/${date.year}",
              //             style: TextStyle(
              //               fontSize: isSelected ? 22 : 18,
              //               fontWeight: isSelected
              //                   ? FontWeight.bold
              //                   : FontWeight.normal,
              //               color: isSelected ? Colors.pink : Colors.grey,
              //             ),
              //           ),
              //         );
              //       },
              //     ),
              //   ),
              // ),

              // Row(
              //   // Parent position of the Row container
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   // Position of the children in the Row container
              //   crossAxisAlignment: CrossAxisAlignment.center,
              //   children: [
              //     const Text('Try the new period tracker!'),

              //     Image.network(
              //       "https://static.vecteezy.com/system/resources/previews/036/152/193/non_2x/uterus-cute-cartoon-character-in-kawaii-style-drop-of-blood-menstruation-women-health-female-reproductive-system-cycle-anatomy-cervix-ovaries-fallopian-tubes-illustration-flat-style-vector.jpg",
              //       // Saves RAM, good for thumbnails
              //       cacheWidth: null,
              //       cacheHeight: 100,
              //       fit: BoxFit.cover,
              //     ),
              //   ],
              // ),
              // Navigation Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      'Navigation Bar',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ],
              ),

              Container(
                // Margin (space outside)
                margin: const EdgeInsets.symmetric(horizontal: 20),
                // Padding (space inside)
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Icon(Icons.camera_alt, color: Colors.blue, size: 30),
                    Icon(Icons.video_library, color: Colors.blue, size: 30),
                    Icon(Icons.settings, color: Colors.blue, size: 30),
                    Icon(Icons.chat_bubble, color: Colors.blue, size: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/* 
  NOTES:
    - onValueChanged - acts as a second layer of securitym
    it ensures that even if a tap event were to slip through,
    the _dates state remains unchanged unless _isEditingPeriodDates
    is true.
*/
