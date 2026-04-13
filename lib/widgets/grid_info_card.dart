import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kindmap/config/app_theme.dart';
import 'package:kindmap/models/pin_model.dart';
import 'package:latlong2/latlong.dart';

class GridInfoCard extends StatefulWidget {
  final String? currentCellId;
  final bool isSubscribedToCurrentGrid;
  final int pinsInCurrentGrid;
  final List<Pin> pinsInCurrentGridList;
  final VoidCallback onToggleSubscription;
  final Function(LatLng, Pin) onMarkerTap;
  final LatLng? currentLocation;

  const GridInfoCard({
    super.key,
    required this.currentCellId,
    required this.isSubscribedToCurrentGrid,
    required this.pinsInCurrentGrid,
    required this.pinsInCurrentGridList,
    required this.onToggleSubscription,
    required this.onMarkerTap,
    required this.currentLocation,
  });

  @override
  State<GridInfoCard> createState() => _GridInfoCardState();
}

class _GridInfoCardState extends State<GridInfoCard>
    with TickerProviderStateMixin {
  // Expand/collapse
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  // Card entrance
  late AnimationController _entranceCtrl;
  late Animation<Offset> _entranceSlide;
  late Animation<double> _entranceFade;

  // Subscribe button press
  late AnimationController _subBtnCtrl;
  late Animation<double> _subBtnScale;

  // Pin count badge pulse
  late AnimationController _badgeCtrl;
  late Animation<double> _badgePulse;

  bool _isListViewExpanded = false;
  double _dragStartY = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    _expandCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _expandAnim =
        CurvedAnimation(parent: _expandCtrl, curve: Curves.easeInOutCubic);

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _entranceSlide = Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));
    _entranceFade =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);

    _subBtnCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 130),
        reverseDuration: const Duration(milliseconds: 250));
    _subBtnScale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _subBtnCtrl, curve: Curves.easeOut));

    _badgeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _badgePulse = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeInOut));

    _entranceCtrl.forward();
  }

  @override
  void didUpdateWidget(GridInfoCard old) {
    super.didUpdateWidget(old);
    // Re-animate entrance if cell changed
    if (old.currentCellId != widget.currentCellId) {
      _entranceCtrl.forward(from: 0);
      if (_isListViewExpanded) {
        setState(() => _isListViewExpanded = false);
        _expandCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    _entranceCtrl.dispose();
    _subBtnCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    setState(() => _isListViewExpanded = !_isListViewExpanded);
    if (_isListViewExpanded) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  void _onVerticalDragStart(DragStartDetails d) {
    _dragStartY = d.localPosition.dy;
    _isDragging = true;
  }

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    if (!_isDragging) return;
    final delta = d.localPosition.dy - _dragStartY;
    if (delta < -60 && !_isListViewExpanded) {
      _isDragging = false;
      _toggleExpanded();
    } else if (delta > 60 && _isListViewExpanded) {
      _isDragging = false;
      _toggleExpanded();
    }
  }

  void _onVerticalDragEnd(DragEndDetails _) => _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final double cardW = (screenW * 0.42).clamp(200.0, 300.0);

    return SlideTransition(
      position: _entranceSlide,
      child: FadeTransition(
        opacity: _entranceFade,
        child: GestureDetector(
          onVerticalDragStart: _onVerticalDragStart,
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: cardW, maxHeight: screenH * 0.8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: theme.primaryText.withOpacity(0.07),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: theme.primary.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Drag handle ─────────────────────────────
                    _DragHandle(
                      isExpanded: _isListViewExpanded,
                      theme: theme,
                      onTap: _toggleExpanded,
                    ),

                    // ── Header ──────────────────────────────────
                    _CardHeader(
                      cellId: widget.currentCellId,
                      isSubscribed: widget.isSubscribedToCurrentGrid,
                      pinCount: widget.pinsInCurrentGrid,
                      badgePulse: _badgePulse,
                      theme: theme,
                    ),

                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            theme.primary.withOpacity(0.3),
                            theme.primaryText.withOpacity(0.04),
                          ]),
                        ),
                      ),
                    ),

                    // ── Action buttons ──────────────────────────
                    _CardActions(
                      isSubscribed: widget.isSubscribedToCurrentGrid,
                      isExpanded: _isListViewExpanded,
                      theme: theme,
                      subBtnCtrl: _subBtnCtrl,
                      subBtnScale: _subBtnScale,
                      onToggleSubscription: widget.onToggleSubscription,
                      onToggleList: _toggleExpanded,
                    ),

                    // ── Expandable list ──────────────────────────
                    AnimatedBuilder(
                      animation: _expandAnim,
                      builder: (_, __) => ClipRect(
                        child: Align(
                          heightFactor: _expandAnim.value,
                          child: Column(children: [
                            Container(
                              height: 1,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  theme.primaryText.withOpacity(0.04),
                                  theme.primary.withOpacity(0.2),
                                ]),
                              ),
                            ),
                            ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxHeight: screenH * 0.42),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(10, 8, 10, 16),
                                child: widget.pinsInCurrentGridList.isEmpty
                                    ? _EmptyState(theme: theme)
                                    : Column(
                                        children: widget.pinsInCurrentGridList
                                            .asMap()
                                            .entries
                                            .map((e) => _PinListTile(
                                                  pin: e.value,
                                                  index: e.key,
                                                  theme: theme,
                                                  currentLocation:
                                                      widget.currentLocation,
                                                  onTap: () {
                                                    widget.onMarkerTap(
                                                      LatLng(e.value.latitude,
                                                          e.value.longitude),
                                                      e.value,
                                                    );
                                                  },
                                                ))
                                            .toList(),
                                      ),
                              ),
                            ),
                          ]),
                        ),
                      ),
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

