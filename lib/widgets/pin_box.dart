import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_theme.dart';
import '../models/pin_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point: call this to show the pin sheet
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showPinBox({
  required BuildContext context,
  required Pin pin,
  required LatLng userLocation,
  required VoidCallback onServe,
}) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.65),
    barrierLabel: 'Pin details',
    enableDrag: true,
    transitionAnimationController: AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 480),
    ),
    builder: (_) => PinBox(
      pin: pin,
      location: userLocation,
      onServe: onServe,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PinBox widget
// ─────────────────────────────────────────────────────────────────────────────

class PinBox extends StatefulWidget {
  final Pin pin;
  final LatLng location;
  final VoidCallback onServe;

  const PinBox({
    super.key,
    required this.pin,
    required this.location,
    required this.onServe,
  });

  @override
  State<PinBox> createState() => _PinBoxState();
}

class _PinBoxState extends State<PinBox> with TickerProviderStateMixin {
  late final int _distance;
  bool _isServing = false;

  // Master entrance sequence
  late final AnimationController _entranceCtrl;
  late final AnimationController _imageCtrl;
  late final AnimationController _serveCtrl;

  // Entrance animations
  late final Animation<double> _sheetFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentFade;
  late final Animation<double> _imageScale;
  late final Animation<double> _imageFade;

  // Serve button ripple
  late final Animation<double> _servePulse;

  @override
  void initState() {
    super.initState();

    _distance = Geolocator.distanceBetween(
      widget.pin.latitude,
      widget.pin.longitude,
      widget.location.latitude,
      widget.location.longitude,
    ).round();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _imageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _serveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _sheetFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
    ));

    _contentFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.1, 0.65, curve: Curves.easeOut),
    );

    _imageScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _imageCtrl,
        curve: Curves.easeOutBack,
      ),
    );

    _imageFade = CurvedAnimation(
      parent: _imageCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _servePulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _serveCtrl,
        curve: Curves.easeInOut,
      ),
    );

    // Staggered start
    _entranceCtrl.forward();
    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) _imageCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _serveCtrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _imageCtrl.dispose();
    _serveCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _distanceLabel {
    if (_distance < 1000) return '$_distance m away';
    return '${(_distance / 1000).toStringAsFixed(1)} km away';
  }

  String get _timeLabel {
    final t = widget.pin.timer;
    if (t == null) return '';
    return '$t left';
  }

  Future<void> _navigateToLocation() async {
    HapticFeedback.lightImpact();
    final lat = widget.pin.latitude;
    final lng = widget.pin.longitude;
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar('Could not open maps', isError: true),
      );
    }
  }

  Future<void> _handleServe() async {
    if (_isServing) return;
    HapticFeedback.heavyImpact();
    setState(() => _isServing = true);
    // Let the button animate before calling
    await Future.delayed(const Duration(milliseconds: 180));
    widget.onServe();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final mq = MediaQuery.of(context);

    return FadeTransition(
      opacity: _sheetFade,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 32,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SlideTransition(
            position: _contentSlide,
            child: FadeTransition(
              opacity: _contentFade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Handle(theme: theme),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                          20, 4, 20, 20 + mq.viewInsets.bottom),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Image
                          _PinImage(
                            imageSource: widget.pin.imageBase64 ?? '',
                            scaleAnim: _imageScale,
                            fadeAnim: _imageFade,
                          ),

                          const SizedBox(height: 16),

                          // Distance + time chips
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _InfoChip(
                                icon: Icons.near_me_rounded,
                                label: _distanceLabel,
                                theme: theme,
                                colorSeed: Colors.blue,
                              ),
                              if (_timeLabel.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                _InfoChip(
                                  icon: Icons.schedule_rounded,
                                  label: _timeLabel,
                                  theme: theme,
                                  colorSeed: const Color(0xFF1D9E75),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Note & detail card
                          _NoteCard(
                            note: widget.pin.note ?? '',
                            detail: widget.pin.details ?? '',
                            theme: theme,
                          ),

                          const SizedBox(height: 20),

                          // Navigate button
                          _ActionButton(
                            label: 'Navigate',
                            icon: Icons.navigation_rounded,
                            onPressed: _navigateToLocation,
                            theme: theme,
                            style: _ButtonStyle.secondary,
                          ),

                          const SizedBox(height: 10),

                          // Serve button with pulse
                          AnimatedBuilder(
                            animation: _servePulse,
                            builder: (_, child) => Transform.scale(
                              scale: _isServing ? 1.0 : _servePulse.value,
                              child: child,
                            ),
                            child: _ActionButton(
                              label: _isServing
                                  ? 'Marking served…'
                                  : 'Mark as Served',
                              icon: _isServing
                                  ? null
                                  : Icons.volunteer_activism_rounded,
                              onPressed: _isServing ? null : _handleServe,
                              theme: theme,
                              style: _ButtonStyle.primary,
                              isLoading: _isServing,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Handle bar
// ─────────────────────────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  final KMTheme theme;
  const _Handle({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: theme.primaryText.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pin image
// ─────────────────────────────────────────────────────────────────────────────

class _PinImage extends StatelessWidget {
  final String imageSource;
  final Animation<double> scaleAnim;
  final Animation<double> fadeAnim;

  const _PinImage({
    required this.imageSource,
    required this.scaleAnim,
    required this.fadeAnim,
  });

  bool get _isUrl => imageSource.startsWith('http');
  bool get _isEmpty => imageSource.isEmpty;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.38;

    return ScaleTransition(
      scale: scaleAnim,
      child: FadeTransition(
        opacity: fadeAnim,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: _isEmpty
                ? _ImagePlaceholder(size: size)
                : _isUrl
                    ? CachedNetworkImage(
                        imageUrl: imageSource,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            _ImagePlaceholder(size: size, loading: true),
                        errorWidget: (_, __, ___) =>
                            _ImagePlaceholder(size: size),
                      )
                    : Image.memory(
                        base64Decode(imageSource),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) =>
                            _ImagePlaceholder(size: size),
                      ),
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final double size;
  final bool loading;
  const _ImagePlaceholder({required this.size, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    return Container(
      width: size,
      height: size,
      color: theme.primaryText.withOpacity(0.06),
      child: Center(
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.primary,
                ),
              )
            : Icon(
                Icons.image_not_supported_outlined,
                size: 28,
                color: theme.primaryText.withOpacity(0.25),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info chip (distance, time)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final KMTheme theme;
  final Color colorSeed;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.theme,
    required this.colorSeed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colorSeed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: colorSeed.withOpacity(0.18),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorSeed),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.bodySmall.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: colorSeed,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Note card
// ─────────────────────────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final String note;
  final String detail;
  final KMTheme theme;

  const _NoteCard({
    required this.note,
    required this.detail,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (note.isEmpty && detail.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryText.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.primaryText.withOpacity(0.07),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.isNotEmpty) ...[
            _NoteRow(
              icon: Icons.sticky_note_2_outlined,
              title: 'Note',
              value: note,
              theme: theme,
            ),
          ],
          if (note.isNotEmpty && detail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                height: 1,
                color: theme.primaryText.withOpacity(0.07),
              ),
            ),
          if (detail.isNotEmpty) ...[
            _NoteRow(
              icon: Icons.place_outlined,
              title: 'Location detail',
              value: detail,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final KMTheme theme;

  const _NoteRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: theme.primaryText.withOpacity(0.35)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.bodySmall.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: theme.primaryText.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.bodyMedium.copyWith(
                  fontSize: 14,
                  height: 1.45,
                  color: theme.primaryText.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action buttons
// ─────────────────────────────────────────────────────────────────────────────

enum _ButtonStyle { primary, secondary }

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final KMTheme theme;
  final _ButtonStyle style;
  final bool isLoading;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.theme,
    required this.style,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;
  late Animation<double> _pressOpacity;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
    _pressOpacity = Tween<double>(begin: 1.0, end: 0.75).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  bool get _isPrimary => widget.style == _ButtonStyle.primary;

  Color get _bgColor => _isPrimary
      ? widget.theme.primary
      : widget.theme.primaryText.withOpacity(0.06);

  Color get _textColor =>
      _isPrimary ? widget.theme.primaryBtnText : widget.theme.primaryText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => _pressCtrl.forward(),
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              _pressCtrl.reverse();
              widget.onPressed!();
            },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (_, child) => Transform.scale(
          scale: _pressScale.value,
          child: Opacity(
            opacity: _pressOpacity.value,
            child: child,
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(16),
            border: _isPrimary
                ? null
                : Border.all(
                    color: widget.theme.primaryText.withOpacity(0.1),
                    width: 1,
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 10),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: _textColor),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: widget.theme.bodyMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: _isPrimary ? 0.2 : 0,
                  color: _textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Snackbar helper
// ─────────────────────────────────────────────────────────────────────────────

SnackBar _buildSnackBar(String message, {bool isError = false}) {
  return SnackBar(
    content: Row(children: [
      Icon(
        isError
            ? Icons.error_outline_rounded
            : Icons.check_circle_outline_rounded,
        color: Colors.white,
        size: 18,
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
    ]),
    backgroundColor:
        isError ? const Color(0xFFA32D2D) : const Color(0xFF0F6E56),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    margin: const EdgeInsets.all(12),
    duration: const Duration(seconds: 3),
  );
}
