import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Settings helpers
// ─────────────────────────────────────────────────────────────────────────────

void _showWebPermissionHint(ScaffoldMessengerState? messenger) {
  messenger?.showSnackBar(
    const SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
        'On the web, manage this from your browser\'s site settings — tap '
        'the lock or info icon next to the address bar.',
      ),
    ),
  );
}

Future<void> _openLocationSettings(ScaffoldMessengerState? messenger) async {
  if (kIsWeb) {
    _showWebPermissionHint(messenger);
    return;
  }
  try {
    await Geolocator.openLocationSettings();
  } catch (_) {}
}

Future<void> _openAppSettings(ScaffoldMessengerState? messenger) async {
  if (kIsWeb) {
    _showWebPermissionHint(messenger);
    return;
  }
  try {
    await openAppSettings();
  } catch (_) {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showLocationServiceDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (_) => const _LocationDialog(
      type: _LocationDialogType.serviceDisabled,
    ),
  );
}

Future<void> showLocationPermissionDialog(
  BuildContext context, {
  VoidCallback? onSkip,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (_) => _LocationDialog(
      type: _LocationDialogType.permissionDenied,
      onSkip: onSkip,
    ),
  );
}

Future<void> showNotificationPermissionDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (_) => const _LocationDialog(
      type: _LocationDialogType.notificationPermission,
    ),
  );
}

Future<void> showCameraPermissionDialog(
  BuildContext context, {
  VoidCallback? onSkip,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (_) => _LocationDialog(
      type: _LocationDialogType.cameraPermission,
      onSkip: onSkip,
    ),
  );
}

/// Internet connection lost dialog.
/// Provide an optional [onTryAgain] callback.
Future<void> showNoInternetDialog(
  BuildContext context, {
  VoidCallback? onTryAgain,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (_) => _LocationDialog(
      type: _LocationDialogType.internetOffline,
      onTryAgain: onTryAgain,
    ),
  );
}