// ═══════════════════════════════════════════════════════════════
// DRAG HANDLE
// ═══════════════════════════════════════════════════════════════

class _DragHandle extends StatelessWidget {
  final bool isExpanded;
  final KMTheme theme;
  final VoidCallback onTap;

  const _DragHandle({
    required this.isExpanded,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Column(children: [
          // Physical handle bar
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: theme.primaryText.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          // Animated chevron
          AnimatedRotation(
            turns: isExpanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 18,
              color: theme.secondaryText.withOpacity(0.6),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CARD HEADER
// ═══════════════════════════════════════════════════════════════

class _CardHeader extends StatelessWidget {
  final String? cellId;
  final bool isSubscribed;
  final int pinCount;
  final Animation<double> badgePulse;
  final KMTheme theme;

  const _CardHeader({
    required this.cellId,
    required this.isSubscribed,
    required this.pinCount,
    required this.badgePulse,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Grid ID row
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.grid_4x4_rounded, size: 14, color: theme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cellId ?? '—',
              style: theme.titleSmall.copyWith(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Status dot with animated glow
          AnimatedBuilder(
            animation: badgePulse,
            builder: (_, __) => Transform.scale(
              scale: isSubscribed ? badgePulse.value : 1.0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSubscribed
                      ? theme.success
                      : theme.secondaryText.withOpacity(0.4),
                  boxShadow: isSubscribed
                      ? [
                          BoxShadow(
                            color: theme.success.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                ),
              ),
            ),
          ),
        ]),

        const SizedBox(height: 12),

        // Pin count chip
        Row(children: [
          _PinCountChip(count: pinCount, theme: theme),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              pinCount == 1 ? 'person needs help' : 'people need help',
              style: theme.labelSmall.copyWith(
                fontSize: 12,
                color: theme.secondaryText,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PIN COUNT CHIP
// ═══════════════════════════════════════════════════════════════

class _PinCountChip extends StatelessWidget {
  final int count;
  final KMTheme theme;

  const _PinCountChip({required this.count, required this.theme});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: count > 0
            ? theme.error.withOpacity(0.12)
            : theme.secondaryText.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: count > 0
              ? theme.error.withOpacity(0.25)
              : theme.secondaryText.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => ScaleTransition(
          scale: anim,
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Text(
          '$count',
          key: ValueKey(count),
          style: theme.labelMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: count > 0 ? theme.error : theme.secondaryText,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CARD ACTIONS
// ═══════════════════════════════════════════════════════════════

class _CardActions extends StatelessWidget {
  final bool isSubscribed;
  final bool isExpanded;
  final KMTheme theme;
  final AnimationController subBtnCtrl;
  final Animation<double> subBtnScale;
  final VoidCallback onToggleSubscription;
  final VoidCallback onToggleList;

  const _CardActions({
    required this.isSubscribed,
    required this.isExpanded,
    required this.theme,
    required this.subBtnCtrl,
    required this.subBtnScale,
    required this.onToggleSubscription,
    required this.onToggleList,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(children: [
        // Subscribe button
        GestureDetector(
          onTapDown: (_) => subBtnCtrl.forward(),
          onTapUp: (_) {
            subBtnCtrl.reverse();
            HapticFeedback.lightImpact();
            onToggleSubscription();
          },
          onTapCancel: () => subBtnCtrl.reverse(),
          child: AnimatedBuilder(
            animation: subBtnScale,
            builder: (_, __) => Transform.scale(
              scale: subBtnScale.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSubscribed
                      ? theme.error.withOpacity(0.1)
                      : theme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isSubscribed
                        ? theme.error.withOpacity(0.3)
                        : theme.success.withOpacity(0.3),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, anim) => RotationTransition(
                        turns: Tween(begin: 0.0, end: 1.0).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Icon(
                        isSubscribed
                            ? Icons.notifications_off_outlined
                            : Icons.notifications_active_outlined,
                        key: ValueKey(isSubscribed),
                        size: 16,
                        color: isSubscribed ? theme.error : theme.success,
                      ),
                    ),
                    const SizedBox(width: 7),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        isSubscribed ? 'Unsubscribe' : 'Subscribe',
                        key: ValueKey(isSubscribed),
                        style: theme.labelMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSubscribed ? theme.error : theme.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 7),

        // View list button
        GestureDetector(
          onTap: onToggleList,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isExpanded
                  ? theme.primaryText.withOpacity(0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: theme.primaryText.withOpacity(0.1),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: Icon(
                    Icons.list_alt_rounded,
                    size: 16,
                    color: theme.primaryText.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  isExpanded ? 'Hide List' : 'View List',
                  style: theme.labelMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PIN LIST TILE
// ═══════════════════════════════════════════════════════════════

class _PinListTile extends StatefulWidget {
  final Pin pin;
  final int index;
  final KMTheme theme;
  final LatLng? currentLocation;
  final VoidCallback onTap;

  const _PinListTile({
    required this.pin,
    required this.index,
    required this.theme,
    required this.currentLocation,
    required this.onTap,
  });

  @override
  State<_PinListTile> createState() => _PinListTileState();
}

class _PinListTileState extends State<_PinListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _enterCtrl;
  late Animation<double> _enterFade;
  late Animation<Offset> _enterSlide;
  bool _pressing = false;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _enterFade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));

    // Staggered entry
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _enterCtrl.forward();
    });
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final pin = widget.pin;
    final imageSize = MediaQuery.of(context).size.width * 0.13;

    final distance = (widget.currentLocation != null)
        ? Geolocator.distanceBetween(
                pin.latitude,
                pin.longitude,
                widget.currentLocation!.latitude,
                widget.currentLocation!.longitude)
            .round()
        : null;

    return FadeTransition(
      opacity: _enterFade,
      child: SlideTransition(
        position: _enterSlide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressing = true),
          onTapUp: (_) {
            setState(() => _pressing = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressing = false),
          child: AnimatedScale(
            scale: _pressing ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primaryBackground.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.primaryText.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: Row(children: [
                // Image / placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: pin.imageBase64 != null
                      ? Image.memory(
                          base64Decode(pin.imageBase64!),
                          fit: BoxFit.cover,
                          width: imageSize,
                          height: imageSize,
                          errorBuilder: (_, __, ___) =>
                              _ImagePlaceholder(size: imageSize, theme: theme),
                        )
                      : _ImagePlaceholder(size: imageSize, theme: theme),
                ),

                const SizedBox(width: 10),

                // Text info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (distance != null)
                        Row(children: [
                          Icon(Icons.near_me_outlined,
                              size: 11, color: theme.primary.withOpacity(0.8)),
                          const SizedBox(width: 3),
                          Text(
                            '${distance}m away',
                            style: theme.labelSmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: theme.primary.withOpacity(0.8),
                            ),
                          ),
                        ]),
                      if (distance != null) const SizedBox(height: 3),
                      Text(
                        pin.note ?? 'No note',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.primaryText.withOpacity(0.85),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.timer_outlined,
                            size: 11, color: theme.error.withOpacity(0.8)),
                        const SizedBox(width: 3),
                        Text(
                          '${pin.timer} hrs',
                          style: theme.labelSmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.error.withOpacity(0.8),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),

                // Tap chevron
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: theme.secondaryText.withOpacity(0.4),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// IMAGE PLACEHOLDER
// ═══════════════════════════════════════════════════════════════

class _ImagePlaceholder extends StatelessWidget {
  final double size;
  final KMTheme theme;

  const _ImagePlaceholder({required this.size, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.primaryText.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.image_outlined,
        size: size * 0.45,
        color: theme.secondaryText.withOpacity(0.4),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final KMTheme theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.location_off_outlined,
              size: 36, color: theme.secondaryText.withOpacity(0.4)),
          const SizedBox(height: 10),
          Text(
            'No pins in this area',
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText.withOpacity(0.6),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ]),
      ),
    );
  }
}
