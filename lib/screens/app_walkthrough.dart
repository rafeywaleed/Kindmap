import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../config/app_theme.dart';

const String kHasSeenWalkthroughKey = 'has_seen_app_walkthrough';

/// Marks the onboarding walkthrough as seen so it won't auto-show again.
Future<void> markWalkthroughSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kHasSeenWalkthroughKey, true);
}

/// Whether the user has already completed or skipped the walkthrough.
Future<bool> hasSeenWalkthrough() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kHasSeenWalkthroughKey) ?? false;
}

class _WalkthroughPageData {
  final IconData icon;
  final String title;
  final String description;

  const _WalkthroughPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

const List<_WalkthroughPageData> _kWalkthroughPages = [
  _WalkthroughPageData(
    icon: Icons.volunteer_activism_rounded,
    title: 'Welcome to KindMap',
    description:
        'KindMap connects people who need help with people nearby who can '
        'give it — all on one simple map.',
  ),
  _WalkthroughPageData(
    icon: Icons.map_outlined,
    title: 'Explore the map',
    description:
        'The map is divided into grids. Browse nearby grids to see active '
        'requests and offers of help around you.',
  ),
  _WalkthroughPageData(
    icon: Icons.add_location_alt_rounded,
    title: 'Drop a pin',
    description:
        'Tap the pin button, take a photo, and place a pin to ask for help '
        'or offer it. Your pin appears on the map for others nearby to see.',
  ),
  _WalkthroughPageData(
    icon: Icons.notifications_active_rounded,
    title: 'Stay notified',
    description:
        'Turn on notifications to know when someone nearby needs help, or '
        'when someone responds to your pin.',
  ),
  _WalkthroughPageData(
    icon: Icons.account_circle_rounded,
    title: 'Track your impact',
    description:
        'Visit your profile to see how many people you\'ve helped, change '
        'your avatar, and manage your account anytime.',
  ),
];

/// Full-screen, multi-page onboarding walkthrough. Shown automatically the
/// first time a user reaches the home screen, and can be replayed any time
/// from Settings → Help.
class AppWalkthroughScreen extends StatefulWidget {
  const AppWalkthroughScreen({super.key});

  @override
  State<AppWalkthroughScreen> createState() => _AppWalkthroughScreenState();
}

class _AppWalkthroughScreenState extends State<AppWalkthroughScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    markWalkthroughSeen();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _next() {
    if (_page == _kWalkthroughPages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = _page == _kWalkthroughPages.length - 1;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0E1214) : const Color(0xFFF5EFEE),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: isLast
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextButton(
                          onPressed: _finish,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.45),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _kWalkthroughPages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) => _WalkthroughPage(
                  data: _kWalkthroughPages[index],
                  theme: theme,
                  isDark: isDark,
                ),
              ),
            ),
            SmoothPageIndicator(
              controller: _controller,
              count: _kWalkthroughPages.length,
              effect: ExpandingDotsEffect(
                dotWidth: 8,
                dotHeight: 8,
                spacing: 8,
                radius: 16,
                activeDotColor: theme.primary,
                dotColor: theme.primaryText.withOpacity(0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isLast ? 'Get Started' : 'Next',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryBtnText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalkthroughPage extends StatelessWidget {
  final _WalkthroughPageData data;
  final KMTheme theme;
  final bool isDark;

  const _WalkthroughPage({
    required this.data,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isDark ? const Color(0xFF1E1416) : const Color(0xFFFAC6C3),
              border: Border.all(
                color: theme.primary.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primary.withOpacity(0.18),
                  blurRadius: 32,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(data.icon, size: 54, color: theme.primary),
          ),
          const SizedBox(height: 36),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: isDark ? Colors.white : const Color(0xFF0E1214),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Readex Pro',
              fontSize: 14.5,
              height: 1.6,
              color: isDark
                  ? Colors.white.withOpacity(0.6)
                  : Colors.black.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}
