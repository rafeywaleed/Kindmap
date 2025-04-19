import 'package:flutter/material.dart';
import 'package:kindmap/themes/kmTheme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class IntroScreens extends StatefulWidget {
  const IntroScreens({super.key});

  @override
  State<IntroScreens> createState() => _IntroScreensState();
}

class _IntroScreensState extends State<IntroScreens> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<IntroPage> _pages = [
    IntroPage(
      imagePath: 'assets/images/Screenshot_2024-02-25_195318.png',
      isPortrait: false,
    ),
    IntroPage(
      imagePath: 'assets/images/Screenshot_2024-02-25_195346.png',
      isPortrait: true,
    ),
    IntroPage(
      imagePath: 'assets/images/Screenshot_2024-02-25_195318.png',
      isPortrait: false,
    ),
    IntroPage(
      imagePath: 'assets/images/Screenshot_2024-02-25_195435.png',
      isPortrait: true,
    ),
    IntroPage(
      imagePath: 'assets/images/Screenshot_2024-02-25_201212.png',
      isPortrait: true,
      isLastPage: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    final theme = KMTheme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _IntroPageContent(
                    imagePath: page.imagePath,
                    isPortrait: page.isPortrait,
                    isLastPage: page.isLastPage,
                    isWeb: isWeb,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: _PageIndicator(
                controller: _pageController,
                count: _pages.length,
                currentPage: _currentPage,
                theme: theme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IntroPage {
  final String imagePath;
  final bool isPortrait;
  final bool isLastPage;

  IntroPage({
    required this.imagePath,
    this.isPortrait = false,
    this.isLastPage = false,
  });
}

class _IntroPageContent extends StatelessWidget {
  final String imagePath;
  final bool isPortrait;
  final bool isLastPage;
  final bool isWeb;

  const _IntroPageContent({
    required this.imagePath,
    required this.isPortrait,
    required this.isLastPage,
    required this.isWeb,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 100 : 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: isPortrait
                  ? _buildPortraitImage(context)
                  : _buildLandscapeImage(context),
            ),
          ),
          if (isLastPage) _buildDoneButton(context),
        ],
      ),
    );
  }

  Widget _buildPortraitImage(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
        maxWidth: MediaQuery.of(context).size.width * 0.9,
      ),
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildLandscapeImage(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
        maxWidth: MediaQuery.of(context).size.width * 0.9,
      ),
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    final theme = KMTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pushNamed('/avatars'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.info,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Done',
          style: theme.titleSmall.copyWith(
            color: theme.error,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final PageController controller;
  final int count;
  final int currentPage;
  final KMTheme theme;

  const _PageIndicator({
    required this.controller,
    required this.count,
    required this.currentPage,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SmoothPageIndicator(
      controller: controller,
      count: count,
      effect: ExpandingDotsEffect(
        expansionFactor: 3,
        spacing: 8,
        radius: 16,
        dotWidth: 16,
        dotHeight: 8,
        dotColor: theme.accent1,
        activeDotColor: theme.error,
      ),
      onDotClicked: (index) => controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
      ),
    );
  }
}
