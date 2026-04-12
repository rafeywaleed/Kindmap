import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kindmap/config/app_theme.dart';
import 'package:kindmap/models/pin_model.dart';
import 'package:kindmap/widgets/grid_info_skeleton.dart';
import 'package:latlong2/latlong.dart';

// First, create a separate widget for the grid info card to better manage state
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
    with SingleTickerProviderStateMixin {
  late bool _isListViewExpanded;
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  // For smooth drag tracking
  double _dragStartY = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _isListViewExpanded = false;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _heightAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isListViewExpanded = !_isListViewExpanded;
      if (_isListViewExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _dragStartY = details.localPosition.dy;
    _isDragging = true;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final delta = details.localPosition.dy - _dragStartY;

    if (delta < -60 && !_isListViewExpanded) {
      _isDragging = false;
      _toggleExpanded();
    } else if (delta > 60 && _isListViewExpanded) {
      _isDragging = false;
      _toggleExpanded();
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _isDragging = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        double maxCardWidth = (screenWidth * 0.4).clamp(200.0, 320.0);
        double maxHeight = screenHeight * 0.8;

        return ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: maxCardWidth, maxHeight: maxHeight),
          child: GestureDetector(
            onVerticalDragStart: _onVerticalDragStart,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: Material(
              elevation: 8,
              shadowColor: theme.primaryText.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.secondaryBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      padding: const EdgeInsets.only(top: 8),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return RotationTransition(
                            turns: animation,
                            child: child,
                          );
                        },
                        child: Icon(
                          _isListViewExpanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_up_rounded,
                          key: ValueKey(_isListViewExpanded),
                          size: 24,
                          color: theme.secondaryText,
                        ),
                      ),
                    ),

                    // Always visible header content
                    _buildHeaderContent(theme),

                    // Expandable list view with smooth animation
                    AnimatedBuilder(
                      animation: _heightAnimation,
                      builder: (context, child) {
                        return ClipRect(
                          child: Align(
                            heightFactor: _isListViewExpanded
                                ? _heightAnimation.value
                                : 0,
                            child: Column(
                              children: [
                                Divider(
                                  color: theme.lineColor,
                                  height: 1,
                                  thickness: 1,
                                ),
                                Container(
                                  constraints: BoxConstraints(
                                    maxHeight: _isListViewExpanded
                                        ? screenHeight * 0.45
                                        : 0,
                                  ),
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: widget.pinsInCurrentGridList.isEmpty
                                        ? _buildEmptyState(theme)
                                        : Column(
                                            children: widget
                                                .pinsInCurrentGridList
                                                .map((pin) => _buildPinListItem(
                                                    pin, theme))
                                                .toList(),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderContent(KMTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Grid ID with status dot
          Row(
            children: [
              Expanded(
                child: Text(
                  'Grid: ${widget.currentCellId.toString()}',
                  style: theme.titleSmall.copyWith(
                    color: theme.primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSubscribedToCurrentGrid
                      ? theme.success
                      : theme.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // People count
          Row(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 16,
                color: theme.secondaryText,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${widget.pinsInCurrentGrid} ${widget.pinsInCurrentGrid == 1 ? 'person needs' : 'people need'} help',
                  style: theme.labelMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider for visual separation
          Container(
            height: 1,
            color: theme.lineColor,
          ),
          const SizedBox(height: 16),

          // Action buttons
          Column(
            children: [
              // Subscribe/Unsubscribe button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onToggleSubscription,
                  icon: Icon(
                    widget.isSubscribedToCurrentGrid
                        ? Icons.notifications_off
                        : Icons.notifications_active,
                    size: 18,
                    color: theme.primaryBtnText,
                  ),
                  label: Text(
                    widget.isSubscribedToCurrentGrid
                        ? 'Unsubscribe'
                        : 'Subscribe',
                    style: theme.labelMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryBtnText,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isSubscribedToCurrentGrid
                        ? theme.error
                        : theme.success,
                    foregroundColor: theme.primaryBtnText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              // Toggle list button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _toggleExpanded,
                  icon: Icon(
                    _isListViewExpanded ? Icons.compress : Icons.list_alt,
                    size: 18,
                    color: theme.primaryText,
                  ),
                  label: Text(
                    _isListViewExpanded ? 'Hide List' : 'View List',
                    style: theme.labelMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primaryText,
                    side: BorderSide(
                      color: theme.lineColor,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(KMTheme theme) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 48,
              color: theme.secondaryText,
            ),
            const SizedBox(height: 12),
            Text(
              'No pins in this grid',
              style: theme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinListItem(Pin pin, KMTheme theme) {
    final distance = Geolocator.distanceBetween(
      pin.latitude,
      pin.longitude,
      widget.currentLocation?.latitude ?? 0,
      widget.currentLocation?.longitude ?? 0,
    ).round();

    return GestureDetector(
      onTap: () {
        widget.onMarkerTap(
          LatLng(pin.latitude, pin.longitude),
          pin,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildPinImage(pin, theme),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$distance m',
                      style: theme.bodyMedium.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pin.note ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pin.timer} hrs',
                      style: theme.bodyMedium.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: theme.error,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinImage(Pin pin, KMTheme theme) {
    final imageSize = MediaQuery.of(context).size.width * 0.15;

    if (pin.imageBase64 != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          base64Decode(pin.imageBase64!),
          fit: BoxFit.cover,
          width: imageSize,
          height: imageSize,
          errorBuilder: (context, error, stackTrace) => Container(
            width: imageSize,
            height: imageSize,
            color: theme.lineColor,
            child: const Icon(Icons.error),
          ),
        ),
      );
    } else {
      return Container(
        width: imageSize,
        height: imageSize,
        color: theme.lineColor,
        child: const Icon(Icons.image_not_supported),
      );
    }
  }
}
