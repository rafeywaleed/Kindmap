import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Below this viewport width, the app renders normally (phones, most
/// tablets in portrait). Above it, web users are asked to switch to a
/// mobile device or opt into a constrained mobile-width frame.
const double kWebMobileBreakpoint = 600;

/// Width of the centered "mobile frame" shown when a desktop/laptop
/// user chooses to continue anyway.
const double kWebMobileFrameWidth = 430;

/// Wraps the app on Web: if the viewport is wider than
/// [kWebMobileBreakpoint] (laptop/desktop), shows a friendly message
/// asking the user to switch to a mobile device, with a "Use anyway"
/// option that letterboxes the app into a centered mobile-width frame.
///
/// On non-web platforms this is a no-op passthrough.
class ResponsiveWebGate extends StatefulWidget {
  final Widget child;

  const ResponsiveWebGate({super.key, required this.child});

  @override
  State<ResponsiveWebGate> createState() => _ResponsiveWebGateState();
}

class _ResponsiveWebGateState extends State<ResponsiveWebGate> {
  bool _useAnyway = false;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;

    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > kWebMobileBreakpoint;

    if (!isWide) return widget.child;

    if (!_useAnyway) {
      return _DesktopNotice(onUseAnyway: () {
        setState(() => _useAnyway = true);
      });
    }

    // "Use anyway" — letterbox the app into a centered mobile-width frame.
    final theme = KMTheme.of(context);
    final frameHeight = mq.size.height;

    return ColoredBox(
      color: theme.alternate.withOpacity(0.18),
      child: Center(
        child: Container(
          width: kWebMobileFrameWidth,
          height: frameHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: MediaQuery(
            data: mq.copyWith(size: Size(kWebMobileFrameWidth, frameHeight)),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _DesktopNotice extends StatelessWidget {
  final VoidCallback onUseAnyway;

  const _DesktopNotice({required this.onUseAnyway});

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1214) : const Color(0xFFF5EFEE),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF1E1416)
                        : const Color(0xFFFAC6C3),
                    border: Border.all(
                      color: theme.primary.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primary.withOpacity(0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.phone_iphone_rounded,
                    size: 38,
                    color: theme.primary,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Please use a mobile device',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: isDark ? Colors.white : const Color(0xFF0E1214),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'KindMap is designed for mobile screens — maps, the '
                  'camera and notifications work best on a phone or '
                  'tablet. Please open this page on a mobile device for '
                  'the full experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Readex Pro',
                    fontSize: 14,
                    height: 1.6,
                    color: isDark
                        ? Colors.white.withOpacity(0.6)
                        : Colors.black.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onUseAnyway,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.08),
                        ),
                      ),
                    ),
                    child: Text(
                      'Use anyway',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