void showWebExperienceSnackBar(BuildContext context) {
  if (!context.mounted) return;
  final theme = KMTheme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
      backgroundColor: theme.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.primaryText.withOpacity(0.08)),
      ),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: theme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'On web, location accuracy and camera speed depend on your '
              'browser. For the smoothest experience, try the KindMap '
              'mobile app.',
              style: theme.bodyMedium.copyWith(
                color: theme.primaryText,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void showNoInternetSnackBar(BuildContext context) {
  if (!context.mounted) return;
  final theme = KMTheme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: theme.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.primaryText.withOpacity(0.08)),
      ),
      content: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: theme.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No internet connection. Some features may not work.',
              style: theme.bodyMedium.copyWith(
                color: theme.primaryText,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal dialog type enum
// ─────────────────────────────────────────────────────────────────────────────

enum _LocationDialogType {
  serviceDisabled,
  permissionDenied,
  notificationPermission,
  cameraPermission,
  internetOffline, // <-- NEW
}

// ─────────────────────────────────────────────────────────────────────────────
// Core dialog widget
// ─────────────────────────────────────────────────────────────────────────────

class _LocationDialog extends StatefulWidget {
  final _LocationDialogType type;
  final VoidCallback? onSkip;
  final VoidCallback? onTryAgain; // used by internetOffline

  const _LocationDialog({
    required this.type,
    this.onSkip,
    this.onTryAgain,
  });

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _iconCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double> _dialogScale;
  late final Animation<double> _dialogFade;
  late final Animation<Offset> _dialogSlide;
  late final Animation<double> _iconBounce;
  late final Animation<double> _pulseRing;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _dialogScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: Curves.easeOutBack,
      ),
    );

    _dialogFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _dialogSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOutCubic,
    ));

    _iconBounce = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconCtrl,
        curve: Curves.elasticOut,
      ),
    );

    _pulseRing = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    _pulseOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    _entranceCtrl.forward();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _iconCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _iconCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  _DialogContent get _content {
    switch (widget.type) {
      case _LocationDialogType.serviceDisabled:
        return _DialogContent(
          icon: Icons.location_off_rounded,
          iconColor: const Color(0xFFA32D2D),
          iconBg: const Color(0xFFFCEBEB),
          title: 'Location services off',
          subtitle:
              'Enable location services to see your position and nearby help requests on the map.',
          primaryLabel: 'Enable location',
          secondaryLabel: 'Not now',
          onPrimary: () async {
            final messenger = ScaffoldMessenger.maybeOf(context);
            Navigator.pop(context);
            await _openLocationSettings(messenger);
          },
        );

      case _LocationDialogType.permissionDenied:
        return _DialogContent(
          icon: Icons.lock_outline_rounded,
          iconColor: const Color(0xFFBA7517),
          iconBg: const Color(0xFFFAEEDA),
          title: 'Permission required',
          subtitle:
              'Grant location access so KindMap can show nearby help requests and guide you to them.',
          primaryLabel: kIsWeb ? 'How to allow' : 'Open settings',
          secondaryLabel: 'Continue without',
          onPrimary: () async {
            final messenger = ScaffoldMessenger.maybeOf(context);
            Navigator.pop(context);
            await _openAppSettings(messenger);
          },
          onSecondary: () {
            Navigator.pop(context);
            widget.onSkip?.call();
          },
        );

      case _LocationDialogType.notificationPermission:
        return _DialogContent(
          icon: Icons.notifications_outlined,
          iconColor: const Color(0xFF185FA5),
          iconBg: const Color(0xFFE6F1FB),
          title: 'Stay in the loop',
          subtitle:
              'Allow notifications to get alerted when new help requests appear near you.',
          primaryLabel: kIsWeb ? 'How to allow' : 'Allow notifications',
          secondaryLabel: 'Maybe later',
          onPrimary: () async {
            final messenger = ScaffoldMessenger.maybeOf(context);
            Navigator.pop(context);
            await _openAppSettings(messenger);
          },
        );

      case _LocationDialogType.cameraPermission:
        return _DialogContent(
          icon: Icons.camera_alt_outlined,
          iconColor: const Color(0xFF2E7D32),
          iconBg: const Color(0xFFE8F5E9),
          title: 'Camera access needed',
          subtitle:
              'Allow camera access so you can take a photo and pin someone on the map.',
          primaryLabel: kIsWeb ? 'How to allow' : 'Open settings',
          secondaryLabel: 'Not now',
          onPrimary: () async {
            final messenger = ScaffoldMessenger.maybeOf(context);
            Navigator.pop(context);
            await _openAppSettings(messenger);
          },
          onSecondary: () {
            Navigator.pop(context);
            widget.onSkip?.call();
          },
        );

      case _LocationDialogType.internetOffline:
        return _DialogContent(
          icon: Icons.wifi_off_rounded,
          iconColor: const Color(0xFFD32F2F),
          iconBg: const Color(0xFFFFEBEE),
          title: 'No Internet Connection',
          subtitle: 'Please check your Wi-Fi or mobile data and try again.',
          primaryLabel: 'Try Again',
          secondaryLabel: 'Dismiss',
          onPrimary: () {
            Navigator.pop(context);
            widget.onTryAgain?.call();
          },
          onSecondary: () => Navigator.pop(context),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final content = _content;

    return ClipRRect(
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: FadeTransition(
          opacity: _dialogFade,
          child: SlideTransition(
            position: _dialogSlide,
            child: ScaleTransition(
              scale: _dialogScale,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.secondaryBackground,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AnimatedIcon(
                        iconCtrl: _iconCtrl,
                        pulseCtrl: _pulseCtrl,
                        iconBounce: _iconBounce,
                        pulseRing: _pulseRing,
                        pulseOpacity: _pulseOpacity,
                        icon: content.icon,
                        iconColor: content.iconColor,
                        iconBg: content.iconBg,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        content.title,
                        textAlign: TextAlign.center,
                        style: theme.titleLarge.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        content.subtitle,
                        textAlign: TextAlign.center,
                        style: theme.bodyMedium.copyWith(
                          fontSize: 13.5,
                          height: 1.55,
                          color: theme.primaryText.withOpacity(0.52),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _DialogButton(
                        label: content.primaryLabel,
                        color: content.iconColor,
                        theme: theme,
                        onPressed: content.onPrimary,
                        isPrimary: true,
                      ),
                      const SizedBox(height: 8),
                      _DialogButton(
                        label: content.secondaryLabel,
                        color: content.iconColor,
                        theme: theme,
                        onPressed:
                            content.onSecondary ?? () => Navigator.pop(context),
                        isPrimary: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated icon with orbiting pulse rings
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedIcon extends StatelessWidget {
  final AnimationController iconCtrl;
  final AnimationController pulseCtrl;
  final Animation<double> iconBounce;
  final Animation<double> pulseRing;
  final Animation<double> pulseOpacity;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _AnimatedIcon({
    required this.iconCtrl,
    required this.pulseCtrl,
    required this.iconBounce,
    required this.pulseRing,
    required this.pulseOpacity,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, __) => Opacity(
              opacity: pulseOpacity.value,
              child: Transform.scale(
                scale: pulseRing.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, __) {
              final phase = (pulseCtrl.value + 0.4) % 1.0;
              final scale = 0.6 + phase * 0.4;
              final opacity = (1.0 - phase) * 0.4;
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor.withOpacity(0.12),
                    ),
                  ),
                ),
              );
            },
          ),
          ScaleTransition(
            scale: iconBounce,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog button
// ─────────────────────────────────────────────────────────────────────────────

class _DialogButton extends StatefulWidget {
  final String label;
  final Color color;
  final KMTheme theme;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _DialogButton({
    required this.label,
    required this.color,
    required this.theme,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return GestureDetector(
      onTapDown: (_) {
        _pressCtrl.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? widget.color
                : theme.primaryText.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: theme.primaryText.withOpacity(0.08),
                    width: 1,
                  ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: theme.bodyMedium.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: widget.isPrimary
                  ? Colors.white
                  : theme.primaryText.withOpacity(0.65),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content model
// ─────────────────────────────────────────────────────────────────────────────

class _DialogContent {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;

  const _DialogContent({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    this.onSecondary,
  });
}
