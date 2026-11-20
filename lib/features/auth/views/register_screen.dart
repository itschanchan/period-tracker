import 'package:flutter/material.dart';

import 'package:period_tracker/core/routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Insert data values here :)
  bool _obscureText = true;

  DateTime? selectedDate;
  final TextEditingController _dateController = TextEditingController();

  // initialize DatePicker
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = pickedDate.toString().split(" ")[0];
      });
    } else {
      selectedDate = pickedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Register',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Full Name Input Row
                    Row(
                      children: [
                        // First Name
                        // Container(
                        //   margin: const EdgeInsets.all(10.0),
                        //   child: const Text(
                        //     'First Name:',
                        //     style: TextStyle(
                        //       fontSize: 11,
                        //       fontWeight: FontWeight.bold,
                        //     ),
                        //   ),
                        // ),

                        // First Name Field
                        // Use Expanded to prevent from having conflicts in redndering Widgets.
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'First Name',
                                hintText: 'e.g., John',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                          ),
                        ),

                        // Second Name
                        // Container(
                        //   margin: const EdgeInsets.all(8.0),
                        //   child: const Text(
                        //     'Second Name:',
                        //     style: TextStyle(
                        //       fontSize: 11,
                        //       fontWeight: FontWeight.bold,
                        //     ),
                        //   ),
                        // ),

                        // Second Name Field
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Second Name',
                                hintText: 'e.g., Andrei',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Last Name Input
                    Row(
                      children: [
                        // Last Name
                        // Container(
                        //   margin: const EdgeInsets.all(10.0),
                        //   child: const Text(
                        //     'Last Name:',
                        //     style: TextStyle(
                        //       fontSize: 11,
                        //       fontWeight: FontWeight.bold,
                        //     ),
                        //   ),
                        // ),

                        // Last Name Field
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Last Name',
                                hintText: 'e.g., Andrei',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Username Input Row
                    Row(
                      children: [
                        // Username
                        // Container(
                        //   margin: const EdgeInsets.all(10.0),
                        //   child: const Text(
                        //     'Username:',
                        //     style: TextStyle(
                        //       fontSize: 11,
                        //       fontWeight: FontWeight.bold,
                        //     ),
                        //   ),
                        // ),

                        // Username Field
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Username',
                                hintText: 'e.g. Bebi',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Email Input Row
                    Row(
                      children: [
                        // Email
                        // Container(
                        //   margin: const EdgeInsets.all(10.0),
                        //   child: const Text(
                        //     'Email:',
                        //     style: TextStyle(
                        //       fontSize: 11,
                        //       fontWeight: FontWeight.bold,
                        //     ),
                        //   ),
                        // ),

                        // Email Field
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Email',
                                hintText: 'user@email.com',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Password Field Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Password',
                                hintText: 'e.g., password123',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock),
                              ),
                              obscureText: _obscureText,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Confirm Password Field
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Confirm Password',
                                hintText: 'e.g., password123',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              obscureText: _obscureText,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 0),

                    // Show Password Button
                    Row(
                      children: [
                        Checkbox(
                          value: !_obscureText, // Initialized as unchecked
                          onChanged: (bool? value) {
                            setState(() {
                              _obscureText = !value!;
                            });
                          },
                        ),
                        const Text("Show Password"),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Birthdate Picker
                    Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _dateController,
                            decoration: InputDecoration(
                              labelText: 'Birthdate',
                              filled: true,
                              prefixIcon: Icon(Icons.calendar_today),
                              // Removes the lower border when unclicked.
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.pink),
                              ),
                            ),
                            readOnly: true, // Not editable
                            onTap: () {
                              _selectDate();
                            },
                          ),
                        ),
                      ],
                    ),

                    // OLD DATEPICKER
                    // Column(
                    //   mainAxisSize: MainAxisSize.min,
                    //   spacing: 20,
                    //   children: <Widget>[
                    //     Text(
                    //       selectedDate != null
                    //           ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                    //           : 'No Date Selected',
                    //     ),
                    //     OutlinedButton(
                    //       onPressed: _selectDate,
                    //       child: const Text('Select Birthdate'),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 50),

                    // Register Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, AppRoutes.login);
                          },
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}