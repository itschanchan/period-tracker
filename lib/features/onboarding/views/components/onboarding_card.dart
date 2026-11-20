import 'package:flutter/material.dart';

class OnboardingCard extends StatelessWidget {
  final String image, title, description, buttonText;
  final Function onPressed; // responsible for buttons

  const OnboardingCard({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.80,
      width: MediaQuery.sizeOf(context).width,
      //   color: Colors.pink,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          Padding(
            padding: const EdgeInsets.all(50.0),
            child: Image.asset(image, fit: BoxFit.contain),
          ),

          // TEXT COLUMN
          Column(
            children: [
              // TITLE
              Text(
                title, // pass the title parameter to the text
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 10),

              // DESCRIPTION
              Text(
                description, // pass the description parameter to the text
                textAlign: TextAlign.center,
                style: TextStyle(
                  //   color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                  //   fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          MaterialButton(
            minWidth: 300,
            onPressed: () => onPressed(),
            color: Theme.of(context).colorScheme.primary,
            child: Text(
              buttonText, // pass the buttonTextparameter to the button
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}