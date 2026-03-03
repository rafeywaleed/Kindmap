import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../controllers/pin_controller.dart';
import '../models/pin_model.dart';
import '../providers/map_provider.dart';
import '../widgets/pin_box.dart';

class PinListView extends StatelessWidget {
  const PinListView({super.key, required this.pins, required this.location});
  final List<Pin> pins;
  final LatLng location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Pin List')),
        backgroundColor: KMTheme.of(context).primaryBackground,
        body: ListView.builder(
          itemCount: pins.length,
          itemBuilder: (context, index) {
            final pin = pins[index];
            return GestureDetector(
              onTap: () => _onMarkerTap(context, location, pin),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Container(
                  height: 100,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: KMTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(pin.imageBase64!),
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width * 0.2,
                          height: MediaQuery.of(context).size.width * 0.2,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    '${Geolocator.distanceBetween(
                                      pin.latitude,
                                      pin.longitude,
                                      location.latitude,
                                      location.longitude,
                                    ).round()} meters away',
                                    style: KMTheme.of(context)
                                        .bodyMedium
                                        .copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Text('${pin.timer} hrs left',
                                      style: KMTheme.of(context)
                                          .bodyMedium
                                          .copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(pin.note ?? '',
                                    style: KMTheme.of(context)
                                        .bodyMedium
                                        .copyWith(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400)),
                                Padding(
                                  padding: const EdgeInsets.only(right: 14),
                                  child: GestureDetector(
                                    onTap: null,
                                    child: Container(
                                      width: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          "Served",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ));
  }

  void _onMarkerTap(BuildContext context, LatLng markerLocation, Pin pin) {
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return PinBox(
          pin: pin,
          location: location,
          onServe: () async {
            try {
              // Delete pin
              await PinController().deletePin(pin.pinId);

              // Update local state
              final mapProvider =
                  Provider.of<MapProvider>(context, listen: false);
              final updatedMarkers = mapProvider.markers
                  .where((marker) => marker.point != markerLocation)
                  .toList();
              mapProvider.setMarkers(updatedMarkers);

              // Show success message
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Thank you for helping!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }

              // Close the bottom sheet AFTER removing marker
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              debugPrint('Error removing pin: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error removing pin: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }
}
