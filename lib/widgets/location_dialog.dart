import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Show the "location services disabled" dialog
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

/// Show the "location permission denied" dialog
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

/// Show the "notification permission" dialog
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

// ─────────────────────────────────────────────────────────────────────────────
// Internal dialog type enum
// ─────────────────────────────────────────────────────────────────────────────

enum _LocationDialogType {
  serviceDisabled,
  permissionDenied,
  notificationPermission,
  cameraPermission,
}

// ─────────────────────────────────────────────────────────────────────────────
// Core dialog widget
// ─────────────────────────────────────────────────────────────────────────────

class _LocationDialog extends StatefulWidget {
  final _LocationDialogType type;
  final VoidCallback? onSkip;

  const _LocationDialog({
    required this.type,
    this.onSkip,
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

  // ── Content per dialog type ────────────────────────────────────────────────

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
            Navigator.pop(context);
            await Geolocator.openLocationSettings();
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
          primaryLabel: 'Open settings',
          secondaryLabel: 'Continue without',
          onPrimary: () async {
            Navigator.pop(context);
            await openAppSettings();
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
          primaryLabel: 'Allow notifications',
          secondaryLabel: 'Maybe later',
          onPrimary: () async {
            Navigator.pop(context);
            await openAppSettings();
          },
        );

      case _LocationDialogType.cameraPermission:
        return _DialogContent(
          icon: Icons.camera_alt_outlined,
          iconColor:
              const Color(0xFF2E7D32), // Deep green – adjust to your brand
          iconBg: const Color(0xFFE8F5E9),
          title: 'Camera access needed',
          subtitle:
              'Allow camera access so you can take a photo and pin someone on the map.',
          primaryLabel: 'Open settings',
          secondaryLabel: 'Not now',
          onPrimary: () async {
            Navigator.pop(context);
            await openAppSettings();
          },
          onSecondary: () {
            Navigator.pop(context);
            widget.onSkip?.call();
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final content = _content;

    return Dialog(
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
                    // Animated icon with pulse rings
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

                    // Title
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

                    // Subtitle
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

                    // Primary button
                    _DialogButton(
                      label: content.primaryLabel,
                      color: content.iconColor,
                      theme: theme,
                      onPressed: content.onPrimary,
                      isPrimary: true,
                    ),

                    const SizedBox(height: 8),

                    // Secondary button
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
          // Outer pulse ring
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

          // Inner pulse ring (offset phase)
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

          // Icon sphere
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
