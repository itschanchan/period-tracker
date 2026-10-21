import 'package:flutter/material.dart';
import 'package:period_tracker/frontend/onboarding_page/widgets/onboarding_card.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static final PageController _pageController = PageController(initialPage: 0);

  final List<Widget> _onboardingPages = [
    OnboardingCard(
      image: "lib/frontend/assets/images/image_welcome.png",
      title: "Welcome to bebi's Period Tracker!",
      description: "I love you so much",
      buttonText: "Next",

      // animateToPage: index, duration, curve
      // Curves - transition effects
      onPressed: () {
        _pageController.animateToPage(
          1,
          duration: Durations.long1,
          curve: Curves.linear,
        );
      },
    ),

    OnboardingCard(
      image: "lib/frontend/assets/images/image_clipboard.png",
      title: "What's your usual cycle?",
      description: "Display buttons here",
      buttonText: "Next",
      onPressed: () {
        _pageController.animateToPage(
          2,
          duration: Durations.long1,
          curve: Curves.linear,
        );
      },
    ),

    OnboardingCard(
      image: "lib/frontend/assets/images/image_period_calendar.png",
      title: "Select your period now!",
      description: "Display buttons here",
      buttonText: "Done",
      onPressed: () {
        _pageController.animateToPage(
          3,
          duration: Durations.long1,
          curve: Curves.linear,
        );
      },
    ),
  ];

  // use dispose to prevent memory leaks when closing the onboarding page.
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 20,
          children: [
            Expanded(
              /*
                PageView: widget that allows us to embed children within it
                and you can navigate across children using swipe gesture.
              */
              child: PageView(
                controller: _pageController,
                children: _onboardingPages,
              ),
            ),

            // ANIMATED PAGE INDICATOR
            SmoothPageIndicator(
              controller: _pageController,
              count: _onboardingPages.length,
              effect: ColorTransitionEffect(
                activeDotColor: Theme.of(context).colorScheme.primary,
                dotColor: Colors.grey, // inactive dot color
              ),

              onDotClicked: (index) {
                _pageController.animateToPage(
                  index,
                  duration: Durations.long1,
                  curve: Curves.linear,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
