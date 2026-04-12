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
  bool _isListViewExpanded = false;
  late AnimationController _expandAnimationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandAnimationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _expandAnimationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isListViewExpanded = !_isListViewExpanded;
      if (_isListViewExpanded) {
        _expandAnimationController.forward();
      } else {
        _expandAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        double maxCardWidth =
            (MediaQuery.of(context).size.width * 0.4).clamp(200.0, 320.0);

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCardWidth),
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! > 0 && !_isListViewExpanded) {
                  _toggleExpanded();
                } else if (details.primaryVelocity! < 0 &&
                    _isListViewExpanded) {
                  _toggleExpanded();
                }
              }
            },
            child: AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return Container(
                  height: _isListViewExpanded ? screenHeight * 0.8 : null,
                  constraints: BoxConstraints(
                    minHeight: _isListViewExpanded ? screenHeight * 0.8 : 0,
                  ),
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
                          // Drag handle / header section
                          _buildDragHandle(theme),

                          // Always visible header content
                          _buildHeaderContent(theme),

                          // Expandable list view (only shown when expanded)
                          if (_isListViewExpanded)
                            _buildExpandableContent(theme, screenHeight),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragHandle(KMTheme theme) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      child: Icon(
        _isListViewExpanded
            ? Icons.keyboard_arrow_down_rounded
            : Icons.keyboard_arrow_up_rounded,
        size: 24,
        color: theme.secondaryText,
      ),
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
                  'Grid ${widget.currentCellId.toString()}',
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

  Widget _buildExpandableContent(KMTheme theme, double screenHeight) {
    return Expanded(
      child: Column(
        children: [
          Divider(
            color: theme.lineColor,
            height: 1,
            thickness: 1,
          ),
          Expanded(
            child: widget.pinsInCurrentGridList.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    itemCount: widget.pinsInCurrentGridList.length,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemBuilder: (context, index) {
                      final pin = widget.pinsInCurrentGridList[index];
                      return _buildPinListItem(pin, theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(KMTheme theme) {
    return Center(
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

// Skeleton loader widget for grid content
class GridInfoCardSkeleton extends StatelessWidget {
  const GridInfoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        double maxCardWidth =
            (MediaQuery.of(context).size.width * 0.4).clamp(200.0, 320.0);

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCardWidth),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryText.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skeleton for drag handle
                Container(
                  width: 40,
                  height: 24,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.lineColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Skeleton for header row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 22,
                        decoration: BoxDecoration(
                          color: theme.lineColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Skeleton for people count
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.lineColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.lineColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Skeleton for divider
                Container(
                  height: 1,
                  color: theme.lineColor,
                ),
                const SizedBox(height: 16),
                // Skeleton for buttons
                Column(
                  children: [
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.lineColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.lineColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// class GridInfoPanel extends StatefulWidget {
//   final String? currentCellId;
//   final bool isSubscribedToCurrentGrid;
//   final int pinsInCurrentGrid;
//   final List<Pin> pinsInCurrentGridList;
//   final bool isLoading;
//   final LatLng? currentLocation;
//   final VoidCallback onSubscribeToggle;
//   final Function(LatLng, Pin) onMarkerTap;

//   const GridInfoPanel({
//     required this.currentCellId,
//     required this.isSubscribedToCurrentGrid,
//     required this.pinsInCurrentGrid,
//     required this.pinsInCurrentGridList,
//     required this.isLoading,
//     required this.currentLocation,
//     required this.onSubscribeToggle,
//     required this.onMarkerTap,
//   });

//   @override
//   State<GridInfoPanel> createState() => _GridInfoPanelState();
// }

// class _GridInfoPanelState extends State<GridInfoPanel>
//     with SingleTickerProviderStateMixin {
//   bool _isExpanded = false;
//   late DraggableScrollableController _draggableController;

//   @override
//   void initState() {
//     super.initState();
//     _draggableController = DraggableScrollableController();
//     _draggableController.addListener(_onDragUpdate);
//   }

//   @override
//   void dispose() {
//     _draggableController.removeListener(_onDragUpdate);
//     _draggableController.dispose();
//     super.dispose();
//   }

//   void _onDragUpdate() {
//     if (_draggableController.isAttached && mounted) {
//       final size = _draggableController.size;
//       final shouldBeExpanded = size > 0.4;
//       if (shouldBeExpanded != _isExpanded) {
//         setState(() {
//           _isExpanded = shouldBeExpanded;
//         });
//       }
//     }
//   }

//   void _toggleExpansion() async {
//     if (_draggableController.isAttached) {
//       final targetSize = _isExpanded ? 0.15 : 0.7;
//       await _draggableController.animateTo(
//         targetSize,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOutCubic,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final maxCardWidth = (screenWidth * 0.4).clamp(200.0, 320.0);
//     final theme = KMTheme.of(context);

//     return SizedBox(
//       width: maxCardWidth,
//       height: MediaQuery.of(context).size.height * 0.8,
//       child: DraggableScrollableSheet(
//         controller: _draggableController,
//         initialChildSize: 0.15,
//         minChildSize: 0.12,
//         maxChildSize: 0.8,
//         snap: true,
//         snapSizes: const [0.15, 0.5, 0.7],
//         builder: (context, scrollController) {
//           return Container(
//             decoration: BoxDecoration(
//               color: theme.secondaryBackground,
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(20),
//                 topRight: Radius.circular(20),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.15),
//                   blurRadius: 12,
//                   offset: const Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 // Drag handle
//                 GestureDetector(
//                   onTap: _toggleExpansion,
//                   child: Container(
//                     margin: const EdgeInsets.only(top: 12),
//                     width: 40,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: theme.secondaryText.withOpacity(0.4),
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: SingleChildScrollView(
//                     controller: scrollController,
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // Header Section (always visible)
//                         _buildHeaderSection(theme),
//                         const SizedBox(height: 16),

//                         // Divider
//                         _buildDivider(theme),
//                         const SizedBox(height: 16),

//                         // Action Buttons
//                         _buildActionButtons(theme),

//                         // Pin List (only when expanded)
//                         if (_isExpanded) ...[
//                           const SizedBox(height: 16),
//                           _buildDivider(theme),
//                           const SizedBox(height: 16),
//                           _buildPinListSection(theme),
//                         ],
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildHeaderSection(KMTheme theme) {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Grid ID with status dot
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   'Grid ${widget.currentCellId ?? 'Unknown'}',
//                   style: theme.titleSmall.copyWith(
//                     color: theme.primaryText,
//                     fontSize: 17,
//                     fontWeight: FontWeight.w600,
//                     letterSpacing: -0.3,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               Container(
//                 width: 8,
//                 height: 8,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: widget.isSubscribedToCurrentGrid
//                       ? theme.success
//                       : theme.secondaryText,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 14),

//           // People count with shimmer effect
//           Row(
//             children: [
//               Icon(
//                 Icons.people_outline_rounded,
//                 size: 16,
//                 color: theme.secondaryText,
//               ),
//               const SizedBox(width: 6),
//               Flexible(
//                 child: widget.isLoading
//                     ? ShimmerSkeleton(
//                         width: 120,
//                         height: 16,
//                         borderRadius: BorderRadius.circular(4),
//                       )
//                     : Text(
//                         '${widget.pinsInCurrentGrid} ${widget.pinsInCurrentGrid == 1 ? 'person needs' : 'people need'} help',
//                         style: theme.labelMedium.copyWith(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w500,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDivider(KMTheme theme) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       height: 1,
//       color: theme.lineColor,
//     );
//   }

//   Widget _buildActionButtons(KMTheme theme) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         children: [
//           // Subscribe/Unsubscribe button
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton.icon(
//               onPressed: widget.onSubscribeToggle,
//               icon: Icon(
//                 widget.isSubscribedToCurrentGrid
//                     ? Icons.notifications_off
//                     : Icons.notifications_active,
//                 size: 18,
//                 color: theme.primaryBtnText,
//               ),
//               label: Text(
//                 widget.isSubscribedToCurrentGrid ? 'Unsubscribe' : 'Subscribe',
//                 style: theme.labelMedium.copyWith(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: theme.primaryBtnText,
//                 ),
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: widget.isSubscribedToCurrentGrid
//                     ? theme.error
//                     : theme.success,
//                 foregroundColor: theme.primaryBtnText,
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 padding: const EdgeInsets.symmetric(vertical: 10),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),

//           // Expand/Collapse button
//           SizedBox(
//             width: double.infinity,
//             child: OutlinedButton.icon(
//               onPressed: _toggleExpansion,
//               icon: Icon(
//                 _isExpanded ? Icons.visibility_off : Icons.list_alt,
//                 size: 18,
//                 color: theme.primaryText,
//               ),
//               label: Text(
//                 _isExpanded ? 'Hide List' : 'View List',
//                 style: theme.labelMedium.copyWith(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: theme.primaryText,
//                 side: BorderSide(color: theme.lineColor, width: 1.5),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 padding: const EdgeInsets.symmetric(vertical: 10),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPinListSection(KMTheme theme) {
//     if (widget.isLoading) {
//       return _buildSkeletonList(theme);
//     }

//     if (widget.pinsInCurrentGridList.isEmpty) {
//       return Padding(
//         padding: const EdgeInsets.all(32),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.location_off_outlined,
//                 size: 48,
//                 color: theme.secondaryText.withOpacity(0.5),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'No pins in this grid',
//                 style: theme.bodyMedium.copyWith(
//                   color: theme.secondaryText,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Text(
//             'People needing help',
//             style: theme.titleSmall.copyWith(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//         const SizedBox(height: 8),
//         ListView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           itemCount: widget.pinsInCurrentGridList.length,
//           itemBuilder: (context, index) {
//             final pin = widget.pinsInCurrentGridList[index];
//             return _buildPinListItem(pin, theme);
//           },
//         ),
//         const SizedBox(height: 16),
//       ],
//     );
//   }

//   Widget _buildSkeletonList(KMTheme theme) {
//     return Column(
//       children: List.generate(
//         3,
//         (index) => Container(
//           margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           padding: const EdgeInsets.all(8),
//           child: Row(
//             children: [
//               ShimmerSkeleton(
//                 width: 50,
//                 height: 50,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     ShimmerSkeleton(
//                       width: 100,
//                       height: 12,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     const SizedBox(height: 8),
//                     ShimmerSkeleton(
//                       width: 150,
//                       height: 10,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     const SizedBox(height: 8),
//                     ShimmerSkeleton(
//                       width: 80,
//                       height: 10,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   ],
//                 ),
//               ),
//               ShimmerSkeleton(
//                 width: 60,
//                 height: 30,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPinListItem(Pin pin, KMTheme theme) {
//     final distance = Geolocator.distanceBetween(
//       pin.latitude,
//       pin.longitude,
//       widget.currentLocation?.latitude ?? 0,
//       widget.currentLocation?.longitude ?? 0,
//     ).round();

//     return GestureDetector(
//       onTap: () => widget.onMarkerTap(
//         LatLng(pin.latitude, pin.longitude),
//         pin,
//       ),
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: theme.primaryBackground,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: theme.lineColor, width: 1),
//         ),
//         child: Row(
//           children: [
//             // Pin image
//             ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: pin.imageBase64 != null
//                   ? Image.memory(
//                       base64Decode(pin.imageBase64!),
//                       fit: BoxFit.cover,
//                       width: 50,
//                       height: 50,
//                       errorBuilder: (context, error, stackTrace) => Container(
//                         width: 50,
//                         height: 50,
//                         color: theme.lineColor,
//                         child: const Icon(Icons.error, size: 24),
//                       ),
//                     )
//                   : Container(
//                       width: 50,
//                       height: 50,
//                       color: theme.lineColor,
//                       child: Icon(
//                         Icons.person_outline,
//                         size: 24,
//                         color: theme.secondaryText,
//                       ),
//                     ),
//             ),
//             const SizedBox(width: 12),

//             // Pin details
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     '$distance meters away',
//                     style: theme.labelMedium.copyWith(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   if (pin.note != null && pin.note!.isNotEmpty)
//                     Text(
//                       pin.note!,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: theme.labelSmall.copyWith(
//                         fontSize: 11,
//                         color: theme.secondaryText,
//                       ),
//                     ),
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.timer_outlined,
//                         size: 12,
//                         color: theme.warning,
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         '${pin.timer} hours left',
//                         style: theme.labelSmall.copyWith(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w500,
//                           color: theme.warning,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             // View button
//             Container(
//               decoration: BoxDecoration(
//                 color: theme.error,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Material(
//                 color: Colors.transparent,
//                 child: InkWell(
//                   onTap: () => widget.onMarkerTap(
//                     LatLng(pin.latitude, pin.longitude),
//                     pin,
//                   ),
//                   borderRadius: BorderRadius.circular(8),
//                   child: const Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     child: Text(
//                       'View',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:kindmap/config/app_theme.dart';
// // import 'package:kindmap/models/pin_model.dart';
// // import 'package:latlong2/latlong.dart';

// // class GridInfoCard extends StatelessWidget {
// //   final String? cellId;
// //   final int pinsCount;
// //   final bool isSubscribed;
// //   final VoidCallback onSubscribeToggle;
// //   final List<Pin> pinsList;
// //   final LatLng? currentLocation;
// //   final Function(LatLng, Pin) onMarkerTap;

// //   const GridInfoCard({
// //     super.key,
// //     required this.cellId,
// //     required this.pinsCount,
// //     required this.isSubscribed,
// //     required this.onSubscribeToggle,
// //     required this.pinsList,
// //     required this.currentLocation,
// //     required this.onMarkerTap,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     return Positioned(
// //       bottom: 35,
// //       left: 6,
// //       child: _GridCard(
// //         cellId: cellId,
// //         pinsCount: pinsCount,
// //         isSubscribed: isSubscribed,
// //         onSubscribeToggle: onSubscribeToggle,
// //         pinsList: pinsList,
// //         currentLocation: currentLocation,
// //         onMarkerTap: onMarkerTap,
// //       ),
// //     );
// //   }
// // }

// // // Main card widget with expansion logic
// // class _GridCard extends StatefulWidget {
// //   final String? cellId;
// //   final int pinsCount;
// //   final bool isSubscribed;
// //   final VoidCallback onSubscribeToggle;
// //   final List<Pin> pinsList;
// //   final LatLng? currentLocation;
// //   final Function(LatLng, Pin) onMarkerTap;

// //   const _GridCard({
// //     required this.cellId,
// //     required this.pinsCount,
// //     required this.isSubscribed,
// //     required this.onSubscribeToggle,
// //     required this.pinsList,
// //     required this.currentLocation,
// //     required this.onMarkerTap,
// //   });

// //   @override
// //   State<_GridCard> createState() => _GridCardState();
// // }

// // class _GridCardState extends State<_GridCard> {
// //   bool _isExpanded = false;
// //   late DraggableScrollableController _draggableController;
// //   final GlobalKey _containerKey = GlobalKey();

// //   @override
// //   void initState() {
// //     super.initState();
// //     _draggableController = DraggableScrollableController();
// //     _draggableController.addListener(_onDragUpdate);
// //   }

// //   @override
// //   void dispose() {
// //     _draggableController.removeListener(_onDragUpdate);
// //     _draggableController.dispose();
// //     super.dispose();
// //   }

// //   void _onDragUpdate() {
// //     if (_draggableController.isAttached) {
// //       final size = _draggableController.size;
// //       if (size > 0.5 && !_isExpanded) {
// //         if (mounted) {
// //           setState(() => _isExpanded = true);
// //         }
// //       } else if (size < 0.3 && _isExpanded) {
// //         if (mounted) {
// //           setState(() => _isExpanded = false);
// //         }
// //       }
// //     }
// //   }

// //   void _toggleExpansion() async {
// //     if (_draggableController.isAttached) {
// //       if (!_isExpanded) {
// //         await _draggableController.animateTo(
// //           0.8,
// //           duration: const Duration(milliseconds: 300),
// //           curve: Curves.easeOutCubic,
// //         );
// //       } else {
// //         await _draggableController.animateTo(
// //           0.15,
// //           duration: const Duration(milliseconds: 300),
// //           curve: Curves.easeOutCubic,
// //         );
// //       }
// //       if (mounted) {
// //         setState(() {
// //           _isExpanded = !_isExpanded;
// //         });
// //       }
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = KMTheme.of(context);
// //     final screenWidth = MediaQuery.of(context).size.width;
// //     final maxCardWidth = (screenWidth * 0.4).clamp(200.0, 320.0);

// //     return Container(
// //       key: _containerKey,
// //       width: maxCardWidth,
// //       height: _isExpanded ? MediaQuery.of(context).size.height * 0.8 : null,
// //       child: DraggableScrollableSheet(
// //         controller: _draggableController,
// //         initialChildSize: 0.15,
// //         minChildSize: 0.12,
// //         maxChildSize: 0.8,
// //         snap: true,
// //         snapSizes: const [0.15, 0.5, 0.8],
// //         builder: (context, scrollController) {
// //           return Container(
// //             decoration: BoxDecoration(
// //               color: theme.secondaryBackground,
// //               borderRadius: BorderRadius.circular(20),
// //               boxShadow: [
// //                 BoxShadow(
// //                   color: Colors.black.withOpacity(0.15),
// //                   blurRadius: 12,
// //                   offset: const Offset(0, 4),
// //                 ),
// //               ],
// //             ),
// //             child: Column(
// //               children: [
// //                 // Drag handle
// //                 GestureDetector(
// //                   onTap: _toggleExpansion,
// //                   child: Container(
// //                     margin: const EdgeInsets.only(top: 12),
// //                     width: 40,
// //                     height: 4,
// //                     decoration: BoxDecoration(
// //                       color: theme.secondaryText.withOpacity(0.4),
// //                       borderRadius: BorderRadius.circular(2),
// //                     ),
// //                   ),
// //                 ),
// //                 Expanded(
// //                   child: SingleChildScrollView(
// //                     controller: scrollController,
// //                     child: Column(
// //                       mainAxisSize: MainAxisSize.min,
// //                       children: [
// //                         Padding(
// //                           padding: const EdgeInsets.all(16),
// //                           child: Column(
// //                             mainAxisSize: MainAxisSize.min,
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               _buildHeader(theme),
// //                               const SizedBox(height: 14),
// //                               _buildPeopleCount(theme),
// //                               const SizedBox(height: 16),
// //                               _buildDivider(theme),
// //                               const SizedBox(height: 16),
// //                               _buildActionButtons(theme),
// //                             ],
// //                           ),
// //                         ),
// //                         // Pin list (only show when expanded enough)
// //                         if (_draggableController.isAttached &&
// //                             _draggableController.size > 0.3)
// //                           _buildPinList(theme),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }

// //   Widget _buildHeader(KMTheme theme) {
// //     return Row(
// //       children: [
// //         Expanded(
// //           child: Text(
// //             'Grid ${widget.cellId ?? 'Unknown'}',
// //             style: theme.titleSmall.copyWith(
// //               color: theme.primaryText,
// //               fontSize: 17,
// //               fontWeight: FontWeight.w600,
// //               letterSpacing: -0.3,
// //             ),
// //             overflow: TextOverflow.ellipsis,
// //           ),
// //         ),
// //         Container(
// //           width: 8,
// //           height: 8,
// //           decoration: BoxDecoration(
// //             shape: BoxShape.circle,
// //             color: widget.isSubscribed ? theme.success : theme.secondaryText,
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildPeopleCount(KMTheme theme) {
// //     return Row(
// //       children: [
// //         Icon(
// //           Icons.people_outline_rounded,
// //           size: 16,
// //           color: theme.secondaryText,
// //         ),
// //         const SizedBox(width: 6),
// //         Flexible(
// //           child: Text(
// //             '${widget.pinsCount} ${widget.pinsCount == 1 ? 'person needs' : 'people need'} help',
// //             style: theme.labelMedium.copyWith(
// //               fontSize: 13,
// //               fontWeight: FontWeight.w500,
// //             ),
// //             overflow: TextOverflow.ellipsis,
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildDivider(KMTheme theme) {
// //     return Container(
// //       height: 1,
// //       color: theme.lineColor,
// //     );
// //   }

// //   Widget _buildActionButtons(KMTheme theme) {
// //     return Column(
// //       children: [
// //         SizedBox(
// //           width: double.infinity,
// //           child: ElevatedButton.icon(
// //             onPressed: widget.onSubscribeToggle,
// //             icon: Icon(
// //               widget.isSubscribed
// //                   ? Icons.notifications_off
// //                   : Icons.notifications_active,
// //               size: 18,
// //               color: theme.primaryBtnText,
// //             ),
// //             label: Text(
// //               widget.isSubscribed ? 'Unsubscribe' : 'Subscribe',
// //               style: theme.labelMedium.copyWith(
// //                 fontSize: 14,
// //                 fontWeight: FontWeight.w600,
// //                 color: theme.primaryBtnText,
// //               ),
// //             ),
// //             style: ElevatedButton.styleFrom(
// //               backgroundColor:
// //                   widget.isSubscribed ? theme.error : theme.success,
// //               foregroundColor: theme.primaryBtnText,
// //               elevation: 0,
// //               shape: RoundedRectangleBorder(
// //                 borderRadius: BorderRadius.circular(12),
// //               ),
// //               padding: const EdgeInsets.symmetric(vertical: 10),
// //             ),
// //           ),
// //         ),
// //         const SizedBox(height: 10),
// //         SizedBox(
// //           width: double.infinity,
// //           child: OutlinedButton.icon(
// //             onPressed: _toggleExpansion,
// //             icon: Icon(
// //               _isExpanded ? Icons.visibility_off : Icons.list_alt,
// //               size: 18,
// //               color: theme.primaryText,
// //             ),
// //             label: Text(
// //               _isExpanded ? 'Hide List' : 'View List',
// //               style: theme.labelMedium.copyWith(
// //                 fontSize: 14,
// //                 fontWeight: FontWeight.w500,
// //               ),
// //             ),
// //             style: OutlinedButton.styleFrom(
// //               foregroundColor: theme.primaryText,
// //               side: BorderSide(color: theme.lineColor, width: 1.5),
// //               shape: RoundedRectangleBorder(
// //                 borderRadius: BorderRadius.circular(12),
// //               ),
// //               padding: const EdgeInsets.symmetric(vertical: 10),
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildPinList(KMTheme theme) {
// //     if (widget.pinsList.isEmpty) {
// //       return Padding(
// //         padding: const EdgeInsets.all(32),
// //         child: Center(
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               Icon(
// //                 Icons.location_off_outlined,
// //                 size: 48,
// //                 color: theme.secondaryText.withOpacity(0.5),
// //               ),
// //               const SizedBox(height: 12),
// //               Text(
// //                 'No pins in this grid',
// //                 style: theme.bodyMedium.copyWith(
// //                   color: theme.secondaryText,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       );
// //     }

// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Padding(
// //           padding: const EdgeInsets.symmetric(horizontal: 16),
// //           child: Text(
// //             'People needing help',
// //             style: theme.titleSmall.copyWith(
// //               fontSize: 14,
// //               fontWeight: FontWeight.w600,
// //             ),
// //           ),
// //         ),
// //         const SizedBox(height: 8),
// //         ListView.builder(
// //           shrinkWrap: true,
// //           physics: const NeverScrollableScrollPhysics(),
// //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// //           itemCount: widget.pinsList.length,
// //           itemBuilder: (context, index) {
// //             final pin = widget.pinsList[index];
// //             return _PinListItem(
// //               pin: pin,
// //               currentLocation: widget.currentLocation,
// //               onTap: () => widget.onMarkerTap(
// //                 LatLng(pin.latitude, pin.longitude),
// //                 pin,
// //               ),
// //             );
// //           },
// //         ),
// //       ],
// //     );
// //   }
// // }

// // // Separate widget for pin list items
// // class _PinListItem extends StatelessWidget {
// //   final Pin pin;
// //   final LatLng? currentLocation;
// //   final VoidCallback onTap;

// //   const _PinListItem({
// //     required this.pin,
// //     required this.currentLocation,
// //     required this.onTap,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = KMTheme.of(context);
// //     final distance = Geolocator.distanceBetween(
// //       pin.latitude,
// //       pin.longitude,
// //       currentLocation?.latitude ?? 0,
// //       currentLocation?.longitude ?? 0,
// //     ).round();

// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Container(
// //         margin: const EdgeInsets.symmetric(vertical: 4),
// //         padding: const EdgeInsets.all(8),
// //         decoration: BoxDecoration(
// //           color: theme.primaryBackground,
// //           borderRadius: BorderRadius.circular(12),
// //           border: Border.all(
// //             color: theme.lineColor,
// //             width: 1,
// //           ),
// //         ),
// //         child: Row(
// //           children: [
// //             _buildPinImage(theme),
// //             const SizedBox(width: 12),
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   Text(
// //                     '$distance meters away',
// //                     style: theme.labelMedium.copyWith(
// //                       fontSize: 12,
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 4),
// //                   if (pin.note != null && pin.note!.isNotEmpty)
// //                     Text(
// //                       pin.note!,
// //                       maxLines: 1,
// //                       overflow: TextOverflow.ellipsis,
// //                       style: theme.labelSmall.copyWith(
// //                         fontSize: 11,
// //                         color: theme.secondaryText,
// //                       ),
// //                     ),
// //                   const SizedBox(height: 4),
// //                   Row(
// //                     children: [
// //                       Icon(
// //                         Icons.timer_outlined,
// //                         size: 12,
// //                         color: theme.warning,
// //                       ),
// //                       const SizedBox(width: 4),
// //                       Text(
// //                         '${pin.timer} hours left',
// //                         style: theme.labelSmall.copyWith(
// //                           fontSize: 11,
// //                           fontWeight: FontWeight.w500,
// //                           color: theme.warning,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             // View button
// //             Container(
// //               decoration: BoxDecoration(
// //                 color: theme.error,
// //                 borderRadius: BorderRadius.circular(8),
// //               ),
// //               child: Material(
// //                 color: Colors.transparent,
// //                 child: InkWell(
// //                   onTap: onTap,
// //                   borderRadius: BorderRadius.circular(8),
// //                   child: const Padding(
// //                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// //                     child: Text(
// //                       'View',
// //                       style: TextStyle(
// //                         color: Colors.white,
// //                         fontWeight: FontWeight.w600,
// //                         fontSize: 12,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildPinImage(KMTheme theme) {
// //     const imageSize = 50.0;

// //     return ClipRRect(
// //       borderRadius: BorderRadius.circular(8),
// //       child: pin.imageBase64 != null
// //           ? Image.memory(
// //               base64Decode(pin.imageBase64!),
// //               fit: BoxFit.cover,
// //               width: imageSize,
// //               height: imageSize,
// //               errorBuilder: (context, error, stackTrace) => Container(
// //                 width: imageSize,
// //                 height: imageSize,
// //                 color: theme.lineColor,
// //                 child: const Icon(Icons.error, size: 24),
// //               ),
// //             )
// //           : Container(
// //               width: imageSize,
// //               height: imageSize,
// //               color: theme.lineColor,
// //               child: Icon(
// //                 Icons.person_outline,
// //                 size: 24,
// //                 color: theme.secondaryText,
// //               ),
// //             ),
// //     );
// //   }
// // }
