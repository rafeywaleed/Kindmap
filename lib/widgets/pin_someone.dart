import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kindmap/screens/camera.dart';
import '../config/app_theme.dart';

class PinSomeoneButton extends StatefulWidget {
  final Size size;
  const PinSomeoneButton({super.key, required this.size});

  @override
  State<PinSomeoneButton> createState() => _PinSomeoneButtonState();
}

class _PinSomeoneButtonState extends State<PinSomeoneButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;
  bool _pressing = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.955).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTap() async {
    await _pressCtrl.forward();
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await _pressCtrl.reverse();

    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => const CameraPage(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
              ),
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final size = widget.size;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: AnimatedBuilder(
          animation: _pressCtrl,
          builder: (_, __) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: GestureDetector(
                onTapDown: (_) {
                  setState(() => _pressing = true);
                  _pressCtrl.forward();
                },
                onTapUp: (_) {
                  setState(() => _pressing = false);
                  _onTap();
                },
                onTapCancel: () {
                  setState(() => _pressing = false);
                  _pressCtrl.reverse();
                },
                child: Hero(
                  // tag: 'pin_button',
                  tag: 'camera',
                  child: Container(
                    height: size.height * 0.1,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.28 + _glowAnim.value * 0.18),
                          blurRadius: 20 + _glowAnim.value * 12,
                          offset: const Offset(0, 6),
                          spreadRadius: _glowAnim.value * 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Subtle inner highlight
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: size.height * 0.1 * 0.5,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.07),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: Row(
                              children: [
                                // Icon container
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.share_location_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pin Someone',
                                        style: theme.bodyMedium.copyWith(
                                          fontFamily: 'Plus Jakarta Sans',
                                          color: Colors.white,
                                          fontSize: 21,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      Text(
                                        'Request nearby help',
                                        style: theme.bodySmall.copyWith(
                                          color: Colors.white.withOpacity(0.65),
                                          fontSize: 14,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Arrow indicator
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  transform: Matrix4.translationValues(
                                    _pressing ? 4 : 0,
                                    0,
                                    0,
                                  ),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Keep the old function signature for backward compat
Widget pinSomeone(Size size, BuildContext context) {
  return PinSomeoneButton(size: size);
}
